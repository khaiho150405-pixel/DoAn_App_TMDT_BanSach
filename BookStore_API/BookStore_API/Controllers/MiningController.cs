using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text;
using System.Text.Json;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MiningController : ControllerBase
    {
        private readonly BookStoreContext _context;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;

        public MiningController(
            BookStoreContext context,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        /// <summary>
        /// POST /api/Mining/topk?k=5
        /// Chạy VertTopKDS mining trên dữ liệu đơn hàng, trả về Top-K itemsets.
        /// </summary>
        [HttpPost("topk")]
        public async Task<IActionResult> RunTopKMining([FromQuery] int k = 10)
        {
            if (k < 1 || k > 100)
                return BadRequest(new { message = "K phải từ 1 đến 100" });

            // 1. Query đơn hàng hoàn thành cùng chi tiết
            var completedOrders = await _context.Donhangs
                .Where(dh => dh.Trangthaidonhang == "Hoàn thành"
                          || dh.Trangthaidonhang == "Đang giao"
                          || dh.Trangthaidonhang == "Đang chuẩn bị hàng"
                          || dh.Trangthaidonhang == "Chờ xác nhận")
                .Include(dh => dh.Chitietdonhangs)
                    .ThenInclude(ct => ct.MasachNavigation)
                        .ThenInclude(s => s.MatgNavigation)
                .ToListAsync();

            if (!completedOrders.Any())
                return Ok(new
                {
                    k,
                    totalTransactions = 0,
                    totalItems = 0,
                    results = new List<object>(),
                    threshold = 0,
                    message = "Chưa có đơn hàng nào để phân tích. Hệ thống sẽ sử dụng dữ liệu mẫu."
                });

            // 2. Transform thành transaction format cho mining service
            var transactions = new List<object>();
            var externalUtilities = new Dictionary<string, double>();
            var bookMetadata = new Dictionary<string, object>();

            foreach (var order in completedOrders)
            {
                var items = new List<object>();
                foreach (var ct in order.Chitietdonhangs)
                {
                    var book = ct.MasachNavigation;
                    if (book == null) continue;

                    items.Add(new
                    {
                        itemId = ct.Masach,
                        quantity = ct.Soluong
                    });

                    // External utility = giá bán (proxy cho lợi nhuận)
                    var key = ct.Masach.ToString();
                    if (!externalUtilities.ContainsKey(key))
                    {
                        externalUtilities[key] = (double)book.Giaban;
                    }

                    if (!bookMetadata.ContainsKey(key))
                    {
                        bookMetadata[key] = new
                        {
                            name = book.Tensach,
                            image = book.Hinhanh ?? "default_book.jpg",
                            price = (double)book.Giaban,
                            author = book.MatgNavigation?.Tentg ?? ""
                        };
                    }
                }

                if (items.Any())
                {
                    transactions.Add(new
                    {
                        tid = order.Madh,
                        items
                    });
                }
            }

            // 3. Gọi FastAPI mining service
            var miningBaseUrl = _configuration["AiMining:BaseUrl"] ?? "http://localhost:8002";
            var client = _httpClientFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(30);

            var requestBody = new
            {
                k,
                transactions,
                externalUtilities,
                bookMetadata
            };

            var jsonContent = new StringContent(
                JsonSerializer.Serialize(requestBody),
                Encoding.UTF8,
                "application/json"
            );

            try
            {
                var response = await client.PostAsync($"{miningBaseUrl}/mine/topk", jsonContent);
                var responseBody = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    var result = JsonSerializer.Deserialize<JsonElement>(responseBody);
                    return Ok(result);
                }

                return StatusCode(502, new
                {
                    message = "Mining service trả về lỗi",
                    detail = responseBody
                });
            }
            catch (HttpRequestException)
            {
                return StatusCode(503, new
                {
                    message = "Không thể kết nối Mining Service. Đảm bảo service đang chạy tại " + miningBaseUrl
                });
            }
            catch (TaskCanceledException)
            {
                return StatusCode(504, new
                {
                    message = "Mining Service timeout. Thử giảm giá trị K hoặc kiểm tra lại service."
                });
            }
        }

        /// <summary>
        /// POST /api/Mining/apply-promotions
        /// Nhận kết quả mining và tự động tạo khuyến mãi + gắn vào sách.
        /// </summary>
        [HttpPost("apply-promotions")]
        public async Task<IActionResult> ApplyPromotions([FromBody] ApplyPromotionRequest request)
        {
            if (request.Results == null || !request.Results.Any())
                return BadRequest(new { message = "Không có kết quả để tạo khuyến mãi" });

            var createdPromotions = new List<object>();
            var now = DateTime.Now;

            foreach (var result in request.Results)
            {
                var isSingle = result.Itemset.Count == 1;
                var discountPercent = isSingle ? 10 : 15;
                var promoType = isSingle ? "Giảm giá" : "Combo";
                var itemNames = string.Join(" + ", result.ItemNames.Take(3));
                if (result.ItemNames.Count > 3)
                    itemNames += $" +{result.ItemNames.Count - 3} sản phẩm khác";

                var promoName = $"[AI] {promoType}: {itemNames}";
                if (promoName.Length > 150)
                    promoName = promoName.Substring(0, 147) + "...";

                // Tạo khuyến mãi
                var km = new Khuyenmai
                {
                    Tenkm = promoName,
                    Mota = $"Tự động tạo bởi AI Mining (Utility: {result.UtilityScore:N0} đ, Rank #{result.Rank})",
                    Phantramgiam = discountPercent,
                    Ngaybatdau = now,
                    Ngayketthuc = now.AddDays(7),
                    Trangthai = "Đang diễn ra"
                };

                _context.Khuyenmais.Add(km);
                await _context.SaveChangesAsync();

                // Gắn khuyến mãi vào các sách trong itemset
                var updatedBooks = new List<string>();
                foreach (var bookId in result.Itemset)
                {
                    var book = await _context.Saches.FindAsync(bookId);
                    if (book != null)
                    {
                        book.Makm = km.Makm;
                        updatedBooks.Add(book.Tensach);
                    }
                }
                await _context.SaveChangesAsync();

                createdPromotions.Add(new
                {
                    maKM = km.Makm,
                    tenKM = km.Tenkm,
                    phanTramGiam = km.Phantramgiam,
                    loai = promoType,
                    sachApDung = updatedBooks,
                    ngayBatDau = km.Ngaybatdau,
                    ngayKetThuc = km.Ngayketthuc
                });
            }

            return Ok(new
            {
                message = $"Đã tạo {createdPromotions.Count} chương trình khuyến mãi từ AI Mining",
                promotions = createdPromotions
            });
        }
    }

    // ── Request DTOs ────────────────────────────────────────────────────

    public class ApplyPromotionRequest
    {
        public List<MiningResultItem> Results { get; set; } = new();
    }

    public class MiningResultItem
    {
        public int Rank { get; set; }
        public List<int> Itemset { get; set; } = new();
        public List<string> ItemNames { get; set; } = new();
        public double UtilityScore { get; set; }
        public string PromotionType { get; set; } = "single";
    }
}

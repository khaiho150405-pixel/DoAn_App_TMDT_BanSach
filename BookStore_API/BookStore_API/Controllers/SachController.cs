using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SachController : ControllerBase
    {
        private readonly BookStoreContext _context;
        private readonly IWebHostEnvironment _env;

        public SachController(BookStoreContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // 1. LẤY TOÀN BỘ SÁCH KÈM GIÁ KHUYẾN MÃI DỰA THEO THỜI GIAN THỰC
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var now = DateTime.Now;

            var result = await _context.Saches
                .Include(s => s.MatgNavigation)
                .Include(s => s.ManxbNavigation)
                .Include(s => s.MakmNavigation)
                .Include(s => s.MatheloaiNavigation)
                .Select(s => new
                {
                    s.Masach,
                    s.Tensach,
                    s.Mota,
                    s.Soluongton,
                    s.Trangthai,
                    s.Hinhanh,
                    TenTacGia = s.MatgNavigation.Tentg,
                    TenNxb = s.ManxbNavigation.Tennxb,
                    GiaGoc = s.Giaban,
                    TenTheLoai = s.MatheloaiNavigation.Tentheloai,
                    // Nếu sách được gán mã KM và đợt KM đang nằm trong thời gian hiệu lực
                    PhanTramGiam = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                                   ? s.MakmNavigation.Phantramgiam : 0,
                    GiaBanThucTe = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                                   ? (s.Giaban - (s.Giaban * s.MakmNavigation.Phantramgiam / 100)) : s.Giaban,
                    TenSuKienKhuyenMai = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                                   ? s.MakmNavigation.Tenkm : null
                }).ToListAsync();

            return Ok(result);
        }

        // 2. NHÂN VIÊN KHO THÊM SÁCH MỚI CÓ TẢI ẢNH LÊN
        [HttpPost("ThemSach")]
        public async Task<IActionResult> ThemSach([FromForm] FormSachRequest request)
        {
            try
            {
                string nameOfFile = "default_book.jpg";

                if (request.FileHinhAnh != null && request.FileHinhAnh.Length > 0)
                {
                    string ext = Path.GetExtension(request.FileHinhAnh.FileName);
                    nameOfFile = Guid.NewGuid().ToString() + ext; // Đảm bảo tên file không bị trùng

                    string rootFolderPath = Path.Combine(_env.WebRootPath, "images");
                    if (!Directory.Exists(rootFolderPath)) Directory.CreateDirectory(rootFolderPath);

                    string finalPath = Path.Combine(rootFolderPath, nameOfFile);
                    using (var fs = new FileStream(finalPath, FileMode.Create))
                    {
                        await request.FileHinhAnh.CopyToAsync(fs);
                    }
                }

                var sach = new Sach
                {
                    Tensach = request.TenSach,
                    Matg = request.Matg,
                    Manxb = request.Manxb,
                    Matheloai = request.Matheloai,
                    Mota = request.Mota,
                    Giaban = request.GiaBán,
                    Soluongton = request.SoLuongTon,
                    Makm = request.Makm == 0 ? null : request.Makm,
                    Hinhanh = nameOfFile,
                    Trangthai = request.SoLuongTon > 0 ? "Có sẵn" : "Đã hết"
                };

                _context.Saches.Add(sach);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Thêm đầu sách mới thành công!", bookId = sach.Masach });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi xử lý file hoặc DB: {ex.Message}" });
            }
        }
    }

    public class FormSachRequest
    {
        public string TenSach { get; set; } = null!;
        public int Matg { get; set; }
        public int Manxb { get; set; }
        public int Matheloai { get; set; }
        public string? Mota { get; set; }
        public decimal GiaBán { get; set; }
        public int SoLuongTon { get; set; }
        public int? Makm { get; set; }
        public IFormFile? FileHinhAnh { get; set; }
    }
}
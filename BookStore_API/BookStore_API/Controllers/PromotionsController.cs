using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PromotionsController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public PromotionsController(BookStoreContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var now = DateTime.Now;

            var promotions = await _context.Khuyenmais
                .OrderByDescending(km => km.Ngaybatdau)
                .Select(km => new
                {
                    MaKM = km.Makm,
                    TenKM = km.Tenkm,
                    MoTa = km.Mota,
                    PhanTramGiam = km.Phantramgiam,
                    NgayBatDau = km.Ngaybatdau,
                    NgayKetThuc = km.Ngayketthuc,
                    TrangThai = km.Ngayketthuc < now ? "Đã kết thúc"
                              : km.Ngaybatdau > now ? "Sắp diễn ra"
                              : "Đang diễn ra",
                    SoSachApDung = km.Saches.Count
                })
                .ToListAsync();

            return Ok(promotions);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] PromotionCreateRequest request)
        {
            if (request.NgayBatDau > request.NgayKetThuc)
                return BadRequest(new { message = "Ngày bắt đầu phải trước ngày kết thúc!" });

            if (request.PhanTramGiam < 1 || request.PhanTramGiam > 100)
                return BadRequest(new { message = "Phần trăm giảm phải từ 1 đến 100!" });

            var now = DateTime.Now;
            string trangThai;
            if (request.NgayKetThuc < now) trangThai = "Đã kết thúc";
            else if (request.NgayBatDau > now) trangThai = "Sắp diễn ra";
            else trangThai = "Đang diễn ra";

            var km = new Khuyenmai
            {
                Tenkm = request.TenKM,
                Mota = request.MoTa,
                Phantramgiam = request.PhanTramGiam,
                Ngaybatdau = request.NgayBatDau,
                Ngayketthuc = request.NgayKetThuc,
                Trangthai = trangThai
            };

            _context.Khuyenmais.Add(km);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Tạo khuyến mãi thành công!", id = km.Makm });
        }
    }

    public class PromotionCreateRequest
    {
        public string TenKM { get; set; } = null!;
        public string? MoTa { get; set; }
        public int PhanTramGiam { get; set; }
        public DateTime NgayBatDau { get; set; }
        public DateTime NgayKetThuc { get; set; }
    }
}

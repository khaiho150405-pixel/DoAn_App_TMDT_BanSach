using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class KhoController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public KhoController(BookStoreContext context)
        {
            _context = context;
        }

        // =========================================================
        // 1. DASHBOARD KHO
        // =========================================================
        [HttpGet("Dashboard")]
        public async Task<IActionResult> GetDashboard()
        {
            var today = DateTime.Today;

            var tongSoSach = await _context.Saches.CountAsync();
            var sachHetHang = await _context.Saches.CountAsync(s => s.Trangthai == "Đã hết");
            var phieuNhapHomNay = await _context.Phieunhaps.CountAsync(p => p.Ngaynhap.Date == today);
            var tongGiaTriKho = await _context.Saches.SumAsync(s => s.Giaban * s.Soluongton);

            return Ok(new
            {
                tongSoSach,
                sachHetHang,
                phieuNhapHomNay,
                tongGiaTriKho
            });
        }

        // =========================================================
        // 2. DANH SÁCH TỒN KHO
        // =========================================================
        [HttpGet("TonKho")]
        public async Task<IActionResult> GetTonKho()
        {
            var result = await _context.Saches
                .Include(s => s.MatgNavigation)
                .Include(s => s.ManxbNavigation)
                .Include(s => s.MatheloaiNavigation)
                .Select(s => new
                {
                    s.Masach,
                    s.Tensach,
                    s.Hinhanh,
                    s.Giaban,
                    s.Soluongton,
                    s.Trangthai,
                    s.Mota,
                    TenTacGia = s.MatgNavigation.Tentg,
                    TenNxb = s.ManxbNavigation.Tennxb,
                    TenTheLoai = s.MatheloaiNavigation.Tentheloai,
                    s.Matg,
                    s.Manxb,
                    s.Matheloai
                })
                .OrderBy(s => s.Tensach)
                .ToListAsync();

            return Ok(result);
        }

        // =========================================================
        // 3. CẢNH BÁO TỒN KHO
        // =========================================================
        [HttpGet("CanhBao")]
        public async Task<IActionResult> GetCanhBao([FromQuery] int threshold = 10)
        {
            var result = await _context.Saches
                .Include(s => s.MatgNavigation)
                .Include(s => s.ManxbNavigation)
                .Include(s => s.MatheloaiNavigation)
                .Where(s => s.Soluongton <= threshold)
                .Select(s => new
                {
                    s.Masach,
                    s.Tensach,
                    s.Hinhanh,
                    s.Giaban,
                    s.Soluongton,
                    s.Trangthai,
                    TenTacGia = s.MatgNavigation.Tentg,
                    TenNxb = s.ManxbNavigation.Tennxb,
                    TenTheLoai = s.MatheloaiNavigation.Tentheloai
                })
                .OrderBy(s => s.Soluongton)
                .ToListAsync();

            return Ok(result);
        }
    }
}

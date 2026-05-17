using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HoiDapController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public HoiDapController(BookStoreContext context)
        {
            _context = context;
        }

        // 1. LẤY DANH SÁCH CÂU HỎI CHƯA TRẢ LỜI (Dành cho NV Sale)
        [HttpGet("ChuaTraLoi")]
        public async Task<IActionResult> GetPendingQuestions()
        {
            var questions = await _context.Hoidaps
                .Include(h => h.MakhNavigation)
                .Where(h => h.Trangthai == "Chờ trả lời")
                .OrderByDescending(h => h.Thoigianhoi)
                .Select(h => new
                {
                    h.Mahoidap,
                    h.Makh,
                    TenKhachHang = h.MakhNavigation.Hovaten,
                    h.Cauhoi,
                    h.Traloi,
                    h.Thoigianhoi,
                    h.Thoigiantraloi,
                    h.Trangthai
                })
                .ToListAsync();

            return Ok(questions);
        }

        // 2. LẤY TẤT CẢ CÂU HỎI (Bao gồm đã trả lời)
        [HttpGet("TatCa")]
        public async Task<IActionResult> GetAllQuestions()
        {
            var questions = await _context.Hoidaps
                .Include(h => h.MakhNavigation)
                .Include(h => h.ManvNavigation)
                .OrderByDescending(h => h.Thoigianhoi)
                .Select(h => new
                {
                    h.Mahoidap,
                    h.Makh,
                    TenKhachHang = h.MakhNavigation.Hovaten,
                    h.Cauhoi,
                    h.Traloi,
                    h.Manv,
                    TenNhanVien = h.ManvNavigation != null ? h.ManvNavigation.Hovaten : null,
                    h.Thoigianhoi,
                    h.Thoigiantraloi,
                    h.Trangthai
                })
                .ToListAsync();

            return Ok(questions);
        }

        // 3. NHÂN VIÊN TRẢ LỜI CÂU HỎI
        [HttpPut("TraLoi/{maHoiDap}")]
        public async Task<IActionResult> ReplyQuestion(int maHoiDap, [FromBody] ReplyRequest request)
        {
            var question = await _context.Hoidaps.FindAsync(maHoiDap);
            if (question == null)
                return NotFound(new { message = "Không tìm thấy câu hỏi!" });

            question.Traloi = request.TraLoi;
            question.Manv = request.MaNV;
            question.Thoigiantraloi = DateTime.Now;
            question.Trangthai = "Đã trả lời";

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã trả lời câu hỏi thành công!" });
        }
    }

    public class ReplyRequest
    {
        public string TraLoi { get; set; } = null!;
        public int MaNV { get; set; }
    }
}

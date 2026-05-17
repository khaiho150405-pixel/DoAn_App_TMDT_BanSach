using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DanhGiaController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public DanhGiaController(BookStoreContext context)
        {
            _context = context;
        }

        // 1. LẤY TẤT CẢ ĐÁNH GIÁ SÁCH (Kèm thông tin khách hàng + tên sách)
        [HttpGet("DanhSach")]
        public async Task<IActionResult> GetAllReviews()
        {
            var reviews = await _context.Danhgiasaches
                .Include(d => d.MakhNavigation)
                .Include(d => d.MasachNavigation)
                .OrderByDescending(d => d.Thoigian)
                .Select(d => new
                {
                    d.Madanhgia,
                    d.Masach,
                    TenSach = d.MasachNavigation.Tensach,
                    HinhAnhSach = d.MasachNavigation.Hinhanh,
                    d.Makh,
                    TenKhachHang = d.MakhNavigation.Hovaten,
                    d.Diem,
                    d.Nhanxet,
                    d.Thoigian
                })
                .ToListAsync();

            return Ok(reviews);
        }

        // 2. XÓA ĐÁNH GIÁ VI PHẠM
        [HttpDelete("Xoa/{maDanhGia}")]
        public async Task<IActionResult> DeleteReview(int maDanhGia)
        {
            var review = await _context.Danhgiasaches.FindAsync(maDanhGia);
            if (review == null)
                return NotFound(new { message = "Không tìm thấy đánh giá!" });

            _context.Danhgiasaches.Remove(review);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa đánh giá thành công!" });
        }
    }
}

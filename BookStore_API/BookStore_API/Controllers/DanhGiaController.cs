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

        // 3. LẤY DANH SÁCH ĐÁNH GIÁ THEO SÁCH
        [HttpGet("Sach/{maSach}")]
        public async Task<IActionResult> GetReviewsByBook(int maSach)
        {
            var reviews = await _context.Danhgiasaches
                .Include(d => d.MakhNavigation)
                .Where(d => d.Masach == maSach)
                .OrderByDescending(d => d.Thoigian)
                .Select(d => new
                {
                    d.Madanhgia,
                    d.Masach,
                    d.Makh,
                    TenKhachHang = d.MakhNavigation.Hovaten,
                    d.Diem,
                    d.Nhanxet,
                    d.Thoigian
                })
                .ToListAsync();

            return Ok(reviews);
        }

        // 4. THÊM HOẶC CẬP NHẬT ĐÁNH GIÁ SÁCH
        [HttpPost("Luu")]
        public async Task<IActionResult> SaveReview([FromBody] LuuDanhGiaRequest request)
        {
            if (request.Diem < 1 || request.Diem > 5)
                return BadRequest(new { message = "Số sao phải từ 1 đến 5!" });

            // Kiểm tra xem khách hàng và sách có tồn tại không
            var sachExists = await _context.Saches.AnyAsync(s => s.Masach == request.Masach);
            if (!sachExists)
                return NotFound(new { message = "Không tìm thấy sách!" });

            var khExists = await _context.Khachhangs.AnyAsync(k => k.Makh == request.Makh);
            if (!khExists)
                return NotFound(new { message = "Không tìm thấy khách hàng!" });

            // Tìm xem đã có đánh giá chưa
            var review = await _context.Danhgiasaches
                .FirstOrDefaultAsync(d => d.Masach == request.Masach && d.Makh == request.Makh);

            if (review != null)
            {
                // Cập nhật
                review.Diem = request.Diem;
                review.Nhanxet = request.Nhanxet;
                review.Thoigian = DateTime.Now;
                _context.Danhgiasaches.Update(review);
                await _context.SaveChangesAsync();
                return Ok(new { message = "Cập nhật đánh giá thành công!", isUpdate = true });
            }
            else
            {
                // Thêm mới
                var newReview = new Danhgiasach
                {
                    Masach = request.Masach,
                    Makh = request.Makh,
                    Diem = request.Diem,
                    Nhanxet = request.Nhanxet,
                    Thoigian = DateTime.Now
                };
                _context.Danhgiasaches.Add(newReview);
                await _context.SaveChangesAsync();
                return Ok(new { message = "Thêm đánh giá thành công!", isUpdate = false });
            }
        }

        // 5. LẤY DANH SÁCH ĐÁNH GIÁ THEO KHÁCH HÀNG
        [HttpGet("KhachHang/{maKh}")]
        public async Task<IActionResult> GetReviewsByCustomer(int maKh)
        {
            var reviews = await _context.Danhgiasaches
                .Include(d => d.MasachNavigation)
                .Where(d => d.Makh == maKh)
                .OrderByDescending(d => d.Thoigian)
                .Select(d => new
                {
                    d.Madanhgia,
                    d.Masach,
                    TenSach = d.MasachNavigation.Tensach,
                    HinhAnhSach = d.MasachNavigation.Hinhanh,
                    d.Makh,
                    d.Diem,
                    d.Nhanxet,
                    d.Thoigian
                })
                .ToListAsync();

            return Ok(reviews);
        }
    }

    // DTO Request cho việc Lưu/Cập nhật đánh giá
    public class LuuDanhGiaRequest
    {
        public int Masach { get; set; }
        public int Makh { get; set; }
        public int Diem { get; set; }
        public string? Nhanxet { get; set; }
    }
}


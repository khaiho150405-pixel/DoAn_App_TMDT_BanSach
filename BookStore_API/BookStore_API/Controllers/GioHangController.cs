using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GioHangController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public GioHangController(BookStoreContext context)
        {
            _context = context;
        }

        // 1. TẢI CHI TIẾT GIỎ HÀNG CỦA KHÁCH HÀNG (Tính toán giá hiện thời)
        [HttpGet("{maKH}")]
        public async Task<IActionResult> GetGioHang(int maKH)
        {
            var now = DateTime.Now;
            var gioHang = await _context.Giohangs.FirstOrDefaultAsync(g => g.Makh == maKH);
            if (gioHang == null) return NotFound(new { message = "Không tìm thấy dữ liệu giỏ hàng của bạn!" });

            var items = await _context.Chitietgiohangs
                .Where(c => c.Magiohang == gioHang.Magiohang)
                .Include(c => c.MasachNavigation)
                .ThenInclude(s => s.MakmNavigation)
                .Select(c => new
                {
                    c.Masach,
                    c.MasachNavigation.Tensach,
                    c.MasachNavigation.Hinhanh,
                    c.Soluong,
                    GiaGoc = c.MasachNavigation.Giaban,
                    GiaHienTai = (c.MasachNavigation.Makm != null && c.MasachNavigation.MakmNavigation.Ngaybatdau <= now && c.MasachNavigation.MakmNavigation.Ngayketthuc >= now)
                                 ? (c.MasachNavigation.Giaban - (c.MasachNavigation.Giaban * c.MasachNavigation.MakmNavigation.Phantramgiam / 100)) : c.MasachNavigation.Giaban
                }).ToListAsync();

            return Ok(items);
        }

        // 2. THÊM HOẶC CỘNG DỒN SÁCH VÀO GIỎ
        [HttpPost("ThemVaoGio")]
        public async Task<IActionResult> ThemVaoGio(int maKH, int maSach, int soLuong)
        {
            var gioHang = await _context.Giohangs.FirstOrDefaultAsync(g => g.Makh == maKH);
            if (gioHang == null) return BadRequest("Lỗi không tồn tại giỏ hàng cho tài khoản này.");

            var sach = await _context.Saches.FindAsync(maSach);
            if (sach == null || sach.Soluongton < soLuong) return BadRequest("Số lượng sách trong kho không đủ cung ứng!");

            var chiTiet = await _context.Chitietgiohangs
                .FirstOrDefaultAsync(c => c.Magiohang == gioHang.Magiohang && c.Masach == maSach);

            if (chiTiet != null)
            {
                chiTiet.Soluong += soLuong;
            }
            else
            {
                _context.Chitietgiohangs.Add(new Chitietgiohang { Magiohang = gioHang.Magiohang, Masach = maSach, Soluong = soLuong });
            }

            gioHang.Ngaycapnhat = DateTime.Now;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã thêm sản phẩm vào giỏ hàng thành công!" });
        }

        // 3. SỬA ĐỔI SỐ LƯỢNG MÓN HÀNG TRỰC TIẾP (Ấn nút + / - trên app)
        [HttpPut("CapNhatSoLuong")]
        public async Task<IActionResult> CapNhat(int maKH, int maSach, int soLuongMoi)
        {
            var gioHang = await _context.Giohangs.FirstOrDefaultAsync(g => g.Makh == maKH);
            var item = await _context.Chitietgiohangs.FirstOrDefaultAsync(c => c.Magiohang == gioHang!.Magiohang && c.Masach == maSach);

            if (item == null) return NotFound("Sản phẩm không có trong giỏ hàng.");

            if (soLuongMoi <= 0)
            {
                _context.Chitietgiohangs.Remove(item);
            }
            else
            {
                item.Soluong = soLuongMoi;
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã cập nhật giỏ hàng!" });
        }
    }
}
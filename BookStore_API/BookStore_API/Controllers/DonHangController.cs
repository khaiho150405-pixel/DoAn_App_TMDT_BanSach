using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DonHangController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public DonHangController(BookStoreContext context)
        {
            _context = context;
        }

        // 1. LUỒNG ĐẶT HÀNG (Chuyển toàn bộ sách từ giỏ hàng sang hóa đơn mới)
        [HttpPost("CheckOut")]
        public async Task<IActionResult> CheckOut([FromBody] OrderCreateRequest request)
        {
            using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                var now = DateTime.Now;
                var gioHang = await _context.Giohangs.FirstOrDefaultAsync(g => g.Makh == request.MaKH);
                if (gioHang == null) return BadRequest("Không tìm thấy thông tin giỏ hàng.");

                var itemsTrongGio = await _context.Chitietgiohangs
                    .Where(c => c.Magiohang == gioHang.Magiohang)
                    .Include(c => c.MasachNavigation)
                    .ThenInclude(s => s.MakmNavigation)
                    .ToListAsync();

                if (!itemsTrongGio.Any()) return BadRequest("Giỏ hàng của bạn đang trống, không thể thanh toán!");

                // Tạo đối tượng Đơn hàng gốc
                var donHang = new Donhang
                {
                    Makh = request.MaKH,
                    Ngaydat = now,
                    Tennguoinhan = request.TenNguoiNhan,
                    Sdtnhan = request.SdtNhan,
                    Diachigiao = request.DiaChiGiao,
                    Phuongthucthanhtoan = request.PhuongThucThanhToan,
                    Trangthaithanhtoan = request.PhuongThucThanhToan == "COD" ? "Chưa thanh toán" : "Đã thanh toán",
                    Trangthaidonhang = "Chờ xác nhận",
                    Ghichu = request.GhiChu,
                    Tongtien = 0 // Sẽ được tính tự động và cập nhật thông qua Trigger SQL
                };

                _context.Donhangs.Add(donHang);
                await _context.SaveChangesAsync(); // Lấy mã MADH vừa tạo

                // Đưa chi tiết sản phẩm vào hóa đơn
                foreach (var item in itemsTrongGio)
                {
                    if (item.MasachNavigation.Soluongton < item.Soluong)
                    {
                        throw new Exception($"Sách '{item.MasachNavigation.Tensach}' đã hết hàng hoặc không đủ tồn kho!");
                    }

                    // Chốt giá bán tại thời điểm mua (Tránh lỗi đổi giá trong tương lai)
                    decimal giaChot = item.MasachNavigation.Giaban;
                    var km = item.MasachNavigation.MakmNavigation;
                    if (item.MasachNavigation.Makm != null && km?.Ngaybatdau <= now && km?.Ngayketthuc >= now)
                    {
                        giaChot = giaChot - (giaChot * km.Phantramgiam / 100);
                    }

                    var ctDonHang = new Chitietdonhang
                    {
                        Madh = donHang.Madh,
                        Masach = item.Masach,
                        Soluong = item.Soluong,
                        Dongia = giaChot
                    };
                    _context.Chitietdonhangs.Add(ctDonHang);
                }

                // Xóa sạch giỏ hàng hiện tại của khách hàng sau khi tạo bill thành công
                _context.Chitietgiohangs.RemoveRange(itemsTrongGio);

                await _context.SaveChangesAsync();
                await tx.CommitAsync(); // Xác thực hoàn thành toàn bộ luồng xử lý

                return Ok(new { message = "Đơn hàng đã được khởi tạo thành công!", orderId = donHang.Madh });
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                return BadRequest(new { message = ex.Message });
            }
        }

        // 2. KHÁCH HÀNG ẤN NÚT HỦY ĐƠN HÀNG TRÊN APP FLUTTER
        [HttpPut("KhachHuyDon/{maDH}/{maKH}")]
        public async Task<IActionResult> KhachHuyDon(int maDH, int maKH)
        {
            var order = await _context.Donhangs.FirstOrDefaultAsync(d => d.Madh == maDH && d.Makh == maKH);
            if (order == null) return NotFound(new { message = "Không tìm thấy mã đơn hàng!" });

            // Ràng buộc bảo mật trạng thái
            if (order.Trangthaidonhang != "Chờ xác nhận")
            {
                return BadRequest(new { message = "Đơn hàng đã được tiếp nhận xử lý, không thể tự hủy. Vui lòng gọi Hotline!" });
            }

            order.Trangthaidonhang = "Đã hủy";
            await _context.SaveChangesAsync(); // Trigger SQL sẽ tự động hoàn trả lại Số lượng tồn kho cho Sách

            return Ok(new { message = "Bạn đã hủy đơn hàng thành công!", orderId = maDH });
        }

        // 3. NHÂN VIÊN BÁN HÀNG CHUYỂN TRẠNG THÁI ĐƠN HÀNG (QUẢN LÝ FLOW)
        [HttpPut("CapNhatTrangThaiDon/{maDH}")]
        public async Task<IActionResult> ChangeStatus(int maDH, [FromQuery] string statusMoi, [FromQuery] int maNV)
        {
            var order = await _context.Donhangs.FindAsync(maDH);
            if (order == null) return NotFound("Đơn hàng không tồn tại.");

            order.Trangthaidonhang = statusMoi;
            order.Manv = maNV; // Ghi nhận nhân viên nào phụ trách xử lý hóa đơn này

            await _context.SaveChangesAsync();
            return Ok(new { message = $"Đã cập nhật trạng thái sang: {statusMoi}" });
        }

        // 4. LẤY DANH SÁCH ĐƠN HÀNG THEO TRẠNG THÁI (Dành cho tab của Sale)
        [HttpGet("GetByStatus")]
        public async Task<IActionResult> GetOrdersByStatus([FromQuery] string status)
        {
            var orders = await _context.Donhangs
                .Where(d => d.Trangthaidonhang == status)
                .OrderByDescending(d => d.Ngaydat) // Đơn mới nhất lên đầu
                .Select(d => new
                {
                    d.Madh,
                    d.Ngaydat,
                    d.Tennguoinhan,
                    d.Sdtnhan,
                    d.Diachigiao,
                    d.Tongtien,
                    d.Trangthaithanhtoan,
                    d.Trangthaidonhang,
                    d.Ghichu
                })
                .ToListAsync();

            return Ok(orders);
        }

        // 5. LẤY CHI TIẾT 1 ĐƠN HÀNG (Để Sale xem khách mua những sách gì trước khi đóng gói)
        [HttpGet("ChiTiet/{maDH}")]
        public async Task<IActionResult> GetOrderDetail(int maDH)
        {
            var order = await _context.Donhangs.FindAsync(maDH);
            if (order == null) return NotFound("Không tìm thấy đơn hàng");

            var details = await _context.Chitietdonhangs
                .Where(c => c.Madh == maDH)
                .Include(c => c.MasachNavigation)
                .Select(c => new
                {
                    c.Masach,
                    TenSach = c.MasachNavigation.Tensach,
                    HinhAnh = c.MasachNavigation.Hinhanh,
                    c.Soluong,
                    c.Dongia,
                    ThanhTien = c.Soluong * c.Dongia
                }).ToListAsync();

            return Ok(new
            {
                thongTinChung = order,
                danhSachSanPham = details
            });
        }
    }

    public class OrderCreateRequest
    {
        public int MaKH { get; set; }
        public string TenNguoiNhan { get; set; } = null!;
        public string SdtNhan { get; set; } = null!;
        public string DiaChiGiao { get; set; } = null!;
        public string PhuongThucThanhToan { get; set; } = null!;
        public string? GhiChu { get; set; }
    }
}
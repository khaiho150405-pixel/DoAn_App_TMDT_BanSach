using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public AuthController(BookStoreContext context)
        {
            _context = context;
        }

        // 1. ĐĂNG KÝ (Mặc định tạo tài khoản Khách hàng - MaQuyen = 4)
        [HttpPost("Register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (await _context.Taikhoans.AnyAsync(t => t.Tendangnhap == request.TenDangNhap))
                return BadRequest(new { message = "Tên đăng nhập đã tồn tại trên hệ thống!" });

            if (await _context.Khachhangs.AnyAsync(k => k.Email == request.Email))
                return BadRequest(new { message = "Email này đã được đăng ký!" });

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Tạo tài khoản hệ thống
                var taiKhoan = new Taikhoan
                {
                    Tendangnhap = request.TenDangNhap,
                    Matkhau = request.MatKhau, // Nên hash mật khẩu nếu làm dự án thực tế
                    Email = request.Email,
                    Maquyen = 4, // 4: Khách hàng
                    Trangthai = "Hoạt động"
                };

                _context.Taikhoans.Add(taiKhoan);
                await _context.SaveChangesAsync(); // Lấy ra MaTaiKhoan tự tăng

                // Tạo thông tin khách hàng liên kết với tài khoản
                var khachHang = new Khachhang
                {
                    Mataikhoan = taiKhoan.Mataikhoan,
                    Hovaten = request.HoVaTen,
                    Sdt = request.Sdt,
                    Email = request.Email,
                    Diachimacdinh = request.DiaChiMacDinh
                };

                _context.Khachhangs.Add(khachHang);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();
                return Ok(new { message = "Đăng ký tài khoản thành công!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = $"Lỗi hệ thống: {ex.Message}" });
            }
        }

        // 2. ĐĂNG NHẬP (Trả về chi tiết ID tương ứng với từng phân quyền)
        [HttpPost("Login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _context.Taikhoans
                .Include(t => t.MaquyenNavigation)
                .FirstOrDefaultAsync(t => t.Tendangnhap == request.TenDangNhap && t.Matkhau == request.MatKhau);

            if (user == null)
                return Unauthorized(new { message = "Tài khoản hoặc mật khẩu không chính xác!" });

            if (user.Trangthai == "Ngừng hoạt động")
                return BadRequest(new { message = "Tài khoản của bạn đã bị khóa!" });

            // Kiểm tra phân quyền để lấy đúng ID thực tế của người dùng
            int userDetailId = 0;
            string hoVaTen = "Người dùng";
            string? sdt = null;
            string? diaChiMacDinh = null;
            string? email = user.Email;

            if (user.Maquyen == 4) // Khách hàng
            {
                var kh = await _context.Khachhangs.FirstOrDefaultAsync(k => k.Mataikhoan == user.Mataikhoan);
                if (kh != null) {
                    userDetailId = kh.Makh;
                    hoVaTen = kh.Hovaten;
                    sdt = kh.Sdt;
                    diaChiMacDinh = kh.Diachimacdinh;
                    if (string.IsNullOrEmpty(email)) email = kh.Email;
                }
            }
            else // Admin hoặc các phân quyền Nhân viên khác
            {
                var nv = await _context.Nhanviens.FirstOrDefaultAsync(n => n.Mataikhoan == user.Mataikhoan);
                if (nv != null) {
                    userDetailId = nv.Manv;
                    hoVaTen = nv.Hovaten;
                    sdt = nv.Sdt;
                    diaChiMacDinh = null; // Nhân viên không có địa chỉ trong model
                    if (string.IsNullOrEmpty(email)) email = nv.Email;
                }
            }

            return Ok(new
            {
                message = "Đăng nhập thành công!",
                maTaiKhoan = user.Mataikhoan,
                tenDangNhap = user.Tendangnhap,
                roleId = user.Maquyen,
                roleName = user.MaquyenNavigation?.Tenquyen,
                realId = userDetailId, // Cực kỳ quan trọng để Flutter dùng gọi đơn hàng / giỏ hàng
                fullName = hoVaTen,
                sdt = sdt,
                diaChiMacDinh = diaChiMacDinh,
                email = email
            });
        }

        // 3. ĐỔI MẬT KHẨU
        [HttpPut("ChangePassword")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            var user = await _context.Taikhoans.FindAsync(request.MaTaiKhoan);
            if (user == null) return NotFound(new { message = "Tài khoản không tồn tại!" });

            if (user.Matkhau != request.MatKhauCu)
                return BadRequest(new { message = "Mật khẩu cũ không chính xác!" });

            if (request.MatKhauMoi.Length < 6)
                return BadRequest(new { message = "Mật khẩu mới phải có ít nhất 6 ký tự!" });

            user.Matkhau = request.MatKhauMoi;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đổi mật khẩu thành công!" });
        }

        // 4. LOGS HỆ THỐNG (Trả về lịch sử đơn hàng gần đây làm log)
        [HttpGet("Logs")]
        public async Task<IActionResult> GetLogs()
        {
            var logs = await _context.Donhangs
                .OrderByDescending(d => d.Ngaydat)
                .Take(50)
                .Select(d => new
                {
                    Id = d.Madh,
                    Action = $"Đơn hàng #{d.Madh} - {d.Trangthaidonhang}",
                    Detail = $"Người nhận: {d.Tennguoinhan ?? "N/A"} | Tổng: {d.Tongtien:N0}đ",
                    Time = d.Ngaydat
                })
                .ToListAsync();

            return Ok(logs);
        }
    }

    public class RegisterRequest
    {
        public string TenDangNhap { get; set; } = null!;
        public string MatKhau { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string HoVaTen { get; set; } = null!;
        public string? Sdt { get; set; }
        public string? DiaChiMacDinh { get; set; }
    }

    public class LoginRequest
    {
        public string TenDangNhap { get; set; } = null!;
        public string MatKhau { get; set; } = null!;
    }

    public class ChangePasswordRequest
    {
        public int MaTaiKhoan { get; set; }
        public string MatKhauCu { get; set; } = null!;
        public string MatKhauMoi { get; set; } = null!;
    }
}
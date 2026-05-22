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
            // 1. Kiểm tra không được để trống các trường bắt buộc
            if (string.IsNullOrWhiteSpace(request.TenDangNhap) ||
                string.IsNullOrWhiteSpace(request.MatKhau) ||
                string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.HoVaTen) ||
                string.IsNullOrWhiteSpace(request.Sdt) ||
                string.IsNullOrWhiteSpace(request.DiaChiMacDinh) ||
                string.IsNullOrWhiteSpace(request.GioiTinh))
            {
                return BadRequest(new { message = "Vui lòng điền đầy đủ các thông tin bắt buộc!" });
            }

            // 2. Validate email đúng định dạng
            try
            {
                var addr = new System.Net.Mail.MailAddress(request.Email);
                if (addr.Address != request.Email || !request.Email.Contains("."))
                {
                    return BadRequest(new { message = "Email không đúng định dạng" });
                }
            }
            catch
            {
                return BadRequest(new { message = "Email không đúng định dạng" });
            }

            // 3. Validate số điện thoại (chỉ cho nhập số, không ký tự đặc biệt, độ dài hợp lệ từ 9-11 số)
            var cleanedPhone = request.Sdt.Trim();
            if (!System.Text.RegularExpressions.Regex.IsMatch(cleanedPhone, @"^\d{9,11}$"))
            {
                return BadRequest(new { message = "Số điện thoại không hợp lệ (chỉ chứa số, dài từ 9 đến 11 ký tự)!" });
            }

            // 4. Validate mật khẩu tối thiểu 6 ký tự
            if (request.MatKhau.Length < 6)
            {
                return BadRequest(new { message = "Mật khẩu phải có độ dài tối thiểu 6 ký tự!" });
            }

            // 5. Validate ngày sinh không trong tương lai
            if (request.NgaySinh.Date > DateTime.Today)
            {
                return BadRequest(new { message = "Ngày sinh không được vượt quá ngày hiện tại!" });
            }

            // 6. Kiểm tra trùng tên đăng nhập
            if (await _context.Taikhoans.AnyAsync(t => t.Tendangnhap == request.TenDangNhap.Trim()))
            {
                return BadRequest(new { message = "Tên đăng nhập đã tồn tại" });
            }

            // 7. Kiểm tra trùng email
            if (await _context.Taikhoans.AnyAsync(t => t.Email == request.Email.Trim()) ||
                await _context.Khachhangs.AnyAsync(k => k.Email == request.Email.Trim()))
            {
                return BadRequest(new { message = "Email đã được sử dụng" });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Tạo tài khoản hệ thống
                var taiKhoan = new Taikhoan
                {
                    Tendangnhap = request.TenDangNhap.Trim(),
                    Matkhau = request.MatKhau, // Giữ plain-text password theo yêu cầu
                    Email = request.Email.Trim(),
                    Maquyen = 4, // 4: Khách hàng
                    Trangthai = "Hoạt động"
                };

                _context.Taikhoans.Add(taiKhoan);
                await _context.SaveChangesAsync(); // Lấy ra MaTaiKhoan tự tăng

                // Tạo thông tin khách hàng liên kết với tài khoản
                var khachHang = new Khachhang
                {
                    Mataikhoan = taiKhoan.Mataikhoan,
                    Hovaten = request.HoVaTen.Trim(),
                    Gioitinh = request.GioiTinh.Trim(),
                    Ngaysinh = DateOnly.FromDateTime(request.NgaySinh),
                    Sdt = cleanedPhone,
                    Email = request.Email.Trim(),
                    Diachimacdinh = request.DiaChiMacDinh.Trim()
                };

                _context.Khachhangs.Add(khachHang);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();
                return Ok(new { message = "Đăng ký tài khoản thành công" });
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
        [HttpGet("Profile/{maTaiKhoan}")]
        public async Task<IActionResult> GetProfile(int maTaiKhoan)
        {
            var user = await _context.Taikhoans
                .Include(t => t.MaquyenNavigation)
                .Include(t => t.Khachhang)
                .Include(t => t.Nhanvien)
                .FirstOrDefaultAsync(t => t.Mataikhoan == maTaiKhoan);

            if (user == null)
                return NotFound(new { message = "Tài khoản không tồn tại!" });

            return Ok(ToUserProfileResponse(user));
        }

        [HttpPut("Profile/{maTaiKhoan}")]
        public async Task<IActionResult> UpdateProfile(int maTaiKhoan, [FromBody] UpdateProfileRequest request)
        {
            var user = await _context.Taikhoans
                .Include(t => t.MaquyenNavigation)
                .Include(t => t.Khachhang)
                .Include(t => t.Nhanvien)
                .FirstOrDefaultAsync(t => t.Mataikhoan == maTaiKhoan);

            if (user == null)
                return NotFound(new { message = "Tài khoản không tồn tại!" });

            if (string.IsNullOrWhiteSpace(request.HoVaTen))
                return BadRequest(new { message = "Họ và tên không được để trống!" });

            if (string.IsNullOrWhiteSpace(request.Email))
                return BadRequest(new { message = "Email không được để trống!" });

            try
            {
                var addr = new System.Net.Mail.MailAddress(request.Email.Trim());
                if (addr.Address != request.Email.Trim() || !request.Email.Contains("."))
                    return BadRequest(new { message = "Email không đúng định dạng!" });
            }
            catch
            {
                return BadRequest(new { message = "Email không đúng định dạng!" });
            }

            var phone = request.Sdt?.Trim();
            if (!string.IsNullOrWhiteSpace(phone) &&
                !System.Text.RegularExpressions.Regex.IsMatch(phone, @"^\d{9,11}$"))
            {
                return BadRequest(new { message = "Số điện thoại chỉ chứa số và dài từ 9 đến 11 ký tự!" });
            }

            var email = request.Email.Trim();
            var emailExists = await _context.Taikhoans.AnyAsync(t => t.Mataikhoan != maTaiKhoan && t.Email == email)
                || await _context.Khachhangs.AnyAsync(k => k.Mataikhoan != maTaiKhoan && k.Email == email)
                || await _context.Nhanviens.AnyAsync(n => n.Mataikhoan != maTaiKhoan && n.Email == email);

            if (emailExists)
                return BadRequest(new { message = "Email đã được sử dụng bởi tài khoản khác!" });

            user.Email = email;

            if (user.Maquyen == 4)
            {
                if (user.Khachhang == null)
                    return BadRequest(new { message = "Không tìm thấy hồ sơ khách hàng!" });

                user.Khachhang.Hovaten = request.HoVaTen.Trim();
                user.Khachhang.Email = email;
                user.Khachhang.Sdt = phone;
                user.Khachhang.Diachimacdinh = request.DiaChiMacDinh?.Trim();
            }
            else
            {
                if (user.Nhanvien == null)
                    return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên!" });

                user.Nhanvien.Hovaten = request.HoVaTen.Trim();
                user.Nhanvien.Email = email;
                user.Nhanvien.Sdt = phone;
            }

            await _context.SaveChangesAsync();

            return Ok(ToUserProfileResponse(user));
        }

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

        private static object ToUserProfileResponse(Taikhoan user)
    {
        var isCustomer = user.Maquyen == 4;
        var fullName = isCustomer ? user.Khachhang?.Hovaten : user.Nhanvien?.Hovaten;
        var realId = isCustomer ? user.Khachhang?.Makh : user.Nhanvien?.Manv;
        var phone = isCustomer ? user.Khachhang?.Sdt : user.Nhanvien?.Sdt;
        var email = isCustomer ? user.Khachhang?.Email : user.Nhanvien?.Email;

        return new
        {
            maTaiKhoan = user.Mataikhoan,
            tenDangNhap = user.Tendangnhap,
            roleId = user.Maquyen,
            roleName = user.MaquyenNavigation?.Tenquyen,
            realId = realId ?? 0,
            fullName = fullName ?? "Người dùng",
            sdt = phone,
            diaChiMacDinh = user.Khachhang?.Diachimacdinh,
            email = string.IsNullOrWhiteSpace(email) ? user.Email : email
        };
    }

    }

    public class RegisterRequest
    {
        public string TenDangNhap { get; set; } = null!;
        public string MatKhau { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string HoVaTen { get; set; } = null!;
        public string Sdt { get; set; } = null!;
        public string DiaChiMacDinh { get; set; } = null!;
        public string GioiTinh { get; set; } = null!;
        public DateTime NgaySinh { get; set; }
    }

    public class LoginRequest
    {
        public string TenDangNhap { get; set; } = null!;
        public string MatKhau { get; set; } = null!;
    }

    public class UpdateProfileRequest
    {
        public string HoVaTen { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string? Sdt { get; set; }
        public string? DiaChiMacDinh { get; set; }
    }

    public class ChangePasswordRequest
    {
        public int MaTaiKhoan { get; set; }
        public string MatKhauCu { get; set; } = null!;
        public string MatKhauMoi { get; set; } = null!;
    }
}

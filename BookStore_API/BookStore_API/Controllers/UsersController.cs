using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public UsersController(BookStoreContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            var users = await _context.Taikhoans
                .Include(t => t.Nhanvien)
                .Include(t => t.MaquyenNavigation)
                .Where(t => t.Maquyen == 1 || t.Maquyen == 2 || t.Maquyen == 3) // Lấy Admin, Bán hàng, Kho
                .Select(t => new
                {
                    Id = t.Mataikhoan,
                    TenDangNhap = t.Tendangnhap,
                    Email = t.Email,
                    MaQuyen = t.Maquyen,
                    TenQuyen = t.MaquyenNavigation.Tenquyen,
                    TrangThai = t.Trangthai,
                    HoVaTen = t.Nhanvien != null ? t.Nhanvien.Hovaten : "",
                    ChucVu = t.Nhanvien != null ? t.Nhanvien.Chucvu : "",
                    Sdt = t.Nhanvien != null ? t.Nhanvien.Sdt : ""
                })
                .ToListAsync();

            return Ok(users);
        }

        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] UserCreateRequest request)
        {
            using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                // Kiểm tra trùng lặp
                if (await _context.Taikhoans.AnyAsync(t => t.Tendangnhap == request.TenDangNhap))
                    return BadRequest(new { message = "Tên đăng nhập đã tồn tại!" });

                if (await _context.Taikhoans.AnyAsync(t => t.Email == request.Email))
                    return BadRequest(new { message = "Email đã tồn tại!" });

                // Tạo tài khoản
                var tk = new Taikhoan
                {
                    Tendangnhap = request.TenDangNhap,
                    Matkhau = request.MatKhau, // Trong thực tế nên hash mật khẩu
                    Email = request.Email,
                    Maquyen = request.MaQuyen,
                    Trangthai = "Hoạt động"
                };

                _context.Taikhoans.Add(tk);
                await _context.SaveChangesAsync();

                // Tạo nhân viên
                var nv = new Nhanvien
                {
                    Mataikhoan = tk.Mataikhoan,
                    Hovaten = request.HoVaTen,
                    Sdt = request.Sdt,
                    Email = request.Email,
                    Chucvu = request.ChucVu
                };

                _context.Nhanviens.Add(nv);
                await _context.SaveChangesAsync();
                await tx.CommitAsync();

                return Ok(new { message = "Tạo nhân viên thành công!", id = tk.Mataikhoan });
            }
            catch (Exception ex)
            {
                await tx.RollbackAsync();
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}/status")]
        public async Task<IActionResult> ToggleStatus(int id)
        {
            var tk = await _context.Taikhoans.FindAsync(id);
            if (tk == null) return NotFound(new { message = "Tài khoản không tồn tại!" });

            // Không cho phép khóa tài khoản admin gốc (vd: id = 1)
            if (tk.Mataikhoan == 1) return BadRequest(new { message = "Không thể khóa tài khoản Admin hệ thống!" });

            tk.Trangthai = (tk.Trangthai == "Hoạt động") ? "Ngừng hoạt động" : "Hoạt động";
            await _context.SaveChangesAsync();

            return Ok(new { message = $"Đã {(tk.Trangthai == "Hoạt động" ? "mở khóa" : "khóa")} tài khoản." });
        }
    }

    public class UserCreateRequest
    {
        public string TenDangNhap { get; set; } = null!;
        public string MatKhau { get; set; } = null!;
        public string Email { get; set; } = null!;
        public int MaQuyen { get; set; }
        public string HoVaTen { get; set; } = null!;
        public string? Sdt { get; set; }
        public string? ChucVu { get; set; }
    }
}

using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NhaXuatBanController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public NhaXuatBanController(BookStoreContext context)
        {
            _context = context;
        }

        // 1. LẤY DANH SÁCH NHÀ XUẤT BẢN KÈM SỐ SÁCH
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var result = await _context.Nhaxuatbans
                .Select(n => new
                {
                    n.Manxb,
                    n.Tennxb,
                    n.Diachi,
                    n.Sdt,
                    SoSach = n.Saches.Count
                })
                .OrderBy(n => n.Tennxb)
                .ToListAsync();

            return Ok(result);
        }

        // 2. CHI TIẾT 1 NHÀ XUẤT BẢN
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var nxb = await _context.Nhaxuatbans
                .Where(n => n.Manxb == id)
                .Select(n => new
                {
                    n.Manxb,
                    n.Tennxb,
                    n.Diachi,
                    n.Sdt,
                    SoSach = n.Saches.Count,
                    DanhSachSach = n.Saches.Select(s => new { s.Masach, s.Tensach, s.Hinhanh }).ToList()
                })
                .FirstOrDefaultAsync();

            if (nxb == null) return NotFound(new { message = "Không tìm thấy nhà xuất bản." });
            return Ok(nxb);
        }

        // 3. THÊM NHÀ XUẤT BẢN MỚI
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] NhaXuatBanRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.TenNxb))
                return BadRequest(new { message = "Tên nhà xuất bản không được để trống!" });

            try
            {
                var nxb = new Nhaxuatban
                {
                    Tennxb = request.TenNxb.Trim(),
                    Diachi = request.DiaChi?.Trim(),
                    Sdt = request.Sdt?.Trim()
                };

                _context.Nhaxuatbans.Add(nxb);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Thêm nhà xuất bản thành công!", manxb = nxb.Manxb });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        // 4. CẬP NHẬT NHÀ XUẤT BẢN
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] NhaXuatBanRequest request)
        {
            try
            {
                var nxb = await _context.Nhaxuatbans.FindAsync(id);
                if (nxb == null) return NotFound(new { message = "Không tìm thấy nhà xuất bản." });

                if (!string.IsNullOrWhiteSpace(request.TenNxb))
                    nxb.Tennxb = request.TenNxb.Trim();
                if (request.DiaChi != null)
                    nxb.Diachi = request.DiaChi.Trim();
                if (request.Sdt != null)
                    nxb.Sdt = request.Sdt.Trim();

                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Cập nhật nhà xuất bản thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Lỗi cập nhật: " + ex.Message });
            }
        }

        // 5. XÓA NHÀ XUẤT BẢN
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                var nxb = await _context.Nhaxuatbans
                    .Include(n => n.Saches)
                    .FirstOrDefaultAsync(n => n.Manxb == id);

                if (nxb == null) return NotFound(new { message = "Không tìm thấy nhà xuất bản." });

                if (nxb.Saches.Any())
                    return BadRequest(new { message = $"Không thể xóa! NXB đang có {nxb.Saches.Count} đầu sách liên kết." });

                _context.Nhaxuatbans.Remove(nxb);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Đã xóa nhà xuất bản thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Lỗi xóa: " + ex.Message });
            }
        }
    }

    public class NhaXuatBanRequest
    {
        public string TenNxb { get; set; } = null!;
        public string? DiaChi { get; set; }
        public string? Sdt { get; set; }
    }
}

using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TacGiaController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public TacGiaController(BookStoreContext context)
        {
            _context = context;
        }

        // 1. LẤY DANH SÁCH TÁC GIẢ KÈM SỐ SÁCH
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var result = await _context.Tacgia
                .Select(t => new
                {
                    t.Matg,
                    t.Tentg,
                    t.Quoctich,
                    t.Mota,
                    SoSach = t.Saches.Count
                })
                .OrderBy(t => t.Tentg)
                .ToListAsync();

            return Ok(result);
        }

        // 2. CHI TIẾT 1 TÁC GIẢ
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var tacgia = await _context.Tacgia
                .Where(t => t.Matg == id)
                .Select(t => new
                {
                    t.Matg,
                    t.Tentg,
                    t.Quoctich,
                    t.Mota,
                    SoSach = t.Saches.Count,
                    DanhSachSach = t.Saches.Select(s => new { s.Masach, s.Tensach, s.Hinhanh }).ToList()
                })
                .FirstOrDefaultAsync();

            if (tacgia == null) return NotFound(new { message = "Không tìm thấy tác giả." });
            return Ok(tacgia);
        }

        // 3. THÊM TÁC GIẢ MỚI
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] TacGiaRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.TenTg))
                return BadRequest(new { message = "Tên tác giả không được để trống!" });

            try
            {
                var tacgia = new Tacgium
                {
                    Tentg = request.TenTg.Trim(),
                    Quoctich = request.QuocTich?.Trim(),
                    Mota = request.MoTa?.Trim()
                };

                _context.Tacgia.Add(tacgia);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Thêm tác giả thành công!", matg = tacgia.Matg });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        // 4. CẬP NHẬT TÁC GIẢ
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] TacGiaRequest request)
        {
            try
            {
                var tacgia = await _context.Tacgia.FindAsync(id);
                if (tacgia == null) return NotFound(new { message = "Không tìm thấy tác giả." });

                if (!string.IsNullOrWhiteSpace(request.TenTg))
                    tacgia.Tentg = request.TenTg.Trim();
                if (request.QuocTich != null)
                    tacgia.Quoctich = request.QuocTich.Trim();
                if (request.MoTa != null)
                    tacgia.Mota = request.MoTa.Trim();

                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Cập nhật tác giả thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Lỗi cập nhật: " + ex.Message });
            }
        }

        // 5. XÓA TÁC GIẢ
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                var tacgia = await _context.Tacgia
                    .Include(t => t.Saches)
                    .FirstOrDefaultAsync(t => t.Matg == id);

                if (tacgia == null) return NotFound(new { message = "Không tìm thấy tác giả." });

                if (tacgia.Saches.Any())
                    return BadRequest(new { message = $"Không thể xóa! Tác giả đang có {tacgia.Saches.Count} đầu sách liên kết." });

                _context.Tacgia.Remove(tacgia);
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Đã xóa tác giả thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Lỗi xóa: " + ex.Message });
            }
        }
    }

    public class TacGiaRequest
    {
        public string TenTg { get; set; } = null!;
        public string? QuocTich { get; set; }
        public string? MoTa { get; set; }
    }
}

using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PhieuNhapController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public PhieuNhapController(BookStoreContext context)
        {
            _context = context;
        }

        // =========================================================
        // 1. DANH SÁCH PHIẾU NHẬP (theo NV hoặc tất cả)
        // =========================================================
        [HttpGet("DanhSach")]
        public async Task<IActionResult> GetDanhSach([FromQuery] int? maNv)
        {
            var query = _context.Phieunhaps
                .Include(p => p.ManvNavigation)
                .AsQueryable();

            if (maNv.HasValue)
            {
                query = query.Where(p => p.Manv == maNv.Value);
            }

            var result = await query
                .OrderByDescending(p => p.Ngaynhap)
                .Select(p => new
                {
                    p.Mapn,
                    p.Manv,
                    p.Ngaynhap,
                    p.Tongtien,
                    p.Ghichu,
                    TenNhanVien = p.ManvNavigation.Hovaten,
                    SoLuongMuc = p.Chitietphieunhaps.Count
                })
                .ToListAsync();

            return Ok(result);
        }

        // =========================================================
        // 2. CHI TIẾT PHIẾU NHẬP
        // =========================================================
        [HttpGet("ChiTiet/{mapn}")]
        public async Task<IActionResult> GetChiTiet(int mapn)
        {
            var phieuNhap = await _context.Phieunhaps
                .Include(p => p.ManvNavigation)
                .Include(p => p.Chitietphieunhaps)
                    .ThenInclude(ct => ct.MasachNavigation)
                .Where(p => p.Mapn == mapn)
                .Select(p => new
                {
                    p.Mapn,
                    p.Manv,
                    p.Ngaynhap,
                    p.Tongtien,
                    p.Ghichu,
                    TenNhanVien = p.ManvNavigation.Hovaten,
                    ChiTiet = p.Chitietphieunhaps.Select(ct => new
                    {
                        ct.Masach,
                        TenSach = ct.MasachNavigation.Tensach,
                        ct.Soluong,
                        ct.Gianhap,
                        ct.Thanhtien
                    }).ToList()
                })
                .FirstOrDefaultAsync();

            if (phieuNhap == null)
                return NotFound(new { message = "Không tìm thấy phiếu nhập." });

            return Ok(phieuNhap);
        }

        // =========================================================
        // 3. TẠO PHIẾU NHẬP MỚI
        // =========================================================
        [HttpPost("Tao")]
        public async Task<IActionResult> TaoPhieuNhap([FromBody] TaoPhieuNhapRequest request)
        {
            if (request.ChiTiet == null || request.ChiTiet.Count == 0)
                return BadRequest(new { message = "Phiếu nhập phải có ít nhất 1 mục." });

            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                // Tính tổng tiền
                decimal tongTien = request.ChiTiet.Sum(ct => ct.SoLuong * ct.GiaNhap);

                var phieuNhap = new Phieunhap
                {
                    Manv = request.MaNv,
                    Ngaynhap = DateTime.Now,
                    Tongtien = tongTien,
                    Ghichu = request.GhiChu
                };

                _context.Phieunhaps.Add(phieuNhap);
                await _context.SaveChangesAsync();

                // Thêm chi tiết (trigger DB sẽ tự cập nhật tồn kho)
                foreach (var ct in request.ChiTiet)
                {
                    var chiTiet = new Chitietphieunhap
                    {
                        Mapn = phieuNhap.Mapn,
                        Masach = ct.MaSach,
                        Soluong = ct.SoLuong,
                        Gianhap = ct.GiaNhap
                    };
                    _context.Chitietphieunhaps.Add(chiTiet);
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new
                {
                    message = "Tạo phiếu nhập thành công!",
                    maPhieuNhap = phieuNhap.Mapn,
                    tongTien = tongTien
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = $"Lỗi tạo phiếu nhập: {ex.Message}" });
            }
        }
    }

    // =========================================================
    // REQUEST DTOs
    // =========================================================
    public class TaoPhieuNhapRequest
    {
        public int MaNv { get; set; }
        public string? GhiChu { get; set; }
        public List<ChiTietPhieuNhapRequest> ChiTiet { get; set; } = new();
    }

    public class ChiTietPhieuNhapRequest
    {
        public int MaSach { get; set; }
        public int SoLuong { get; set; }
        public decimal GiaNhap { get; set; }
    }
}

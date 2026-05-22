using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SachController : ControllerBase
    {
        private readonly BookStoreContext _context;
        private readonly IWebHostEnvironment _env;

        public SachController(BookStoreContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // 1. LẤY TOÀN BỘ SÁCH KÈM GIÁ KHUYẾN MÃI DỰA THEO THỜI GIAN THỰC
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var now = DateTime.Now;

            var result = await _context.Saches
                .Include(s => s.MatgNavigation)
                .Include(s => s.ManxbNavigation)
                .Include(s => s.MakmNavigation)
                .Include(s => s.MatheloaiNavigation)
                .Select(s => new
                {
                    s.Masach,
                    s.Tensach,
                    s.Mota,
                    s.Soluongton,
                    s.Trangthai,
                    s.Hinhanh,
                    TenTacGia = s.MatgNavigation.Tentg,
                    TenNxb = s.ManxbNavigation.Tennxb,
                    GiaGoc = s.Giaban,
                    TenTheLoai = s.MatheloaiNavigation.Tentheloai,
                    // Nếu sách được gán mã KM và đợt KM đang nằm trong thời gian hiệu lực
                    PhanTramGiam = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                                   ? s.MakmNavigation.Phantramgiam : 0,
                    GiaBanThucTe = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                                   ? (s.Giaban - (s.Giaban * s.MakmNavigation.Phantramgiam / 100)) : s.Giaban,
                    TenSuKienKhuyenMai = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                                   ? s.MakmNavigation.Tenkm : null
                }).ToListAsync();

            return Ok(result);
        }

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var now = DateTime.Now;

            var result = await _context.Saches
                .Include(s => s.MatgNavigation)
                .Include(s => s.ManxbNavigation)
                .Include(s => s.MakmNavigation)
                .Include(s => s.MatheloaiNavigation)
                .Where(s => s.Masach == id)
                .Select(s => new
                {
                    s.Masach,
                    s.Tensach,
                    s.Mota,
                    s.Soluongton,
                    s.Trangthai,
                    s.Hinhanh,
                    TenTacGia = s.MatgNavigation.Tentg,
                    TenNxb = s.ManxbNavigation.Tennxb,
                    GiaGoc = s.Giaban,
                    TenTheLoai = s.MatheloaiNavigation.Tentheloai,
                    PhanTramGiam = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                                   ? s.MakmNavigation.Phantramgiam : 0,
                    GiaBanThucTe = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                                   ? (s.Giaban - (s.Giaban * s.MakmNavigation.Phantramgiam / 100)) : s.Giaban,
                    TenSuKienKhuyenMai = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                                   ? s.MakmNavigation.Tenkm : null
                }).FirstOrDefaultAsync();

            if (result == null) return NotFound();

            return Ok(result);
        }

        // 2. LỌC SÁCH NÂNG CAO
        [HttpGet("filter")]
        public async Task<IActionResult> FilterBooks([FromQuery] string? author, [FromQuery] string? publisher, [FromQuery] decimal? minPrice, [FromQuery] decimal? maxPrice)
        {
            var now = DateTime.Now;

            var query = _context.Saches
                .Include(s => s.MatgNavigation)
                .Include(s => s.ManxbNavigation)
                .Include(s => s.MakmNavigation)
                .Include(s => s.MatheloaiNavigation)
                .AsQueryable();

            if (!string.IsNullOrEmpty(author))
            {
                query = query.Where(s => s.MatgNavigation != null && s.MatgNavigation.Tentg.Contains(author));
            }

            if (!string.IsNullOrEmpty(publisher))
            {
                query = query.Where(s => s.ManxbNavigation != null && s.ManxbNavigation.Tennxb.Contains(publisher));
            }

            var projected = await query.Select(s => new
            {
                s.Masach,
                s.Tensach,
                s.Mota,
                s.Soluongton,
                s.Trangthai,
                s.Hinhanh,
                TenTacGia = s.MatgNavigation.Tentg,
                TenNxb = s.ManxbNavigation.Tennxb,
                GiaGoc = s.Giaban,
                TenTheLoai = s.MatheloaiNavigation.Tentheloai,
                PhanTramGiam = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                               ? s.MakmNavigation.Phantramgiam : 0,
                GiaBanThucTe = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                               ? (s.Giaban - (s.Giaban * s.MakmNavigation.Phantramgiam / 100)) : s.Giaban,
                TenSuKienKhuyenMai = (s.Makm != null && s.MakmNavigation.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now)
                               ? s.MakmNavigation.Tenkm : null
            }).ToListAsync();

            if (minPrice.HasValue)
            {
                projected = projected.Where(s => s.GiaBanThucTe >= minPrice.Value).ToList();
            }

            if (maxPrice.HasValue)
            {
                projected = projected.Where(s => s.GiaBanThucTe <= maxPrice.Value).ToList();
            }

            return Ok(projected);
        }

        [HttpGet("authors")]
        public async Task<IActionResult> GetAuthors()
        {
            var authors = await _context.Tacgia
                .Select(t => t.Tentg)
                .Distinct()
                .OrderBy(t => t)
                .ToListAsync();
            return Ok(authors);
        }

        [HttpGet("publishers")]
        public async Task<IActionResult> GetPublishers()
        {
            var publishers = await _context.Nhaxuatbans
                .Select(n => n.Tennxb)
                .Distinct()
                .OrderBy(n => n)
                .ToListAsync();
            return Ok(publishers);
        }

        // 3. NHÂN VIÊN KHO THÊM SÁCH MỚI CÓ TẢI ẢNH LÊN
        [HttpPost("ThemSach")]
        public async Task<IActionResult> ThemSach([FromForm] FormSachRequest request)
        {
            try
            {
                string nameOfFile = "default_book.jpg";

                if (request.FileHinhAnh != null && request.FileHinhAnh.Length > 0)
                {
                    string ext = Path.GetExtension(request.FileHinhAnh.FileName);
                    nameOfFile = Guid.NewGuid().ToString() + ext; // Đảm bảo tên file không bị trùng

                    string rootFolderPath = Path.Combine(_env.WebRootPath, "images");
                    if (!Directory.Exists(rootFolderPath)) Directory.CreateDirectory(rootFolderPath);

                    string finalPath = Path.Combine(rootFolderPath, nameOfFile);
                    using (var fs = new FileStream(finalPath, FileMode.Create))
                    {
                        await request.FileHinhAnh.CopyToAsync(fs);
                    }
                }

                var sach = new Sach
                {
                    Tensach = request.TenSach,
                    Matg = request.Matg,
                    Manxb = request.Manxb,
                    Matheloai = request.Matheloai,
                    Mota = request.Mota,
                    Giaban = request.GiaBán,
                    Soluongton = request.SoLuongTon,
                    Makm = request.Makm == 0 ? null : request.Makm,
                    Hinhanh = nameOfFile,
                    Trangthai = request.SoLuongTon > 0 ? "Có sẵn" : "Đã hết"
                };

                _context.Saches.Add(sach);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Thêm đầu sách mới thành công!", bookId = sach.Masach });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi xử lý file hoặc DB: {ex.Message}" });
            }
        }

        // =========================================================
        // 4. LẤY DANH SÁCH THỂ LOẠI (có ID)
        // =========================================================
        [HttpGet("TheLoai")]
        public async Task<IActionResult> GetTheLoai()
        {
            var result = await _context.Theloais
                .Select(t => new { t.Matheloai, t.Tentheloai })
                .OrderBy(t => t.Tentheloai)
                .ToListAsync();
            return Ok(result);
        }

        // =========================================================
        // 5. LẤY DANH SÁCH TÁC GIẢ (có ID)
        // =========================================================
        [HttpGet("TacGiaList")]
        public async Task<IActionResult> GetTacGiaList()
        {
            var result = await _context.Tacgia
                .Select(t => new { t.Matg, t.Tentg })
                .OrderBy(t => t.Tentg)
                .ToListAsync();
            return Ok(result);
        }

        // =========================================================
        // 6. LẤY DANH SÁCH NHÀ XUẤT BẢN (có ID)
        // =========================================================
        [HttpGet("NhaXuatBanList")]
        public async Task<IActionResult> GetNhaXuatBanList()
        {
            var result = await _context.Nhaxuatbans
                .Select(n => new { n.Manxb, n.Tennxb })
                .OrderBy(n => n.Tennxb)
                .ToListAsync();
            return Ok(result);
        }

        // =========================================================
        // 7. CẬP NHẬT SÁCH
        // =========================================================
        [HttpPut("CapNhat/{id}")]
        public async Task<IActionResult> CapNhatSach(int id, [FromBody] CapNhatSachRequest request)
        {
            try
            {
                var sach = await _context.Saches.FindAsync(id);
                if (sach == null)
                    return NotFound(new { message = "Không tìm thấy sách." });

                sach.Tensach = request.TenSach ?? sach.Tensach;
                sach.Giaban = request.GiaBan ?? sach.Giaban;
                sach.Mota = request.MoTa ?? sach.Mota;
                sach.Matheloai = request.MaTheLoai ?? sach.Matheloai;
                sach.Matg = request.MaTg ?? sach.Matg;
                sach.Manxb = request.MaNxb ?? sach.Manxb;

                if (request.HinhAnh != null)
                    sach.Hinhanh = request.HinhAnh;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Cập nhật sách thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi cập nhật: {ex.Message}" });
            }
        }

        // =========================================================
        // 8. XÓA SÁCH (SOFT DELETE - đổi trạng thái)
        // =========================================================
        [HttpDelete("Xoa/{id}")]
        public async Task<IActionResult> XoaSach(int id)
        {
            try
            {
                var sach = await _context.Saches
                    .Include(s => s.Chitietdonhangs)
                    .FirstOrDefaultAsync(s => s.Masach == id);

                if (sach == null)
                    return NotFound(new { message = "Không tìm thấy sách." });

                // Soft delete: đổi trạng thái và set tồn kho = 0
                sach.Trangthai = "Đã hết";
                sach.Soluongton = 0;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã ngừng kinh doanh sách này." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Lỗi xóa sách: {ex.Message}" });
            }
        }
    }

    public class CapNhatSachRequest
    {
        public string? TenSach { get; set; }
        public decimal? GiaBan { get; set; }
        public string? MoTa { get; set; }
        public int? MaTheLoai { get; set; }
        public int? MaTg { get; set; }
        public int? MaNxb { get; set; }
        public string? HinhAnh { get; set; }
    }

    public class FormSachRequest
    {
        public string TenSach { get; set; } = null!;
        public int Matg { get; set; }
        public int Manxb { get; set; }
        public int Matheloai { get; set; }
        public string? Mota { get; set; }
        public decimal GiaBán { get; set; }
        public int SoLuongTon { get; set; }
        public int? Makm { get; set; }
        public IFormFile? FileHinhAnh { get; set; }
    }
}
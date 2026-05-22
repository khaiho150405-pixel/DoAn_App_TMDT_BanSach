using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HoiDapController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public HoiDapController(BookStoreContext context)
        {
            _context = context;
        }

        // =========================================================
        // 1. DÀNH CHO NHÂN VIÊN SALE (Tương thích ngược)
        // =========================================================

        // 1.1 LẤY DANH SÁCH CÂU HỎI CHƯA TRẢ LỜI
        [HttpGet("ChuaTraLoi")]
        public async Task<IActionResult> GetPendingQuestions()
        {
            var questions = await _context.Hoidaps
                .Include(h => h.MakhNavigation)
                .Where(h => h.Trangthai == "Chờ trả lời")
                .OrderByDescending(h => h.Thoigiantao)
                .Select(h => new
                {
                    Mahoidap = h.Mahoidap,
                    Makh = h.Makh,
                    TenKhachHang = h.MakhNavigation.Hovaten,
                    Cauhoi = h.Noidung,
                    Traloi = (string?)null,
                    Thoigianhoi = h.Thoigiantao,
                    Thoigiantraloi = (DateTime?)null,
                    Trangthai = h.Trangthai
                })
                .ToListAsync();

            return Ok(questions);
        }

        // 1.2 LẤY TẤT CẢ CÂU HỎI (Bao gồm đã trả lời)
        [HttpGet("TatCa")]
        public async Task<IActionResult> GetAllQuestions()
        {
            var questions = await _context.Hoidaps
                .Include(h => h.MakhNavigation)
                .Include(h => h.ManvphutrachNavigation)
                .OrderByDescending(h => h.Thoigiantao)
                .Select(h => new
                {
                    Mahoidap = h.Mahoidap,
                    Makh = h.Makh,
                    TenKhachHang = h.MakhNavigation.Hovaten,
                    Cauhoi = h.Noidung,
                    Traloi = h.Tinnhanhotros
                        .Where(t => t.Nguoigui == "NhanVien")
                        .OrderByDescending(t => t.Thoigian)
                        .Select(t => t.Noidung)
                        .FirstOrDefault(),
                    Manv = h.Manvphutrach,
                    TenNhanVien = h.ManvphutrachNavigation != null ? h.ManvphutrachNavigation.Hovaten : null,
                    Thoigianhoi = h.Thoigiantao,
                    Thoigiantraloi = h.Capnhatcuoi,
                    Trangthai = h.Trangthai
                })
                .ToListAsync();

            return Ok(questions);
        }

        // 1.3 NHÂN VIÊN TRẢ LỜI CÂU HỎI (Tích hợp ghi vào bảng TINNHANHOTRO)
        [HttpPut("TraLoi/{maHoiDap}")]
        public async Task<IActionResult> ReplyQuestion(int maHoiDap, [FromBody] ReplyRequest request)
        {
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var ticket = await _context.Hoidaps.FindAsync(maHoiDap);
                    if (ticket == null)
                        return NotFound(new { message = "Không tìm thấy yêu cầu hỗ trợ!" });

                    ticket.Trangthai = "Đã trả lời";
                    ticket.Manvphutrach = request.MaNV;
                    ticket.Capnhatcuoi = DateTime.Now;

                    // Tạo tin nhắn phản hồi của nhân viên trong TINNHANHOTRO
                    var message = new Tinnhanhotro
                    {
                        Mahoidap = maHoiDap,
                        Nguoigui = "NhanVien",
                        Manv = request.MaNV,
                        Noidung = request.TraLoi,
                        Thoigian = DateTime.Now,
                        Daxem = false
                    };

                    _context.Tinnhanhotros.Add(message);
                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Ok(new { success = true, message = "Đã gửi câu trả lời hỗ trợ thành công!" });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return StatusCode(500, new { success = false, message = "Lỗi hệ thống: " + ex.Message });
                }
            }
        }

        // =========================================================
        // 2. DÀNH CHO KHÁCH HÀNG (Mới)
        // =========================================================

        // 2.1 LẤY DANH SÁCH TICKET HỖ TRỢ CỦA KHÁCH HÀNG
        [HttpGet("KhachHang/{maKh}")]
        public async Task<IActionResult> GetTicketsByCustomer(int maKh)
        {
            var tickets = await _context.Hoidaps
                .Where(h => h.Makh == maKh)
                .OrderByDescending(h => h.Capnhatcuoi ?? h.Thoigiantao)
                .Select(h => new
                {
                    h.Mahoidap,
                    h.Makh,
                    h.Tieude,
                    h.Noidung,
                    h.Loaihotro,
                    h.Trangthai,
                    h.Thoigiantao,
                    h.Capnhatcuoi,
                    h.Manvphutrach,
                    TinNhanCuoi = h.Tinnhanhotros
                        .OrderByDescending(t => t.Thoigian)
                        .Select(t => t.Noidung)
                        .FirstOrDefault() ?? h.Noidung
                })
                .ToListAsync();

            return Ok(tickets);
        }

        // 2.2 TẠO TICKET HỖ TRỢ MỚI
        [HttpPost("Tao")]
        public async Task<IActionResult> CreateTicket([FromBody] CreateTicketRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.TieuDe) || string.IsNullOrWhiteSpace(request.NoiDung))
            {
                return BadRequest(new { success = false, message = "Tiêu đề và nội dung không được để trống!" });
            }

            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var ticket = new Hoidap
                    {
                        Makh = request.MaKh,
                        Tieude = request.TieuDe.Trim(),
                        Noidung = request.NoiDung.Trim(),
                        Loaihotro = request.LoaiHoTro,
                        Trangthai = "Chờ trả lời",
                        Thoigiantao = DateTime.Now,
                        Capnhatcuoi = DateTime.Now
                    };

                    _context.Hoidaps.Add(ticket);
                    await _context.SaveChangesAsync();

                    // Tự động tạo tin nhắn chat đầu tiên trong TINNHANHOTRO
                    var firstMessage = new Tinnhanhotro
                    {
                        Mahoidap = ticket.Mahoidap,
                        Nguoigui = "KhachHang",
                        Makh = request.MaKh,
                        Noidung = request.NoiDung.Trim(),
                        Thoigian = DateTime.Now,
                        Daxem = false
                    };

                    _context.Tinnhanhotros.Add(firstMessage);
                    await _context.SaveChangesAsync();

                    await transaction.CommitAsync();

                    return Ok(new { success = true, message = "Tạo yêu cầu hỗ trợ thành công!", maHoiDap = ticket.Mahoidap });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return StatusCode(500, new { success = false, message = "Không thể tạo yêu cầu hỗ trợ: " + ex.Message });
                }
            }
        }

        // 2.3 LẤY TOÀN BỘ TIN NHẮN THEO MAHOIDAP
        [HttpGet("TinNhan/{maHoiDap}")]
        public async Task<IActionResult> GetMessages(int maHoiDap)
        {
            var messages = await _context.Tinnhanhotros
                .Where(t => t.Mahoidap == maHoiDap)
                .OrderBy(t => t.Thoigian)
                .Select(t => new
                {
                    t.Matinnhan,
                    t.Mahoidap,
                    t.Nguoigui,
                    t.Makh,
                    t.Manv,
                    t.Noidung,
                    t.Hinhanh,
                    t.Daxem,
                    t.Thoigian
                })
                .ToListAsync();

            return Ok(messages);
        }

        // 2.4 GỬI TIN NHẮN MỚI
        [HttpPost("TinNhan/Gui")]
        public async Task<IActionResult> SendMessage([FromBody] SendMessageRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.NoiDung))
            {
                return BadRequest(new { success = false, message = "Nội dung tin nhắn không được để trống!" });
            }

            var ticket = await _context.Hoidaps.FindAsync(request.MaHoiDap);
            if (ticket == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy yêu cầu hỗ trợ!" });
            }

            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var message = new Tinnhanhotro
                    {
                        Mahoidap = request.MaHoiDap,
                        Nguoigui = request.NguoiGui,
                        Makh = request.NguoiGui == "KhachHang" ? request.MaKh : null,
                        Manv = request.NguoiGui == "NhanVien" ? request.MaNv : null,
                        Noidung = request.NoiDung.Trim(),
                        Thoigian = DateTime.Now,
                        Daxem = false
                    };

                    _context.Tinnhanhotros.Add(message);

                    // Cập nhật trạng thái ticket
                    ticket.Capnhatcuoi = DateTime.Now;
                    if (request.NguoiGui == "KhachHang")
                    {
                        ticket.Trangthai = "Chờ trả lời";
                    }
                    else if (request.NguoiGui == "NhanVien")
                    {
                        ticket.Trangthai = "Đã trả lời";
                        if (request.MaNv.HasValue)
                        {
                            ticket.Manvphutrach = request.MaNv;
                        }
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Ok(new { success = true, message = "Gửi tin nhắn thành công!", data = message });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return StatusCode(500, new { success = false, message = "Không thể gửi tin nhắn: " + ex.Message });
                }
            }
        }
    }

    public class ReplyRequest
    {
        public string TraLoi { get; set; } = null!;
        public int MaNV { get; set; }
    }

    public class CreateTicketRequest
    {
        public int MaKh { get; set; }
        public string TieuDe { get; set; } = null!;
        public string LoaiHoTro { get; set; } = null!;
        public string NoiDung { get; set; } = null!;
    }

    public class SendMessageRequest
    {
        public int MaHoiDap { get; set; }
        public string NguoiGui { get; set; } = null!; // "KhachHang" or "NhanVien"
        public int? MaKh { get; set; }
        public int? MaNv { get; set; }
        public string NoiDung { get; set; } = null!;
    }
}

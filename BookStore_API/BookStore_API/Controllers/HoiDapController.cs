using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
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
                .Include(h => h.Tinnhans)
                .Where(h => h.Trangthai == "Chờ trả lời")
                .OrderByDescending(h => h.Thoigianhoi)
                .Select(h => new
                {
                    Mahoidap = h.Mahoidap,
                    Makh = h.Makh,
                    TenKhachHang = h.MakhNavigation.Hovaten,
                    Tieude = "",
                    Cauhoi = h.Cauhoi,
                    LoaiHoTro = "",
                    Traloi = (string?)null,
                    Thoigianhoi = h.Thoigianhoi,
                    Thoigiantraloi = (DateTime?)null,
                    Trangthai = h.Trangthai,
                    TinNhanCuoi = h.Tinnhans
                        .OrderByDescending(t => t.Thoigian)
                        .Select(t => t.Noidung)
                        .FirstOrDefault() ?? h.Cauhoi
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
                .Include(h => h.ManvNavigation)
                .Include(h => h.Tinnhans)
                .OrderByDescending(h => h.Thoigianhoi)
                .Select(h => new
                {
                    Mahoidap = h.Mahoidap,
                    Makh = h.Makh,
                    TenKhachHang = h.MakhNavigation.Hovaten,
                    Tieude = "",
                    Cauhoi = h.Cauhoi,
                    LoaiHoTro = "",
                    Traloi = h.Traloi,
                    Manv = h.Manv,
                    TenNhanVien = h.ManvNavigation != null ? h.ManvNavigation.Hovaten : null,
                    Thoigianhoi = h.Thoigianhoi,
                    Thoigiantraloi = h.Thoigiantraloi,
                    Trangthai = h.Trangthai,
                    TinNhanCuoi = h.Tinnhans
                        .OrderByDescending(t => t.Thoigian)
                        .Select(t => t.Noidung)
                        .FirstOrDefault() ?? h.Traloi ?? h.Cauhoi
                })
                .ToListAsync();

            return Ok(questions);
        }

        // 1.3 NHÂN VIÊN TRẢ LỜI CÂU HỎI (Tương thích ngược)
        [HttpPut("TraLoi/{maHoiDap}")]
        public async Task<IActionResult> ReplyQuestion(int maHoiDap, [FromBody] ReplyRequest request)
        {
            try
            {
                var ticket = await _context.Hoidaps.FindAsync(maHoiDap);
                if (ticket == null)
                    return NotFound(new { message = "Không tìm thấy yêu cầu hỗ trợ!" });

                ticket.Traloi = request.TraLoi;
                ticket.Manv = request.MaNV;
                ticket.Thoigiantraloi = DateTime.Now;
                ticket.Trangthai = "Đã trả lời";

                // Đồng thời lưu vào bảng TINNHAN
                _context.Tinnhans.Add(new Tinnhan
                {
                    Mahoidap = maHoiDap,
                    Nguoigui = "NhanVien",
                    Manv = request.MaNV,
                    Noidung = request.TraLoi.Trim(),
                    Thoigian = DateTime.Now
                });

                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Đã gửi câu trả lời hỗ trợ thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Lỗi hệ thống: " + ex.Message });
            }
        }

        // =========================================================
        // 2. DÀNH CHO KHÁCH HÀNG
        // =========================================================

        // 2.1 LẤY DANH SÁCH TICKET HỖ TRỢ CỦA KHÁCH HÀNG
        [HttpGet("KhachHang/{maKh}")]
        public async Task<IActionResult> GetTicketsByCustomer(int maKh)
        {
            var tickets = await _context.Hoidaps
                .Include(h => h.Tinnhans)
                .Where(h => h.Makh == maKh)
                .OrderByDescending(h => h.Thoigiantraloi ?? h.Thoigianhoi)
                .Select(h => new
                {
                    h.Mahoidap,
                    h.Makh,
                    Tieude = "",
                    Noidung = h.Cauhoi,
                    Loaihotro = "",
                    h.Trangthai,
                    Thoigiantao = h.Thoigianhoi,
                    Capnhatcuoi = h.Thoigiantraloi ?? h.Thoigianhoi,
                    Manvphutrach = h.Manv,
                    TinNhanCuoi = h.Tinnhans
                        .OrderByDescending(t => t.Thoigian)
                        .Select(t => t.Noidung)
                        .FirstOrDefault() ?? h.Traloi ?? h.Cauhoi
                })
                .ToListAsync();

            return Ok(tickets);
        }

        // 2.2 TẠO TICKET HỖ TRỢ MỚI
        [HttpPost("Tao")]
        public async Task<IActionResult> CreateTicket([FromBody] CreateTicketRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.NoiDung))
            {
                return BadRequest(new { success = false, message = "Nội dung không được để trống!" });
            }

            try
            {
                var ticket = new Hoidap
                {
                    Makh = request.MaKh,
                    Cauhoi = request.NoiDung.Trim(),
                    Thoigianhoi = DateTime.Now,
                    Trangthai = "Chờ trả lời"
                };

                _context.Hoidaps.Add(ticket);
                await _context.SaveChangesAsync();

                // Tạo tin nhắn đầu tiên trong bảng TINNHAN
                _context.Tinnhans.Add(new Tinnhan
                {
                    Mahoidap = ticket.Mahoidap,
                    Nguoigui = "KhachHang",
                    Makh = request.MaKh,
                    Noidung = request.NoiDung.Trim(),
                    Thoigian = DateTime.Now
                });
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Tạo yêu cầu hỗ trợ thành công!", maHoiDap = ticket.Mahoidap });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Không thể tạo yêu cầu hỗ trợ: " + ex.Message });
            }
        }

        // 2.3 LẤY TOÀN BỘ TIN NHẮN THEO MAHOIDAP (từ bảng TINNHAN)
        [HttpGet("TinNhan/{maHoiDap}")]
        public async Task<IActionResult> GetMessages(int maHoiDap)
        {
            var ticket = await _context.Hoidaps
                .FirstOrDefaultAsync(x => x.Mahoidap == maHoiDap);

            if (ticket == null)
                return NotFound(new { success = false, message = "Không tìm thấy yêu cầu hỗ trợ!" });

            // Lấy tin nhắn từ bảng TINNHAN
            var messages = await _context.Tinnhans
                .Where(t => t.Mahoidap == maHoiDap)
                .OrderBy(t => t.Thoigian)
                .Select(t => new
                {
                    matinnhan = t.Matinnhan,
                    mahoidap = t.Mahoidap,
                    nguoigui = t.Nguoigui,
                    makh = t.Makh,
                    manv = t.Manv,
                    noidung = t.Noidung,
                    hinhanh = (string?)null,
                    daxem = true,
                    thoigian = t.Thoigian ?? DateTime.Now
                })
                .ToListAsync();

            // Backward compatibility: Nếu chưa có tin nhắn trong TINNHAN,
            // tạo từ Cauhoi/Traloi cũ trong bảng HOIDAP
            if (!messages.Any())
            {
                var list = new List<object>();

                // Tin nhắn 1: Câu hỏi của khách hàng
                if (!string.IsNullOrWhiteSpace(ticket.Cauhoi))
                {
                    list.Add(new
                    {
                        matinnhan = 1,
                        mahoidap = ticket.Mahoidap,
                        nguoigui = "KhachHang",
                        makh = (int?)ticket.Makh,
                        manv = (int?)null,
                        noidung = ticket.Cauhoi,
                        hinhanh = (string?)null,
                        daxem = true,
                        thoigian = ticket.Thoigianhoi ?? DateTime.Now
                    });
                }

                // Tin nhắn 2: Câu trả lời của nhân viên (nếu có)
                if (!string.IsNullOrWhiteSpace(ticket.Traloi))
                {
                    list.Add(new
                    {
                        matinnhan = 2,
                        mahoidap = ticket.Mahoidap,
                        nguoigui = "NhanVien",
                        makh = (int?)null,
                        manv = ticket.Manv,
                        noidung = ticket.Traloi,
                        hinhanh = (string?)null,
                        daxem = true,
                        thoigian = ticket.Thoigiantraloi ?? DateTime.Now
                    });
                }

                return Ok(list);
            }

            return Ok(messages);
        }

        // 2.4 GỬI TIN NHẮN MỚI (Lưu vào bảng TINNHAN)
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

            try
            {
                // Lưu tin nhắn mới vào bảng TINNHAN
                var newMessage = new Tinnhan
                {
                    Mahoidap = request.MaHoiDap,
                    Nguoigui = request.NguoiGui,
                    Makh = request.NguoiGui == "KhachHang" ? request.MaKh : null,
                    Manv = request.NguoiGui == "NhanVien" ? request.MaNv : null,
                    Noidung = request.NoiDung.Trim(),
                    Thoigian = DateTime.Now
                };

                _context.Tinnhans.Add(newMessage);

                // Cập nhật trạng thái ticket
                if (request.NguoiGui == "KhachHang")
                {
                    ticket.Trangthai = "Chờ trả lời";
                }
                else if (request.NguoiGui == "NhanVien")
                {
                    ticket.Traloi = request.NoiDung.Trim();
                    ticket.Thoigiantraloi = DateTime.Now;
                    ticket.Trangthai = "Đã trả lời";
                    if (request.MaNv.HasValue)
                    {
                        ticket.Manv = request.MaNv;
                    }
                }

                await _context.SaveChangesAsync();

                // Tạo đối tượng tin nhắn trả về tương thích với frontend
                var responseMessage = new
                {
                    matinnhan = newMessage.Matinnhan,
                    mahoidap = ticket.Mahoidap,
                    nguoigui = request.NguoiGui,
                    makh = request.NguoiGui == "KhachHang" ? request.MaKh : null,
                    manv = request.NguoiGui == "NhanVien" ? request.MaNv : null,
                    noidung = request.NoiDung.Trim(),
                    hinhanh = (string?)null,
                    daxem = true,
                    thoigian = newMessage.Thoigian ?? DateTime.Now
                };

                return Ok(new { success = true, message = "Gửi tin nhắn thành công!", data = responseMessage });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Không thể gửi tin nhắn: " + ex.Message });
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

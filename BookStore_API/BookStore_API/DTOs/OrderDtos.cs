using System;
using System.Collections.Generic;

namespace BookStoreAPI.DTOs
{
    public class CheckoutRequestDto
    {
        public int MaKH { get; set; }
        public string TenNguoiNhan { get; set; } = null!;
        public string SdtNhan { get; set; } = null!;
        public string DiaChiGiao { get; set; } = null!;
        public string PhuongThucThanhToan { get; set; } = null!;
        public string? GhiChu { get; set; }
        public decimal TongTien { get; set; }
        public List<OrderItemDto> Items { get; set; } = new List<OrderItemDto>();
    }

    public class OrderItemDto
    {
        public int MaSach { get; set; }
        public int SoLuong { get; set; }
        public decimal DonGia { get; set; }
    }

    public class OrderResponseDto
    {
        public int MaDH { get; set; }
        public DateTime NgayDat { get; set; }
        public decimal TongTien { get; set; }
        public string TenNguoiNhan { get; set; } = null!;
        public string SdtNhan { get; set; } = null!;
        public string DiaChiGiao { get; set; } = null!;
        public string PhuongThucThanhToan { get; set; } = null!;
        public string TrangThaiThanhToan { get; set; } = null!;
        public string TrangThaiDonHang { get; set; } = null!;
        public int SoLuongSanPham { get; set; }
        public List<OrderDetailDto> ChiTiet { get; set; } = new List<OrderDetailDto>();
    }

    public class OrderDetailDto
    {
        public int MaSach { get; set; }
        public string TenSach { get; set; } = null!;
        public string HinhAnh { get; set; } = null!;
        public int SoLuong { get; set; }
        public decimal DonGia { get; set; }
        public decimal ThanhTien { get; set; }
    }
}

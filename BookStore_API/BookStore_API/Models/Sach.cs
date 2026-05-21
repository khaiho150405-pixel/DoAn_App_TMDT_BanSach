using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Sach
{
    public int Masach { get; set; }

    public string Tensach { get; set; } = null!;

    public int Matg { get; set; }

    public int Manxb { get; set; }

    public int Matheloai { get; set; }

    public int? Makm { get; set; }

    public string? Hinhanh { get; set; }

    public string? Mota { get; set; }

    public decimal Giaban { get; set; }
    public int Soluongton { get; set; }

    public string Trangthai { get; set; } = null!;

    public virtual ICollection<Chitietdonhang> Chitietdonhangs { get; set; } = new List<Chitietdonhang>();

    public virtual ICollection<Chitietgiohang> Chitietgiohangs { get; set; } = new List<Chitietgiohang>();

    public virtual ICollection<Chitietphieunhap> Chitietphieunhaps { get; set; } = new List<Chitietphieunhap>();

    public virtual ICollection<Danhgiasach> Danhgiasaches { get; set; } = new List<Danhgiasach>();

    public virtual Khuyenmai? MakmNavigation { get; set; }

    public virtual Nhaxuatban ManxbNavigation { get; set; } = null!;

    public virtual Tacgium MatgNavigation { get; set; } = null!;

    public virtual Theloai MatheloaiNavigation { get; set; } = null!;
}

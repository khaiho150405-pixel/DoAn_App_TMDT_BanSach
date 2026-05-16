using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Donhang
{
    public int Madh { get; set; }

    public int Makh { get; set; }

    public int? Manv { get; set; }

    public DateTime Ngaydat { get; set; }

    public decimal Tongtien { get; set; }

    public string Tennguoinhan { get; set; } = null!;

    public string Sdtnhan { get; set; } = null!;

    public string Diachigiao { get; set; } = null!;

    public string? Phuongthucthanhtoan { get; set; }

    public string? Trangthaithanhtoan { get; set; }

    public string? Trangthaidonhang { get; set; }

    public string? Ghichu { get; set; }

    public virtual ICollection<Chitietdonhang> Chitietdonhangs { get; set; } = new List<Chitietdonhang>();

    public virtual Khachhang MakhNavigation { get; set; } = null!;

    public virtual Nhanvien? ManvNavigation { get; set; }
}

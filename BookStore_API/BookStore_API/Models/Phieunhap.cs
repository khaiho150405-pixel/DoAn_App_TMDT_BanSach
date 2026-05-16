using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Phieunhap
{
    public int Mapn { get; set; }

    public int Manv { get; set; }

    public DateTime Ngaynhap { get; set; }

    public decimal Tongtien { get; set; }

    public string? Ghichu { get; set; }

    public virtual ICollection<Chitietphieunhap> Chitietphieunhaps { get; set; } = new List<Chitietphieunhap>();

    public virtual Nhanvien ManvNavigation { get; set; } = null!;
}

using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Hoidap
{
    public int Mahoidap { get; set; }

    public int Makh { get; set; }

    public string Cauhoi { get; set; } = null!;

    public string? Traloi { get; set; }

    public int? Manv { get; set; }

    public DateTime? Thoigianhoi { get; set; }

    public DateTime? Thoigiantraloi { get; set; }

    public string? Trangthai { get; set; }

    public virtual Khachhang MakhNavigation { get; set; } = null!;

    public virtual Nhanvien? ManvNavigation { get; set; }
}

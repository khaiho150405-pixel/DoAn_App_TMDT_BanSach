using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Danhgiasach
{
    public int Madanhgia { get; set; }

    public int Masach { get; set; }

    public int Makh { get; set; }

    public int? Diem { get; set; }

    public string? Nhanxet { get; set; }

    public DateTime? Thoigian { get; set; }

    public virtual Khachhang MakhNavigation { get; set; } = null!;

    public virtual Sach MasachNavigation { get; set; } = null!;
}

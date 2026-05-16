using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Chitietdonhang
{
    public int Madh { get; set; }

    public int Masach { get; set; }

    public int Soluong { get; set; }

    public decimal Dongia { get; set; }

    public decimal? Thanhtien { get; set; }

    public virtual Donhang MadhNavigation { get; set; } = null!;

    public virtual Sach MasachNavigation { get; set; } = null!;
}

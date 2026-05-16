using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Chitietgiohang
{
    public int Magiohang { get; set; }

    public int Masach { get; set; }

    public int Soluong { get; set; }

    public virtual Giohang MagiohangNavigation { get; set; } = null!;

    public virtual Sach MasachNavigation { get; set; } = null!;
}

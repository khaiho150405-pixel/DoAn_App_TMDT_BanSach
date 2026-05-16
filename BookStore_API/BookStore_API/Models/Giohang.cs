using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Giohang
{
    public int Magiohang { get; set; }

    public int Makh { get; set; }

    public DateTime? Ngaycapnhat { get; set; }

    public virtual ICollection<Chitietgiohang> Chitietgiohangs { get; set; } = new List<Chitietgiohang>();

    public virtual Khachhang MakhNavigation { get; set; } = null!;
}

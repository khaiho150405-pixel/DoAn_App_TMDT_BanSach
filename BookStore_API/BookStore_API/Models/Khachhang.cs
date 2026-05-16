using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Khachhang
{
    public int Makh { get; set; }

    public int Mataikhoan { get; set; }

    public string Hovaten { get; set; } = null!;

    public string? Gioitinh { get; set; }

    public DateOnly? Ngaysinh { get; set; }

    public string? Sdt { get; set; }

    public string? Email { get; set; }

    public string? Diachimacdinh { get; set; }

    public virtual ICollection<Danhgiasach> Danhgiasaches { get; set; } = new List<Danhgiasach>();

    public virtual ICollection<Donhang> Donhangs { get; set; } = new List<Donhang>();

    public virtual Giohang? Giohang { get; set; }

    public virtual ICollection<Hoidap> Hoidaps { get; set; } = new List<Hoidap>();

    public virtual Taikhoan MataikhoanNavigation { get; set; } = null!;
}

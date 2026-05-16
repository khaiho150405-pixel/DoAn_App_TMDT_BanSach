using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Nhanvien
{
    public int Manv { get; set; }

    public int Mataikhoan { get; set; }

    public string Hovaten { get; set; } = null!;

    public string? Gioitinh { get; set; }

    public DateOnly? Ngaysinh { get; set; }

    public string? Sdt { get; set; }

    public string? Email { get; set; }

    public string? Chucvu { get; set; }

    public virtual ICollection<Donhang> Donhangs { get; set; } = new List<Donhang>();

    public virtual ICollection<Hoidap> Hoidaps { get; set; } = new List<Hoidap>();

    public virtual Taikhoan MataikhoanNavigation { get; set; } = null!;

    public virtual ICollection<Phieunhap> Phieunhaps { get; set; } = new List<Phieunhap>();
}

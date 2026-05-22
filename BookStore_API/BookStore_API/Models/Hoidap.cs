using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Hoidap
{
    public int Mahoidap { get; set; }

    public int Makh { get; set; }

    public string Tieude { get; set; } = null!;

    public string Noidung { get; set; } = null!;

    public string? Loaihotro { get; set; }

    public string? Trangthai { get; set; }

    public DateTime? Thoigiantao { get; set; }

    public DateTime? Capnhatcuoi { get; set; }

    public int? Manvphutrach { get; set; }

    public virtual Khachhang MakhNavigation { get; set; } = null!;

    public virtual Nhanvien? ManvphutrachNavigation { get; set; }

    public virtual ICollection<Tinnhanhotro> Tinnhanhotros { get; set; } = new List<Tinnhanhotro>();
}

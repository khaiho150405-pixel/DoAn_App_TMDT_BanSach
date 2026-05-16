using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Khuyenmai
{
    public int Makm { get; set; }

    public string Tenkm { get; set; } = null!;

    public string? Mota { get; set; }

    public int Phantramgiam { get; set; }

    public DateTime Ngaybatdau { get; set; }

    public DateTime Ngayketthuc { get; set; }

    public string? Trangthai { get; set; }

    public virtual ICollection<Sach> Saches { get; set; } = new List<Sach>();
}

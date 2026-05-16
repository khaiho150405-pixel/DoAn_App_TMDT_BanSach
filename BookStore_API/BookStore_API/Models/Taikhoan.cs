using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Taikhoan
{
    public int Mataikhoan { get; set; }
    public string Tendangnhap { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string Matkhau { get; set; } = null!;

    public string? Trangthai { get; set; }

    public int Maquyen { get; set; }

    public virtual Khachhang? Khachhang { get; set; }

    public virtual Phanquyen MaquyenNavigation { get; set; } = null!;

    public virtual Nhanvien? Nhanvien { get; set; }
}

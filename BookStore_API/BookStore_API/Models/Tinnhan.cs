using System;

namespace BookStore_API.Models;

public partial class Tinnhan
{
    public int Matinnhan { get; set; }

    public int Mahoidap { get; set; }

    public string Nguoigui { get; set; } = null!;

    public int? Makh { get; set; }

    public int? Manv { get; set; }

    public string Noidung { get; set; } = null!;

    public DateTime? Thoigian { get; set; }

    public virtual Hoidap MahoidapNavigation { get; set; } = null!;

    public virtual Khachhang? MakhNavigation { get; set; }

    public virtual Nhanvien? ManvNavigation { get; set; }
}

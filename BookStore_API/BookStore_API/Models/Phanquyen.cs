using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Phanquyen
{
    public int Maquyen { get; set; }

    public string Tenquyen { get; set; } = null!;

    public virtual ICollection<Taikhoan> Taikhoans { get; set; } = new List<Taikhoan>();
}

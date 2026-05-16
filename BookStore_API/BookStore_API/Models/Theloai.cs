using System;
using System.Collections.Generic;

namespace BookStore_API.Models;

public partial class Theloai
{
    public int Matheloai { get; set; }

    public string Tentheloai { get; set; } = null!;

    public virtual ICollection<Sach> Saches { get; set; } = new List<Sach>();
}

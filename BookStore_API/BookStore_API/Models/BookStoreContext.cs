using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace BookStore_API.Models;

public partial class BookStoreContext : DbContext
{
    public BookStoreContext()
    {
    }

    public BookStoreContext(DbContextOptions<BookStoreContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Chitietdonhang> Chitietdonhangs { get; set; }

    public virtual DbSet<Chitietgiohang> Chitietgiohangs { get; set; }

    public virtual DbSet<Chitietphieunhap> Chitietphieunhaps { get; set; }

    public virtual DbSet<Danhgiasach> Danhgiasaches { get; set; }

    public virtual DbSet<Donhang> Donhangs { get; set; }

    public virtual DbSet<Giohang> Giohangs { get; set; }

    public virtual DbSet<Hoidap> Hoidaps { get; set; }

    public virtual DbSet<Khachhang> Khachhangs { get; set; }

    public virtual DbSet<Khuyenmai> Khuyenmais { get; set; }

    public virtual DbSet<Nhanvien> Nhanviens { get; set; }

    public virtual DbSet<Nhaxuatban> Nhaxuatbans { get; set; }

    public virtual DbSet<Phanquyen> Phanquyens { get; set; }

    public virtual DbSet<Phieunhap> Phieunhaps { get; set; }

    public virtual DbSet<Sach> Saches { get; set; }

    public virtual DbSet<Tacgium> Tacgia { get; set; }

    public virtual DbSet<Taikhoan> Taikhoans { get; set; }

    public virtual DbSet<Theloai> Theloais { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Chitietdonhang>(entity =>
        {
            entity.HasKey(e => new { e.Madh, e.Masach }).HasName("PK_CTDH");

            entity.ToTable("CHITIETDONHANG", tb =>
                {
                    tb.HasTrigger("TG_CAPNHATTONGTIEN_DONHANG");
                    tb.HasTrigger("TG_TRUTONKHO_DONHANG");
                });

            entity.Property(e => e.Madh).HasColumnName("MADH");
            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Dongia)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("DONGIA");
            entity.Property(e => e.Soluong).HasColumnName("SOLUONG");
            entity.Property(e => e.Thanhtien)
                .HasComputedColumnSql("([SOLUONG]*[DONGIA])", true)
                .HasColumnType("decimal(23, 2)")
                .HasColumnName("THANHTIEN");

            entity.HasOne(d => d.MadhNavigation).WithMany(p => p.Chitietdonhangs)
                .HasForeignKey(d => d.Madh)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTDH_DH");

            entity.HasOne(d => d.MasachNavigation).WithMany(p => p.Chitietdonhangs)
                .HasForeignKey(d => d.Masach)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTDH_SACH");
        });

        modelBuilder.Entity<Chitietgiohang>(entity =>
        {
            entity.HasKey(e => new { e.Magiohang, e.Masach }).HasName("PK_CTGH");

            entity.ToTable("CHITIETGIOHANG");

            entity.Property(e => e.Magiohang).HasColumnName("MAGIOHANG");
            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Soluong)
                .HasDefaultValue(1)
                .HasColumnName("SOLUONG");

            entity.HasOne(d => d.MagiohangNavigation).WithMany(p => p.Chitietgiohangs)
                .HasForeignKey(d => d.Magiohang)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTGH_GH");

            entity.HasOne(d => d.MasachNavigation).WithMany(p => p.Chitietgiohangs)
                .HasForeignKey(d => d.Masach)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTGH_SACH");
        });

        modelBuilder.Entity<Chitietphieunhap>(entity =>
        {
            entity.HasKey(e => new { e.Mapn, e.Masach }).HasName("PK_CTPN");

            entity.ToTable("CHITIETPHIEUNHAP", tb => tb.HasTrigger("TG_CAPNHATSLTON_NHAPSACH"));

            entity.Property(e => e.Mapn).HasColumnName("MAPN");
            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Gianhap)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("GIANHAP");
            entity.Property(e => e.Soluong).HasColumnName("SOLUONG");
            entity.Property(e => e.Thanhtien)
                .HasComputedColumnSql("([SOLUONG]*[GIANHAP])", true)
                .HasColumnType("decimal(23, 2)")
                .HasColumnName("THANHTIEN");

            entity.HasOne(d => d.MapnNavigation).WithMany(p => p.Chitietphieunhaps)
                .HasForeignKey(d => d.Mapn)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTPN_PN");

            entity.HasOne(d => d.MasachNavigation).WithMany(p => p.Chitietphieunhaps)
                .HasForeignKey(d => d.Masach)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CTPN_SACH");
        });

        modelBuilder.Entity<Danhgiasach>(entity =>
        {
            entity.HasKey(e => e.Madanhgia).HasName("PK__DANHGIAS__8597D60ADA17501E");

            entity.ToTable("DANHGIASACH");

            entity.Property(e => e.Madanhgia).HasColumnName("MADANHGIA");
            entity.Property(e => e.Diem).HasColumnName("DIEM");
            entity.Property(e => e.Makh).HasColumnName("MAKH");
            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Nhanxet).HasColumnName("NHANXET");
            entity.Property(e => e.Thoigian)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("THOIGIAN");

            entity.HasOne(d => d.MakhNavigation).WithMany(p => p.Danhgiasaches)
                .HasForeignKey(d => d.Makh)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DGS_KH");

            entity.HasOne(d => d.MasachNavigation).WithMany(p => p.Danhgiasaches)
                .HasForeignKey(d => d.Masach)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DGS_SACH");
        });

        modelBuilder.Entity<Donhang>(entity =>
        {
            entity.HasKey(e => e.Madh).HasName("PK__DONHANG__603F0047028EE739");

            entity.ToTable("DONHANG", tb => tb.HasTrigger("TG_HOANLAITONKHO_HUYDON"));

            entity.Property(e => e.Madh).HasColumnName("MADH");
            entity.Property(e => e.Diachigiao)
                .HasMaxLength(255)
                .HasColumnName("DIACHIGIAO");
            entity.Property(e => e.Ghichu).HasColumnName("GHICHU");
            entity.Property(e => e.Makh).HasColumnName("MAKH");
            entity.Property(e => e.Manv).HasColumnName("MANV");
            entity.Property(e => e.Ngaydat)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("NGAYDAT");
            entity.Property(e => e.Phuongthucthanhtoan)
                .HasMaxLength(50)
                .HasDefaultValue("COD")
                .HasColumnName("PHUONGTHUCTHANHTOAN");
            entity.Property(e => e.Sdtnhan)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("SDTNHAN");
            entity.Property(e => e.Tennguoinhan)
                .HasMaxLength(100)
                .HasColumnName("TENNGUOINHAN");
            entity.Property(e => e.Tongtien)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("TONGTIEN");
            entity.Property(e => e.Trangthaidonhang)
                .HasMaxLength(50)
                .HasDefaultValue("Chờ xác nhận")
                .HasColumnName("TRANGTHAIDONHANG");
            entity.Property(e => e.Trangthaithanhtoan)
                .HasMaxLength(50)
                .HasDefaultValue("Chưa thanh toán")
                .HasColumnName("TRANGTHAITHANHTOAN");

            entity.HasOne(d => d.MakhNavigation).WithMany(p => p.Donhangs)
                .HasForeignKey(d => d.Makh)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DH_KH");

            entity.HasOne(d => d.ManvNavigation).WithMany(p => p.Donhangs)
                .HasForeignKey(d => d.Manv)
                .HasConstraintName("FK_DH_NV");
        });

        modelBuilder.Entity<Giohang>(entity =>
        {
            entity.HasKey(e => e.Magiohang).HasName("PK__GIOHANG__559F5534CC55F8CB");

            entity.ToTable("GIOHANG");

            entity.HasIndex(e => e.Makh, "UQ__GIOHANG__603F592DFCCAE844").IsUnique();

            entity.Property(e => e.Magiohang).HasColumnName("MAGIOHANG");
            entity.Property(e => e.Makh).HasColumnName("MAKH");
            entity.Property(e => e.Ngaycapnhat)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("NGAYCAPNHAT");

            entity.HasOne(d => d.MakhNavigation).WithOne(p => p.Giohang)
                .HasForeignKey<Giohang>(d => d.Makh)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_GIOHANG_KH");
        });

        modelBuilder.Entity<Hoidap>(entity =>
        {
            entity.HasKey(e => e.Mahoidap).HasName("PK__HOIDAP__EE5B5C80A7F3BA51");

            entity.ToTable("HOIDAP");

            entity.Property(e => e.Mahoidap).HasColumnName("MAHOIDAP");
            entity.Property(e => e.Cauhoi).HasColumnName("CAUHOI");
            entity.Property(e => e.Makh).HasColumnName("MAKH");
            entity.Property(e => e.Manv).HasColumnName("MANV");
            entity.Property(e => e.Thoigianhoi)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("THOIGIANHOI");
            entity.Property(e => e.Thoigiantraloi)
                .HasColumnType("datetime")
                .HasColumnName("THOIGIANTRALOI");
            entity.Property(e => e.Traloi).HasColumnName("TRALOI");
            entity.Property(e => e.Trangthai)
                .HasMaxLength(50)
                .HasDefaultValue("Chờ trả lời")
                .HasColumnName("TRANGTHAI");

            entity.HasOne(d => d.MakhNavigation).WithMany(p => p.Hoidaps)
                .HasForeignKey(d => d.Makh)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_HOIDAP_KH");

            entity.HasOne(d => d.ManvNavigation).WithMany(p => p.Hoidaps)
                .HasForeignKey(d => d.Manv)
                .HasConstraintName("FK_HOIDAP_NV");
        });

        modelBuilder.Entity<Khachhang>(entity =>
        {
            entity.HasKey(e => e.Makh).HasName("PK__KHACHHAN__603F592C83D735C5");

            entity.ToTable("KHACHHANG", tb => tb.HasTrigger("TG_TAOGIOHANG_KH"));

            entity.HasIndex(e => e.Email, "UQ__KHACHHAN__161CF7247A2C10B1").IsUnique();

            entity.HasIndex(e => e.Mataikhoan, "UQ__KHACHHAN__2ED8B516F1A8CED2").IsUnique();

            entity.Property(e => e.Makh).HasColumnName("MAKH");
            entity.Property(e => e.Diachimacdinh)
                .HasMaxLength(255)
                .HasColumnName("DIACHIMACDINH");
            entity.Property(e => e.Email)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("EMAIL");
            entity.Property(e => e.Gioitinh)
                .HasMaxLength(5)
                .HasColumnName("GIOITINH");
            entity.Property(e => e.Hovaten)
                .HasMaxLength(100)
                .HasColumnName("HOVATEN");
            entity.Property(e => e.Mataikhoan).HasColumnName("MATAIKHOAN");
            entity.Property(e => e.Ngaysinh).HasColumnName("NGAYSINH");
            entity.Property(e => e.Sdt)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("SDT");

            entity.HasOne(d => d.MataikhoanNavigation).WithOne(p => p.Khachhang)
                .HasForeignKey<Khachhang>(d => d.Mataikhoan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_KHACHHANG_TAIKHOAN");
        });

        modelBuilder.Entity<Khuyenmai>(entity =>
        {
            entity.HasKey(e => e.Makm).HasName("PK__KHUYENMA__603F592B9CC2C66D");

            entity.ToTable("KHUYENMAI");

            entity.Property(e => e.Makm).HasColumnName("MAKM");
            entity.Property(e => e.Mota).HasColumnName("MOTA");
            entity.Property(e => e.Ngaybatdau)
                .HasColumnType("datetime")
                .HasColumnName("NGAYBATDAU");
            entity.Property(e => e.Ngayketthuc)
                .HasColumnType("datetime")
                .HasColumnName("NGAYKETTHUC");
            entity.Property(e => e.Phantramgiam).HasColumnName("PHANTRAMGIAM");
            entity.Property(e => e.Tenkm)
                .HasMaxLength(150)
                .HasColumnName("TENKM");
            entity.Property(e => e.Trangthai)
                .HasMaxLength(50)
                .HasDefaultValue("Đang diễn ra")
                .HasColumnName("TRANGTHAI");
        });

        modelBuilder.Entity<Nhanvien>(entity =>
        {
            entity.HasKey(e => e.Manv).HasName("PK__NHANVIEN__603F51142787E869");

            entity.ToTable("NHANVIEN");

            entity.HasIndex(e => e.Email, "UQ__NHANVIEN__161CF724C3D495A2").IsUnique();

            entity.HasIndex(e => e.Mataikhoan, "UQ__NHANVIEN__2ED8B51636BD3E5C").IsUnique();

            entity.Property(e => e.Manv).HasColumnName("MANV");
            entity.Property(e => e.Chucvu)
                .HasMaxLength(50)
                .HasColumnName("CHUCVU");
            entity.Property(e => e.Email)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("EMAIL");
            entity.Property(e => e.Gioitinh)
                .HasMaxLength(5)
                .HasColumnName("GIOITINH");
            entity.Property(e => e.Hovaten)
                .HasMaxLength(100)
                .HasColumnName("HOVATEN");
            entity.Property(e => e.Mataikhoan).HasColumnName("MATAIKHOAN");
            entity.Property(e => e.Ngaysinh).HasColumnName("NGAYSINH");
            entity.Property(e => e.Sdt)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("SDT");

            entity.HasOne(d => d.MataikhoanNavigation).WithOne(p => p.Nhanvien)
                .HasForeignKey<Nhanvien>(d => d.Mataikhoan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_NHANVIEN_TAIKHOAN");
        });

        modelBuilder.Entity<Nhaxuatban>(entity =>
        {
            entity.HasKey(e => e.Manxb).HasName("PK__NHAXUATB__7ABD9EF24B70B4E7");

            entity.ToTable("NHAXUATBAN");

            entity.Property(e => e.Manxb).HasColumnName("MANXB");
            entity.Property(e => e.Diachi)
                .HasMaxLength(200)
                .HasColumnName("DIACHI");
            entity.Property(e => e.Sdt)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("SDT");
            entity.Property(e => e.Tennxb)
                .HasMaxLength(100)
                .HasColumnName("TENNXB");
        });

        modelBuilder.Entity<Phanquyen>(entity =>
        {
            entity.HasKey(e => e.Maquyen).HasName("PK__PHANQUYE__F2A840CF3553F27C");

            entity.ToTable("PHANQUYEN");

            entity.HasIndex(e => e.Tenquyen, "UQ__PHANQUYE__3B380E4F47413A5E").IsUnique();

            entity.Property(e => e.Maquyen).HasColumnName("MAQUYEN");
            entity.Property(e => e.Tenquyen)
                .HasMaxLength(50)
                .HasColumnName("TENQUYEN");
        });

        modelBuilder.Entity<Phieunhap>(entity =>
        {
            entity.HasKey(e => e.Mapn).HasName("PK__PHIEUNHA__603F61CEC4654E58");

            entity.ToTable("PHIEUNHAP");

            entity.Property(e => e.Mapn).HasColumnName("MAPN");
            entity.Property(e => e.Ghichu).HasColumnName("GHICHU");
            entity.Property(e => e.Manv).HasColumnName("MANV");
            entity.Property(e => e.Ngaynhap)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("NGAYNHAP");
            entity.Property(e => e.Tongtien)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("TONGTIEN");

            entity.HasOne(d => d.ManvNavigation).WithMany(p => p.Phieunhaps)
                .HasForeignKey(d => d.Manv)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PN_NV");
        });

        modelBuilder.Entity<Sach>(entity =>
        {
            entity.HasKey(e => e.Masach).HasName("PK__SACH__3FC48E4CFDB0C055");

            entity.ToTable("SACH");

            entity.Property(e => e.Masach).HasColumnName("MASACH");
            entity.Property(e => e.Giaban)
                .HasColumnType("decimal(12, 2)")
                .HasColumnName("GIABAN");
            entity.Property(e => e.Hinhanh)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("HINHANH");
            entity.Property(e => e.Makm).HasColumnName("MAKM");
            entity.Property(e => e.Manxb).HasColumnName("MANXB");
            entity.Property(e => e.Matg).HasColumnName("MATG");
            entity.Property(e => e.Matheloai).HasColumnName("MATHELOAI");
            entity.Property(e => e.Mota).HasColumnName("MOTA");
            entity.Property(e => e.Soluongton).HasColumnName("SOLUONGTON");
            entity.Property(e => e.Tensach)
                .HasMaxLength(150)
                .HasColumnName("TENSACH");
            entity.Property(e => e.Trangthai)
                .HasMaxLength(30)
                .HasDefaultValue("Có sẵn")
                .HasColumnName("TRANGTHAI");

            entity.HasOne(d => d.MakmNavigation).WithMany(p => p.Saches)
                .HasForeignKey(d => d.Makm)
                .HasConstraintName("FK_SACH_KM");

            entity.HasOne(d => d.ManxbNavigation).WithMany(p => p.Saches)
                .HasForeignKey(d => d.Manxb)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SACH_NXB");

            entity.HasOne(d => d.MatgNavigation).WithMany(p => p.Saches)
                .HasForeignKey(d => d.Matg)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SACH_TACGIA");

            entity.HasOne(d => d.MatheloaiNavigation).WithMany(p => p.Saches)
                .HasForeignKey(d => d.Matheloai)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SACH_THELOAI");
        });

        modelBuilder.Entity<Tacgium>(entity =>
        {
            entity.HasKey(e => e.Matg).HasName("PK__TACGIA__6023721A9E624150");

            entity.ToTable("TACGIA");

            entity.Property(e => e.Matg).HasColumnName("MATG");
            entity.Property(e => e.Mota).HasColumnName("MOTA");
            entity.Property(e => e.Quoctich)
                .HasMaxLength(50)
                .HasColumnName("QUOCTICH");
            entity.Property(e => e.Tentg)
                .HasMaxLength(100)
                .HasColumnName("TENTG");
        });

        modelBuilder.Entity<Taikhoan>(entity =>
        {
            entity.HasKey(e => e.Mataikhoan).HasName("PK__TAIKHOAN__2ED8B51799CF14A9");

            entity.ToTable("TAIKHOAN");

            entity.HasIndex(e => e.Email, "UQ__TAIKHOAN__161CF724A624B85F").IsUnique();

            entity.HasIndex(e => e.Tendangnhap, "UQ__TAIKHOAN__6C836FE5958A5281").IsUnique();

            entity.Property(e => e.Mataikhoan).HasColumnName("MATAIKHOAN");
            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("EMAIL");
            entity.Property(e => e.Maquyen).HasColumnName("MAQUYEN");
            entity.Property(e => e.Matkhau)
                .HasMaxLength(255)
                .HasColumnName("MATKHAU");
            entity.Property(e => e.Tendangnhap)
                .HasMaxLength(50)
                .HasColumnName("TENDANGNHAP");
            entity.Property(e => e.Trangthai)
                .HasMaxLength(20)
                .HasDefaultValue("Hoạt động")
                .HasColumnName("TRANGTHAI");

            entity.HasOne(d => d.MaquyenNavigation).WithMany(p => p.Taikhoans)
                .HasForeignKey(d => d.Maquyen)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_TAIKHOAN_PHANQUYEN");
        });

        modelBuilder.Entity<Theloai>(entity =>
        {
            entity.HasKey(e => e.Matheloai).HasName("PK__THELOAI__AC8D7C2BE4856F57");

            entity.ToTable("THELOAI");

            entity.HasIndex(e => e.Tentheloai, "UQ__THELOAI__6A33C9F1551FD38E").IsUnique();

            entity.Property(e => e.Matheloai).HasColumnName("MATHELOAI");
            entity.Property(e => e.Tentheloai)
                .HasMaxLength(50)
                .HasColumnName("TENTHELOAI");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}

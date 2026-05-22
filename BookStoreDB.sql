CREATE DATABASE BookStoreDB;
GO

USE BookStoreDB;
GO

-- =========================================================
-- 1. BẢNG PHÂN QUYỀN & TÀI KHOẢN
-- =========================================================
CREATE TABLE PHANQUYEN (
    MAQUYEN INT IDENTITY(1,1) PRIMARY KEY,
    TENQUYEN NVARCHAR(50) UNIQUE NOT NULL  
    -- 1: Admin | 2: NV Bán Hàng | 3: NV Kho | 4: Khách Hàng
);
GO

CREATE TABLE TAIKHOAN (
    MATAIKHOAN INT IDENTITY(1,1) PRIMARY KEY,
    TENDANGNHAP NVARCHAR(50) UNIQUE NOT NULL,
	EMAIL VARCHAR(100) UNIQUE NOT NULL,
    MATKHAU NVARCHAR(255) NOT NULL, 
    TRANGTHAI NVARCHAR(20) DEFAULT N'Hoạt động' CHECK (TRANGTHAI IN (N'Hoạt động', N'Ngừng hoạt động')),
    MAQUYEN INT NOT NULL,

    CONSTRAINT FK_TAIKHOAN_PHANQUYEN FOREIGN KEY (MAQUYEN) REFERENCES PHANQUYEN(MAQUYEN)
);
GO

-- =========================================================
-- 2. BẢNG NGƯỜI DÙNG (NHÂN VIÊN & KHÁCH HÀNG)
-- =========================================================
CREATE TABLE NHANVIEN (
    MANV INT IDENTITY(1,1) PRIMARY KEY,
    MATAIKHOAN INT UNIQUE NOT NULL,
    HOVATEN NVARCHAR(100) NOT NULL,
    GIOITINH NVARCHAR(5),
    NGAYSINH DATE,
    SDT VARCHAR(15),
    EMAIL VARCHAR(50) UNIQUE,
    CHUCVU NVARCHAR(50), 

    CONSTRAINT FK_NHANVIEN_TAIKHOAN FOREIGN KEY (MATAIKHOAN) REFERENCES TAIKHOAN(MATAIKHOAN)
);
GO

CREATE TABLE KHACHHANG (
    MAKH INT IDENTITY(1,1) PRIMARY KEY,
    MATAIKHOAN INT UNIQUE NOT NULL,
    HOVATEN NVARCHAR(100) NOT NULL,
    GIOITINH NVARCHAR(5),
    NGAYSINH DATE,
    SDT VARCHAR(15),
    EMAIL VARCHAR(50) UNIQUE,
    DIACHIMACDINH NVARCHAR(255),

    CONSTRAINT FK_KHACHHANG_TAIKHOAN FOREIGN KEY (MATAIKHOAN) REFERENCES TAIKHOAN(MATAIKHOAN)
);
GO

-- =========================================================
-- 3. BẢNG TÁC GIẢ, NHÀ XUẤT BẢN & KHUYẾN MÃI
-- =========================================================
CREATE TABLE TACGIA (
    MATG INT IDENTITY(1,1) PRIMARY KEY,
    TENTG NVARCHAR(100) NOT NULL,
    QUOCTICH NVARCHAR(50) NULL,
    MOTA NVARCHAR(MAX) NULL
);
GO

CREATE TABLE NHAXUATBAN (
    MANXB INT IDENTITY(1,1) PRIMARY KEY,
    TENNXB NVARCHAR(100) NOT NULL,
    DIACHI NVARCHAR(200),
    SDT VARCHAR(15) NULL
);
GO

CREATE TABLE THELOAI (
    MATHELOAI INT IDENTITY(1,1) PRIMARY KEY,
    TENTHELOAI NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE KHUYENMAI (
    MAKM INT IDENTITY(1,1) PRIMARY KEY,
    TENKM NVARCHAR(150) NOT NULL,
    MOTA NVARCHAR(MAX),
    PHANTRAMGIAM INT NOT NULL CHECK (PHANTRAMGIAM >= 0 AND PHANTRAMGIAM <= 100), 
    NGAYBATDAU DATETIME NOT NULL,
    NGAYKETTHUC DATETIME NOT NULL,
    TRANGTHAI NVARCHAR(50) DEFAULT N'Đang diễn ra', 

    CONSTRAINT CK_KM_NGAY CHECK (NGAYBATDAU <= NGAYKETTHUC)
);
GO

-- =========================================================
-- 4. BẢNG SÁCH
-- =========================================================
CREATE TABLE SACH (
    MASACH INT IDENTITY(1,1) PRIMARY KEY,
    TENSACH NVARCHAR(150) NOT NULL,
    MATG INT NOT NULL,
    MANXB INT NOT NULL,
	MATHELOAI INT NOT NULL,
    MAKM INT NULL,
    HINHANH VARCHAR(255),
    MOTA NVARCHAR(MAX),
    GIABAN DECIMAL(12,2) NOT NULL CHECK (GIABAN >= 0),
    SOLUONGTON INT NOT NULL DEFAULT 0 CHECK (SOLUONGTON >= 0),
    TRANGTHAI NVARCHAR(30) NOT NULL DEFAULT N'Có sẵn' CHECK (TRANGTHAI IN (N'Có sẵn', N'Đã hết')),

    CONSTRAINT FK_SACH_TACGIA FOREIGN KEY (MATG) REFERENCES TACGIA(MATG),
    CONSTRAINT FK_SACH_NXB FOREIGN KEY (MANXB) REFERENCES NHAXUATBAN(MANXB),
	CONSTRAINT FK_SACH_THELOAI FOREIGN KEY (MATHELOAI) REFERENCES THELOAI(MATHELOAI),
    CONSTRAINT FK_SACH_KM FOREIGN KEY (MAKM) REFERENCES KHUYENMAI(MAKM)
);
GO

-- =========================================================
-- 5. BẢNG GIỎ HÀNG
-- =========================================================
CREATE TABLE GIOHANG (
    MAGIOHANG INT IDENTITY(1,1) PRIMARY KEY,
    MAKH INT UNIQUE NOT NULL,
    NGAYCAPNHAT DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_GIOHANG_KH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH)
);
GO

CREATE TABLE CHITIETGIOHANG (
    MAGIOHANG INT NOT NULL,
    MASACH INT NOT NULL,
    SOLUONG INT NOT NULL DEFAULT 1 CHECK (SOLUONG > 0),

    CONSTRAINT PK_CTGH PRIMARY KEY (MAGIOHANG, MASACH),
    CONSTRAINT FK_CTGH_GH FOREIGN KEY (MAGIOHANG) REFERENCES GIOHANG(MAGIOHANG),
    CONSTRAINT FK_CTGH_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH)
);
GO

-- =========================================================
-- 6. BẢNG ĐƠN HÀNG (ORDER)
-- =========================================================
CREATE TABLE DONHANG (
    MADH INT IDENTITY(1,1) PRIMARY KEY,
    MAKH INT NOT NULL,
    MANV INT NULL, 
    NGAYDAT DATETIME NOT NULL DEFAULT GETDATE(),
    TONGTIEN DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (TONGTIEN >= 0),
    TENNGUOINHAN NVARCHAR(100) NOT NULL,
    SDTNHAN VARCHAR(15) NOT NULL,
    DIACHIGIAO NVARCHAR(255) NOT NULL,
    PHUONGTHUCTHANHTOAN NVARCHAR(50) DEFAULT N'COD',
    TRANGTHAITHANHTOAN NVARCHAR(50) DEFAULT N'Chưa thanh toán',
    TRANGTHAIDONHANG NVARCHAR(50) DEFAULT N'Chờ xác nhận' CHECK (TRANGTHAIDONHANG IN (N'Chờ xác nhận', N'Đang chuẩn bị hàng', N'Đang giao', N'Hoàn thành', N'Đã hủy')),
    GHICHU NVARCHAR(MAX),

    CONSTRAINT FK_DH_KH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH),
    CONSTRAINT FK_DH_NV FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
);
GO

CREATE TABLE CHITIETDONHANG (
    MADH INT NOT NULL,
    MASACH INT NOT NULL,
    SOLUONG INT NOT NULL CHECK (SOLUONG > 0),
    DONGIA DECIMAL(12,2) NOT NULL CHECK (DONGIA >= 0), -- Giá khách chốt mua (Sau khi đã trừ khuyến mãi)
    THANHTIEN AS (SOLUONG * DONGIA) PERSISTED,

    CONSTRAINT PK_CTDH PRIMARY KEY (MADH, MASACH),
    CONSTRAINT FK_CTDH_DH FOREIGN KEY (MADH) REFERENCES DONHANG(MADH),
    CONSTRAINT FK_CTDH_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH)
);
GO

-- =========================================================
-- 7. BẢNG PHIẾU NHẬP (DÀNH CHO NHÂN VIÊN KHO)
-- =========================================================
CREATE TABLE PHIEUNHAP (
    MAPN INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    MANV INT NOT NULL, 
    NGAYNHAP DATETIME NOT NULL DEFAULT GETDATE(),
    TONGTIEN DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (TONGTIEN >= 0),
    GHICHU NVARCHAR(MAX),

    CONSTRAINT FK_PN_NV FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
);
GO

CREATE TABLE CHITIETPHIEUNHAP (
    MAPN INT NOT NULL,
    MASACH INT NOT NULL,
    SOLUONG INT NOT NULL CHECK (SOLUONG > 0),
    GIANHAP DECIMAL(12,2) NOT NULL CHECK (GIANHAP >= 0),
    THANHTIEN AS (SOLUONG * GIANHAP) PERSISTED,

    CONSTRAINT PK_CTPN PRIMARY KEY (MAPN, MASACH),
    CONSTRAINT FK_CTPN_PN FOREIGN KEY (MAPN) REFERENCES PHIEUNHAP(MAPN),
    CONSTRAINT FK_CTPN_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH)
);
GO

-- =========================================================
-- TẠO BẢNG HOIDAP
-- =========================================================
CREATE TABLE HOIDAP (
    MAHOIDAP INT IDENTITY(1,1) PRIMARY KEY,
    MAKH INT NOT NULL,
    CAUHOI NVARCHAR(MAX) NOT NULL,
    TRALOI NVARCHAR(MAX),
    MANV INT NULL, 
    THOIGIANHOI DATETIME DEFAULT GETDATE(),
    THOIGIANTRALOI DATETIME,
    TRANGTHAI NVARCHAR(50) DEFAULT N'Chờ trả lời',

    CONSTRAINT FK_HOIDAP_KH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH),
    CONSTRAINT FK_HOIDAP_NV FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
);
GO

CREATE TABLE TINNHAN (
    MATINNHAN INT IDENTITY(1,1) PRIMARY KEY,
    MAHOIDAP INT NOT NULL,
    NGUOIGUI NVARCHAR(20) NOT NULL,  -- 'KhachHang' hoặc 'NhanVien'
    MAKH INT NULL,
    MANV INT NULL,
    NOIDUNG NVARCHAR(MAX) NOT NULL,
    THOIGIAN DATETIME DEFAULT GETDATE(),
        
    CONSTRAINT FK_TINNHAN_HOIDAP FOREIGN KEY (MAHOIDAP) REFERENCES HOIDAP(MAHOIDAP),
    CONSTRAINT FK_TINNHAN_KH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH),
    CONSTRAINT FK_TINNHAN_NV FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
);
GO

CREATE TABLE DANHGIASACH (
    MADANHGIA INT IDENTITY(1,1) PRIMARY KEY,
    MASACH INT NOT NULL,
    MAKH INT NOT NULL,
    DIEM INT CHECK (DIEM >= 1 AND DIEM <= 5),
    NHANXET NVARCHAR(MAX),
    THOIGIAN DATETIME DEFAULT GETDATE(),
    PHANHOIDANHGIA NVARCHAR(MAX),

    CONSTRAINT FK_DGS_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH),
    CONSTRAINT FK_DGS_KH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH)
);
GO


-- =====================================================================================================================
-- ||                                               TRIGGERS CỐT LÕI                                                  ||
-- =====================================================================================================================

-- 1. CẬP NHẬT TỒN KHO VÀ TRẠNG THÁI KHI NHẬP SÁCH
GO
CREATE TRIGGER TG_CAPNHATSLTON_NHAPSACH
ON CHITIETPHIEUNHAP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE S
    SET S.SOLUONGTON = ISNULL(S.SOLUONGTON, 0) + ISNULL(I.SL_NHAP, 0) - ISNULL(D.SL_XOA, 0)
    FROM SACH S
    LEFT JOIN (SELECT MASACH, SUM(SOLUONG) AS SL_NHAP FROM inserted GROUP BY MASACH) I ON S.MASACH = I.MASACH
    LEFT JOIN (SELECT MASACH, SUM(SOLUONG) AS SL_XOA FROM deleted GROUP BY MASACH) D ON S.MASACH = D.MASACH
    WHERE S.MASACH IN (SELECT MASACH FROM inserted UNION SELECT MASACH FROM deleted);

    -- Tự động đổi trạng thái sách
    UPDATE SACH SET TRANGTHAI = CASE WHEN SOLUONGTON > 0 THEN N'Có sẵn' ELSE N'Đã hết' END
    WHERE MASACH IN (SELECT MASACH FROM inserted UNION SELECT MASACH FROM deleted);
END;
GO

-- 2. TRỪ TỒN KHO KHI ĐẶT HÀNG THÀNH CÔNG
GO
CREATE TRIGGER TG_TRUTONKHO_DONHANG
ON CHITIETDONHANG
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE S
    SET S.SOLUONGTON = S.SOLUONGTON - I.SOLUONG
    FROM SACH S JOIN inserted I ON S.MASACH = I.MASACH;

    -- Tự động đổi trạng thái sách
    UPDATE SACH SET TRANGTHAI = CASE WHEN SOLUONGTON > 0 THEN N'Có sẵn' ELSE N'Đã hết' END
    WHERE MASACH IN (SELECT MASACH FROM inserted);
END;
GO

-- 3. HOÀN LẠI TỒN KHO KHI HỦY ĐƠN HÀNG
GO
CREATE TRIGGER TG_HOANLAITONKHO_HUYDON
ON DONHANG
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(TRANGTHAIDONHANG)
    BEGIN
        UPDATE S
        SET S.SOLUONGTON = S.SOLUONGTON + CT.SOLUONG
        FROM SACH S
        JOIN CHITIETDONHANG CT ON S.MASACH = CT.MASACH
        JOIN inserted I ON CT.MADH = I.MADH
        JOIN deleted D ON I.MADH = D.MADH
        WHERE I.TRANGTHAIDONHANG = N'Đã hủy' AND D.TRANGTHAIDONHANG != N'Đã hủy';

        -- Tự động đổi trạng thái sách
        UPDATE S SET S.TRANGTHAI = CASE WHEN S.SOLUONGTON > 0 THEN N'Có sẵn' ELSE N'Đã hết' END
        FROM SACH S JOIN CHITIETDONHANG CT ON S.MASACH = CT.MASACH JOIN inserted I ON CT.MADH = I.MADH
        WHERE I.TRANGTHAIDONHANG = N'Đã hủy';
    END
END;
GO

-- 4. TÍNH TỔNG TIỀN ĐƠN HÀNG TỰ ĐỘNG
GO
CREATE TRIGGER TG_CAPNHATTONGTIEN_DONHANG
ON CHITIETDONHANG
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE DH 
    SET DH.TONGTIEN = ISNULL(T.TONG, 0)
    FROM DONHANG DH
    LEFT JOIN (SELECT MADH, SUM(THANHTIEN) AS TONG FROM CHITIETDONHANG GROUP BY MADH) T ON DH.MADH = T.MADH
    WHERE DH.MADH IN (SELECT MADH FROM inserted UNION SELECT MADH FROM deleted);
END;
GO

-- 5. TỰ ĐỘNG TẠO GIỎ HÀNG KHI KHÁCH HÀNG ĐĂNG KÝ
GO
CREATE TRIGGER TG_TAOGIOHANG_KH
ON KHACHHANG
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO GIOHANG (MAKH)
    SELECT MAKH FROM inserted;
END;
GO


-- =====================================================================================================================
-- ||                                          DỮ LIỆU MẪU CHUẨN ĐỂ TEST                                              ||
-- =====================================================================================================================




-- 1. DỮ LIỆU PHÂN QUYỀN (Nếu chưa có)
-- TRUNCATE TABLE để làm sạch dữ liệu cũ nếu cần (Cẩn thận khi dùng)
-- DELETE FROM TAIKHOAN; DELETE FROM PHANQUYEN; ...

INSERT INTO PHANQUYEN (TENQUYEN) VALUES (N'Admin'), (N'Bán Hàng'), (N'Kho'), (N'Khách Hàng');

-- 2. DỮ LIỆU TÀI KHOẢN (5 Tài khoản mẫu)
INSERT INTO TAIKHOAN (TENDANGNHAP, EMAIL, MATKHAU, MAQUYEN) VALUES 
(N'admin', 'admin@bookstore.com', N'123', 1),
(N'sale', 'sale@bookstore.com', N'123', 2),
(N'kho', 'kho@bookstore.com', N'123', 3),
(N'vi', 'vi@gmail.com', N'123', 4),
(N'khai', 'khai@gmail.com', N'123', 4);

-- 3. DỮ LIỆU NHÂN VIÊN
INSERT INTO NHANVIEN (MATAIKHOAN, HOVATEN, GIOITINH, SDT, EMAIL, CHUCVU) VALUES 
(2, N'Nguyễn Văn An', N'Nam', '0912345678', 'sale@bookstore.com', N'Trưởng ca bán hàng'),
(3, N'Lê Thị Bình', N'Nữ', '0987654321', 'kho@bookstore.com', N'Quản lý kho');

-- 4. DỮ LIỆU KHÁCH HÀNG
INSERT INTO KHACHHANG (MATAIKHOAN, HOVATEN, GIOITINH, SDT, EMAIL, DIACHIMACDINH) VALUES 
(4, N'Đỗ Trọng Vĩ', N'Nam', '0901112223', 'vi@gmail.com', N'123 Lê Trọng Tấn, Tân Phú, HCM'),
(5, N'Hồ Quang Khải', N'Nam', '0903334445', 'khai@gmail.com', N'456 Cộng Hòa, Tân Bình, HCM');

-- 5. THỂ LOẠI (9 Thể loại)
INSERT INTO THELOAI (TENTHELOAI) VALUES 
(N'Lập trình'), (N'Khoa học máy tính'), (N'Kỹ năng sống'), (N'Văn học'), (N'Manga'), (N'Kinh tế');
-- 6. TÁC GIẢ
INSERT INTO TACGIA (TENTG, QUOCTICH) VALUES 
(N'Robert C. Martin', 'USA'),   -- ID 1: IT/Lập trình
(N'Nguyễn Nhật Ánh', 'VN'),    -- ID 2: Văn học
(N'Dale Carnegie', 'USA'),      -- ID 3: Kỹ năng
(N'Fujiko F. Fujio', 'Japan'), -- ID 4: Manga
(N'Adam Freeman', 'UK'),       -- ID 5: IT/ASP.NET
(N'Aurélien Géron', 'France'),  -- ID 6: AI/Machine Learning
(N'Paulo Coelho', 'Brazil'),    -- ID 7: Văn học quốc tế
(N'Tony Buổi Sáng', 'VN'),      -- ID 8: Kỹ năng sống
(N'Robert Kiyosaki', 'USA');    -- ID 9: Kinh tế/Tài chính

-- 7. NHÀ XUẤT BẢN
INSERT INTO NHAXUATBAN (TENNXB, DIACHI) VALUES 
(N'NXB Trẻ', N'TP.HCM'), (N'NXB Kim Đồng', N'Hà Nội'), (N'NXB Tổng hợp', N'TP.HCM'), 
(N'O Reilly', 'USA'), (N'Pearson', 'UK');

-- 8. KHUYẾN MÃI
INSERT INTO KHUYENMAI (TENKM, PHANTRAMGIAM, NGAYBATDAU, NGAYKETTHUC) VALUES 
(N'Chào hè 2026', 10, '2026-05-01', '2026-06-30'),
(N'Black Friday IT', 25, '2026-11-20', '2026-11-30');

-- 3. CHÈN 30 CUỐN SÁCH VỚI MÃ KHUYẾN MÃI TƯƠNG ỨNG
INSERT INTO SACH (TENSACH, MATG, MANXB, MATHELOAI, MAKM, HINHANH, MOTA, GIABAN, SOLUONGTON) VALUES
-- =========================================================
-- Nhóm CNTT & AI (Áp dụng Black Friday IT - MAKM: 2)
-- =========================================================
(N'Clean Code', 1, 5, 1, 2, 'clean_code.jpg', N'Cuốn sách kinh điển về quy tắc viết mã sạch, giúp lập trình viên tạo ra mã nguồn dễ đọc và bảo trì.', 350000, 50),
(N'Clean Architecture', 1, 5, 1, 2, 'clean_architecture.jpg', N'Hướng dẫn chi tiết về cách thiết kế cấu trúc hệ thống phần mềm linh hoạt và độc lập với khung công tác.', 380000, 30),
(N'Pro ASP.NET Core MVC 6', 5, 5, 1, 2, 'aspnet_core.jpg', N'Tài liệu chuyên sâu hướng dẫn phát triển ứng dụng web hiện đại bằng kiến trúc MVC trên nền tảng .NET Core.', 550000, 25),
(N'The Clean Coder', 1, 5, 1, 2, 'clean_coder.jpg', N'Cẩm nang về thái độ sống, kỹ năng giao tiếp và đạo đức nghề nghiệp cần có của một lập trình viên chuyên nghiệp.', 320000, 45),
(N'Hands-On Machine Learning', 6, 4, 2, 2, 'machine_learning.jpg', N'Hướng dẫn thực hành xây dựng các hệ thống học máy thông minh sử dụng Scikit-Learn, Keras và TensorFlow.', 680000, 15),
(N'C# in Depth', 5, 5, 1, 2, 'csharp_depth.jpg', N'Phân tích sâu sắc các tính năng phức tạp của ngôn ngữ C#, giúp bạn làm chủ mọi ngóc ngách của .NET.', 480000, 20),
(N'Deep Learning with Python', 6, 4, 2, 2, 'deep_learning.jpg', N'Khám phá thế giới trí tuệ nhân tạo thông qua các ví dụ thực tế về mạng nơ-ron sử dụng thư viện Keras.', 590000, 10),

-- =========================================================
-- Nhóm Kỹ năng & Kinh tế (Áp dụng Chào hè 2026 - MAKM: 1)
-- =========================================================
(N'Đắc Nhân Tâm', 3, 1, 3, 1, 'dac_nhan_tam.jpg', N'Cuốn sách nổi tiếng nhất mọi thời đại về nghệ thuật giao tiếp, thu phục lòng người và tạo dựng mối quan hệ.', 95000, 100),
(N'Quẳng gánh lo đi và vui sống', 3, 1, 3, 1, 'quang_ganh_lo_di.jpg', N'Cung cấp các phương pháp cụ thể để loại bỏ thói quen lo lắng, tận hưởng cuộc sống bình an và hạnh phúc.', 88000, 120),
(N'Trên đường băng', 8, 1, 3, 1, 'tren_duong_bang.jpg', N'Tập hợp những bài chia sẻ đầy cảm hứng của Tony Buổi Sáng, thúc đẩy người trẻ rèn luyện kỹ năng và đạo đức.', 85000, 150),
(N'Cà phê cùng Tony', 8, 1, 3, 1, 'ca_phe_tony.jpg', N'Những câu chuyện hài hước nhưng sâu sắc về cách ứng xử, tư duy kinh doanh và thái độ sống tích cực.', 92000, 110),
(N'Cha giàu cha nghèo', 9, 3, 6, 1, 'rich_dad_poor_dad.jpg', N'Thay đổi hoàn toàn tư duy về tiền bạc và tài chính, giúp bạn hiểu rõ sự khác biệt giữa tài sản và tiêu sản.', 120000, 80),
(N'Dạy con làm giàu tập 2', 9, 3, 6, 1, 'day_con_lam_giau.jpg', N'Khám phá Kim tứ đồ để hiểu về 4 cách tạo ra thu nhập và lộ trình để đạt được tự do tài chính bền vững.', 115000, 60),
(N'7 Thói quen để thành đạt', 3, 3, 3, NULL, '7_habits.jpg', N'Xây dựng nền tảng tính cách thông qua 7 thói quen cốt lõi để đạt được thành công đột phá trong công việc và cuộc sống.', 160000, 40),

-- =========================================================
-- Nhóm Văn học (Áp dụng Chào hè 2026 - MAKM: 1 hoặc NULL)
-- =========================================================
(N'Mắt Biếc', 2, 1, 4, 1, 'mat_biec.jpg', N'Bản tình ca buồn về mối tình đơn phương của Ngạn dành cho Hà Lan, gắn liền với ngôi làng Đo Đo mộc mạc.', 110000, 90),
(N'Cho tôi xin một vé đi tuổi thơ', 2, 1, 4, 1, 've_di_tuoi_tho.jpg', N'Cuốn hồi ký trong trẻo đưa người đọc trở lại với thế giới tuổi thơ đầy nghịch ngợm và những suy nghĩ hồn nhiên.', 85000, 100),
(N'Nhà giả kim', 7, 3, 4, 1, 'nha_gia_kim.jpg', N'Câu chuyện ngụ ngôn đầy triết lý về hành trình theo đuổi ước mơ và lắng nghe tiếng gọi của trái tim.', 79000, 200),
(N'Tôi thấy hoa vàng trên cỏ xanh', 2, 1, 4, NULL, 'hoavang.jpg', N'Những kỷ niệm ngọt ngào xen lẫn cay đắng về tình anh em, tình bạn và những rung động đầu đời tuổi dậy thì.', 125000, 70),
(N'Cô gái đến từ hôm qua', 2, 1, 4, NULL, 'cogai.jpg', N'Câu chuyện tình học trò nhẹ nhàng, lãng mạn với những tình tiết bất ngờ giữa quá khứ và hiện tại.', 90000, 85),
(N'Kính vạn hoa tập 1', 2, 1, 4, NULL, 'kinhvanhoa.jpg', N'Bắt đầu những cuộc phiêu lưu ly kỳ, hài hước của bộ ba bạn thân Quý ròm, Tiểu Long và Hạnh cận.', 105000, 40),
(N'Bàn có năm chỗ ngồi', 2, 1, 4, NULL, 'bannanchongoi.jpg', N'Tác phẩm ca ngợi tình bạn thắm thiết và sự nỗ lực vươn lên trong học tập của nhóm bạn học sinh phổ thông.', 80000, 55),

-- =========================================================
-- Nhóm Manga (Áp dụng Chào hè 2026 - MAKM: 1 hoặc NULL)
-- =========================================================
(N'Doraemon Tập 1', 4, 2, 5, 1, 'doraemon_1.jpg', N'Khởi đầu hành trình vượt thời gian của chú mèo máy Doraemon đến giúp đỡ cậu bé Nobita hậu đậu.', 25000, 500),
(N'Doraemon Tập 2', 4, 2, 5, 1, 'doraemon_2.jpg', N'Nobita và những người bạn cùng khám phá vô vàn bảo bối thần kỳ trong chiếc túi không đáy.', 25000, 450),
(N'Doraemon Tập 3', 4, 2, 5, 1, 'doraemon_3.jpg', N'Những mẩu chuyện cảm động về lòng dũng cảm, sự chia sẻ và những bài học nhân văn sâu sắc.', 25000, 400),
(N'Doraemon Tập 4', 4, 2, 5, 1, 'doraemon_4.jpg', N'Các cuộc phiêu lưu kỳ thú từ lòng đất lên đến bầu trời xanh của nhóm bạn tiểu học.', 25000, 350),
(N'Doraemon Tập 5', 4, 2, 5, 1, 'doraemon_5.jpg', N'Doraemon sử dụng bảo bối để giải quyết những rắc rối dở khóc dở cười do Nobita gây ra.', 25000, 300),
(N'Doraemon Tập 10', 4, 2, 5, 1, 'doraemon_10.jpg', N'Tuyển tập những chương truyện đặc sắc nhất kỷ niệm chặng đường dài gắn bó của chú mèo máy.', 25000, 200),
(N'Conan Tập 100', 4, 2, 5, NULL, 'conan_100.jpg', N'Cột mốc lịch sử với những vụ án hóc búa và những manh mối quan trọng về Tổ chức Áo đen bí ẩn.', 35000, 150),
(N'Conan Tập 99', 4, 2, 5, NULL, 'conan_99.jpg', N'Thám tử nhí Conan tiếp tục phô diễn tài năng suy luận đỉnh cao để vạch trần bộ mặt của những kẻ thủ ác.', 35000, 120),
(N'Conan Tập 1', 4, 2, 5, NULL, 'conan_1.jpg', N'Khởi đầu vụ án tại công viên giải trí khiến thám tử Kudo Shinichi bị teo nhỏ thành Edogawa Conan.', 20000, 600);
GO
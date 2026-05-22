namespace BookStoreAPI.DTOs
{
    public class RecommendationBookDto
    {
        public int MaSach { get; set; }
        public string TenSach { get; set; } = string.Empty;
        public string? MoTa { get; set; }
        public int SoLuongTon { get; set; }
        public string? TrangThai { get; set; }
        public string? HinhAnh { get; set; }
        public int MaTheLoai { get; set; }
        public int MaTg { get; set; }
        public string? TenTacGia { get; set; }
        public string? TenNxb { get; set; }
        public decimal GiaGoc { get; set; }
        public string? TenTheLoai { get; set; }
        public int PhanTramGiam { get; set; }
        public decimal GiaBanThucTe { get; set; }
        public string? TenSuKienKhuyenMai { get; set; }
        public double DanhGiaSao { get; set; }
        public int SoLuongDanhGia { get; set; }
        public double RecommendationScore { get; set; }
        public string RecommendationReason { get; set; } = "Sach phu hop voi so thich doc cua ban";
    }

    public class BookFeatureDto
    {
        public int BookId { get; set; }
        public string Title { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public string Category { get; set; } = string.Empty;
        public int AuthorId { get; set; }
        public string Author { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public double AverageRating { get; set; }
        public int ReviewCount { get; set; }
        public int SoldCount { get; set; }
        public int CartCount { get; set; }
    }

    public class UserBehaviorDto
    {
        public int UserId { get; set; }
        public List<int> PurchasedBookIds { get; set; } = new();
        public List<int> CartBookIds { get; set; } = new();
        public List<int> ReviewedBookIds { get; set; } = new();
        public List<int> ViewedBookIds { get; set; } = new();
        public List<int> PreferredCategoryIds { get; set; } = new();
        public List<int> PreferredAuthorIds { get; set; } = new();
    }

    public class RecommendationTrainingDataDto
    {
        public List<BookFeatureDto> Books { get; set; } = new();
        public UserBehaviorDto? Behavior { get; set; }
    }

    public class AiUserRecommendationRequest
    {
        public int UserId { get; set; }
        public int Limit { get; set; } = 10;
        public List<BookFeatureDto> Books { get; set; } = new();
        public UserBehaviorDto Behavior { get; set; } = new();
    }

    public class AiBookRecommendationRequest
    {
        public int BookId { get; set; }
        public int Limit { get; set; } = 10;
        public List<BookFeatureDto> Books { get; set; } = new();
    }

    public class AiRecommendationResponse
    {
        public List<AiRecommendationItem> Items { get; set; } = new();
    }

    public class AiRecommendationItem
    {
        public int BookId { get; set; }
        public double Score { get; set; }
        public string Reason { get; set; } = string.Empty;
    }
}

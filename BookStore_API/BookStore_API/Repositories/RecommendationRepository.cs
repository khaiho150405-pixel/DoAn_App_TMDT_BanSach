using BookStore_API.Models;
using BookStoreAPI.DTOs;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Repositories
{
    public class RecommendationRepository : IRecommendationRepository
    {
        private readonly BookStoreContext _context;

        public RecommendationRepository(BookStoreContext context)
        {
            _context = context;
        }

        public async Task<RecommendationTrainingDataDto> GetTrainingDataAsync(int? userId = null)
        {
            var ratingStats = await _context.Danhgiasaches
                .GroupBy(x => x.Masach)
                .Select(g => new
                {
                    BookId = g.Key,
                    AverageRating = g.Average(x => (double)(x.Diem ?? 0)),
                    ReviewCount = g.Count()
                })
                .ToDictionaryAsync(x => x.BookId);

            var soldStats = await _context.Chitietdonhangs
                .GroupBy(x => x.Masach)
                .Select(g => new { BookId = g.Key, SoldCount = g.Sum(x => x.Soluong) })
                .ToDictionaryAsync(x => x.BookId, x => x.SoldCount);

            var cartStats = await _context.Chitietgiohangs
                .GroupBy(x => x.Masach)
                .Select(g => new { BookId = g.Key, CartCount = g.Count() })
                .ToDictionaryAsync(x => x.BookId, x => x.CartCount);

            var books = await _context.Saches
                .Include(s => s.MatheloaiNavigation)
                .Include(s => s.MatgNavigation)
                .Where(s => s.Soluongton > 0)
                .Select(s => new
                {
                    s.Masach,
                    s.Tensach,
                    s.Matheloai,
                    Category = s.MatheloaiNavigation.Tentheloai,
                    s.Matg,
                    Author = s.MatgNavigation.Tentg,
                    s.Mota
                })
                .ToListAsync();

            var result = new RecommendationTrainingDataDto
            {
                Books = books.Select(s =>
                {
                    ratingStats.TryGetValue(s.Masach, out var rating);
                    soldStats.TryGetValue(s.Masach, out var soldCount);
                    cartStats.TryGetValue(s.Masach, out var cartCount);

                    return new BookFeatureDto
                    {
                        BookId = s.Masach,
                        Title = s.Tensach,
                        CategoryId = s.Matheloai,
                        Category = s.Category,
                        AuthorId = s.Matg,
                        Author = s.Author,
                        Description = s.Mota ?? string.Empty,
                        AverageRating = rating?.AverageRating ?? 0,
                        ReviewCount = rating?.ReviewCount ?? 0,
                        SoldCount = soldCount,
                        CartCount = cartCount
                    };
                }).ToList()
            };

            if (userId.HasValue)
            {
                result.Behavior = await GetUserBehaviorAsync(userId.Value);
            }

            return result;
        }

        public async Task<List<RecommendationBookDto>> GetBooksByRecommendationAsync(List<AiRecommendationItem> items)
        {
            if (items.Count == 0) return new List<RecommendationBookDto>();

            var itemMap = items
                .GroupBy(x => x.BookId)
                .ToDictionary(x => x.Key, x => x.First());

            var books = await QueryBookDtos()
                .Where(s => itemMap.Keys.Contains(s.MaSach))
                .ToListAsync();

            foreach (var book in books)
            {
                if (itemMap.TryGetValue(book.MaSach, out var item))
                {
                    book.RecommendationScore = item.Score;
                    book.RecommendationReason = string.IsNullOrWhiteSpace(item.Reason)
                        ? book.RecommendationReason
                        : item.Reason;
                }
            }

            return books
                .OrderByDescending(x => itemMap[x.MaSach].Score)
                .ToList();
        }

        public async Task<List<RecommendationBookDto>> GetTrendingBooksAsync(int limit)
        {
            var books = await QueryBookDtos().ToListAsync();
            return books
                .OrderByDescending(x => (x.DanhGiaSao / 5.0 * 0.35)
                    + (Math.Log10(x.SoLuongDanhGia + 1) * 0.20)
                    + (GetSoldCount(x.MaSach) * 0.35)
                    + (x.PhanTramGiam > 0 ? 0.10 : 0))
                .Take(limit)
                .Select(x =>
                {
                    x.RecommendationReason = "Sach dang hot trong cua hang";
                    return x;
                })
                .ToList();
        }

        public async Task<List<RecommendationBookDto>> GetFallbackUserRecommendationsAsync(int userId, int limit)
        {
            var behavior = await GetUserBehaviorAsync(userId);
            var interacted = behavior.PurchasedBookIds
                .Concat(behavior.CartBookIds)
                .Concat(behavior.ReviewedBookIds)
                .ToHashSet();

            var books = await QueryBookDtos().ToListAsync();
            var ranked = books
                .Where(x => !interacted.Contains(x.MaSach))
                .OrderByDescending(x => behavior.PreferredCategoryIds.Contains(x.MaTheLoai))
                .ThenByDescending(x => behavior.PreferredAuthorIds.Contains(x.MaTg))
                .ThenByDescending(x => x.DanhGiaSao)
                .ThenByDescending(x => x.SoLuongDanhGia)
                .Take(limit)
                .ToList();

            foreach (var book in ranked)
            {
                book.RecommendationScore = Math.Round((book.DanhGiaSao / 5.0) + Math.Log10(book.SoLuongDanhGia + 1) * 0.1, 4);
                book.RecommendationReason = "De xuat dua tren lich su mua hang va danh gia cua ban";
            }

            return ranked.Count > 0 ? ranked : await GetTrendingBooksAsync(limit);
        }

        public async Task<List<RecommendationBookDto>> GetFallbackSimilarBooksAsync(int bookId, int limit)
        {
            var source = await _context.Saches
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Masach == bookId);

            if (source == null) return await GetTrendingBooksAsync(limit);

            var books = await QueryBookDtos()
                .Where(x => x.MaSach != bookId)
                .ToListAsync();

            var ranked = books
                .OrderByDescending(x => x.MaTheLoai == source.Matheloai)
                .ThenByDescending(x => x.MaTg == source.Matg)
                .ThenByDescending(x => x.DanhGiaSao)
                .ThenByDescending(x => x.SoLuongDanhGia)
                .Take(limit)
                .ToList();

            foreach (var book in ranked)
            {
                book.RecommendationScore = Math.Round((book.DanhGiaSao / 5.0) + 0.2, 4);
                book.RecommendationReason = "Sach tuong tu ve the loai hoac tac gia";
            }

            return ranked;
        }

        private async Task<UserBehaviorDto> GetUserBehaviorAsync(int userId)
        {
            var purchasedBookIds = await _context.Chitietdonhangs
                .Where(x => x.MadhNavigation.Makh == userId)
                .Select(x => x.Masach)
                .Distinct()
                .ToListAsync();

            var cartBookIds = await _context.Chitietgiohangs
                .Where(x => x.MagiohangNavigation.Makh == userId)
                .Select(x => x.Masach)
                .Distinct()
                .ToListAsync();

            var reviewedBookIds = await _context.Danhgiasaches
                .Where(x => x.Makh == userId)
                .Select(x => x.Masach)
                .Distinct()
                .ToListAsync();

            var seedBookIds = purchasedBookIds
                .Concat(cartBookIds)
                .Concat(reviewedBookIds)
                .Distinct()
                .ToList();

            var preferred = await _context.Saches
                .Where(x => seedBookIds.Contains(x.Masach))
                .GroupBy(x => new { x.Matheloai, x.Matg })
                .Select(g => new
                {
                    g.Key.Matheloai,
                    g.Key.Matg,
                    Count = g.Count()
                })
                .OrderByDescending(x => x.Count)
                .ToListAsync();

            return new UserBehaviorDto
            {
                UserId = userId,
                PurchasedBookIds = purchasedBookIds,
                CartBookIds = cartBookIds,
                ReviewedBookIds = reviewedBookIds,
                PreferredCategoryIds = preferred.Select(x => x.Matheloai).Distinct().Take(5).ToList(),
                PreferredAuthorIds = preferred.Select(x => x.Matg).Distinct().Take(5).ToList()
            };
        }

        private IQueryable<RecommendationBookDto> QueryBookDtos()
        {
            var now = DateTime.Now;

            return _context.Saches
                .AsNoTracking()
                .Include(s => s.MatgNavigation)
                .Include(s => s.ManxbNavigation)
                .Include(s => s.MakmNavigation)
                .Include(s => s.MatheloaiNavigation)
                .Where(s => s.Soluongton > 0)
                .Select(s => new RecommendationBookDto
                {
                    MaSach = s.Masach,
                    TenSach = s.Tensach,
                    MoTa = s.Mota,
                    SoLuongTon = s.Soluongton,
                    TrangThai = s.Trangthai,
                    HinhAnh = s.Hinhanh,
                    MaTheLoai = s.Matheloai,
                    MaTg = s.Matg,
                    TenTacGia = s.MatgNavigation.Tentg,
                    TenNxb = s.ManxbNavigation.Tennxb,
                    GiaGoc = s.Giaban,
                    TenTheLoai = s.MatheloaiNavigation.Tentheloai,
                    PhanTramGiam = s.Makm != null && s.MakmNavigation!.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now
                        ? s.MakmNavigation.Phantramgiam
                        : 0,
                    GiaBanThucTe = s.Makm != null && s.MakmNavigation!.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now
                        ? s.Giaban - s.Giaban * s.MakmNavigation.Phantramgiam / 100
                        : s.Giaban,
                    TenSuKienKhuyenMai = s.Makm != null && s.MakmNavigation!.Ngaybatdau <= now && s.MakmNavigation.Ngayketthuc >= now
                        ? s.MakmNavigation.Tenkm
                        : null,
                    DanhGiaSao = s.Danhgiasaches.Any()
                        ? s.Danhgiasaches.Average(d => (double)(d.Diem ?? 0))
                        : 0,
                    SoLuongDanhGia = s.Danhgiasaches.Count,
                    RecommendationScore = 0,
                    RecommendationReason = "Sach phu hop voi so thich doc cua ban"
                });
        }

        private int GetSoldCount(int bookId)
        {
            return _context.Chitietdonhangs
                .Where(x => x.Masach == bookId)
                .Sum(x => (int?)x.Soluong) ?? 0;
        }
    }
}

# AI Recommendation Architecture

## Architecture

Flutter App -> ASP.NET Core Web API -> Python FastAPI AI Service -> SQL Server

ASP.NET Core is the public backend for the mobile app. It reads training data from SQL Server, calls the AI service by `HttpClient`, caches recommendation results, and falls back to local trending/content rules if the AI service is offline.

## Flow

1. Flutter calls `GET /api/recommendation/user/{userId}`, `GET /api/recommendation/book/{bookId}`, or `GET /api/recommendation/trending`.
2. ASP.NET loads book features and user behavior from SQL Server.
3. ASP.NET posts a compact payload to FastAPI.
4. FastAPI builds TF-IDF vectors from title, category, author, and description.
5. FastAPI ranks candidates by cosine similarity plus behavior and popularity signals.
6. ASP.NET enriches returned IDs with price, image, rating, and explainable reason.
7. Flutter renders horizontal recommendation sections with loading and error states.

## Folder Structure

```text
ai_recommendation_service/
  main.py
  requirements.txt
  README.md
BookStore_API/BookStore_API/
  Controllers/RecommendationController.cs
  DTOs/RecommendationDtos.cs
  Repositories/IRecommendationRepository.cs
  Repositories/RecommendationRepository.cs
  Services/RecommendationService.cs
thuvienapp/lib/
  models/recommendation_book.dart
  providers/api_service.dart
  widgets/recommendation_section.dart
  screens/KhachHang/tab_trang_chu.dart
  screens/KhachHang/book_detail_screen.dart
```

## Training Query

```sql
SELECT
    S.MASACH AS bookId,
    S.TENSACH AS title,
    S.MATHELOAI AS categoryId,
    TL.TENTHELOAI AS category,
    S.MATG AS authorId,
    TG.TENTG AS author,
    S.MOTA AS description,
    S.GIABAN AS price,
    S.HINHANH AS image,
    COALESCE(AVG(CAST(DG.DIEM AS FLOAT)), 0) AS averageRating,
    COUNT(DISTINCT DG.MADANHGIA) AS reviewCount,
    COALESCE(SUM(CTDH.SOLUONG), 0) AS soldCount,
    COALESCE(COUNT(DISTINCT CTGH.MAGIOHANG), 0) AS cartCount
FROM SACH S
JOIN THELOAI TL ON TL.MATHELOAI = S.MATHELOAI
JOIN TACGIA TG ON TG.MATG = S.MATG
LEFT JOIN DANHGIASACH DG ON DG.MASACH = S.MASACH
LEFT JOIN CHITIETDONHANG CTDH ON CTDH.MASACH = S.MASACH
LEFT JOIN CHITIETGIOHANG CTGH ON CTGH.MASACH = S.MASACH
GROUP BY
    S.MASACH, S.TENSACH, S.MATHELOAI, TL.TENTHELOAI,
    S.MATG, TG.TENTG, S.MOTA, S.GIABAN, S.HINHANH;
```

## Mock Response

```json
[
  {
    "maSach": 12,
    "tenSach": "Doraemon Tap 2",
    "tenTheLoai": "Manga",
    "tenTacGia": "Fujiko F. Fujio",
    "hinhAnh": "doraemon_2.jpg",
    "giaGoc": 25000,
    "giaBanThucTe": 25000,
    "phanTramGiam": 0,
    "danhGiaSao": 4.8,
    "soLuongDanhGia": 14,
    "recommendationScore": 0.8732,
    "recommendationReason": "De xuat vi ban quan tam the loai Manga"
  }
]
```

## Algorithm

- Content-based filtering: TF-IDF over title, category, author, description.
- Similarity: cosine similarity between book vectors.
- User behavior: purchased, cart, reviewed, and a future `viewedBookIds` hook.
- Hybrid score: content similarity + popularity + preferred category + preferred author.
- Trending score: sold count, cart count, review count, and average rating.

## Bonus Ideas

- Cache: ASP.NET `IMemoryCache` caches user/book recommendations for a few minutes.
- Real-time: add table `LUOTXEMSACH(MAKH, MASACH, THOIGIAN)` and send recent views in `viewedBookIds`.
- Explainable AI: each returned item carries `recommendationReason`.
- Offline safety: ASP.NET falls back to SQL-based trending/content rules when FastAPI is unavailable.

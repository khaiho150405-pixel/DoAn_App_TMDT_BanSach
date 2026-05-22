using BookStoreAPI.DTOs;

namespace BookStoreAPI.Repositories
{
    public interface IRecommendationRepository
    {
        Task<RecommendationTrainingDataDto> GetTrainingDataAsync(int? userId = null);
        Task<List<RecommendationBookDto>> GetBooksByRecommendationAsync(List<AiRecommendationItem> items);
        Task<List<RecommendationBookDto>> GetTrendingBooksAsync(int limit);
        Task<List<RecommendationBookDto>> GetFallbackUserRecommendationsAsync(int userId, int limit);
        Task<List<RecommendationBookDto>> GetFallbackSimilarBooksAsync(int bookId, int limit);
    }
}

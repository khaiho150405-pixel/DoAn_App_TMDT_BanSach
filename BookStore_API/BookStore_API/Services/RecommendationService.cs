using System.Net.Http.Json;
using BookStoreAPI.DTOs;
using BookStoreAPI.Repositories;
using Microsoft.Extensions.Caching.Memory;

namespace BookStoreAPI.Services
{
    public interface IRecommendationService
    {
        Task<List<RecommendationBookDto>> GetForUserAsync(int userId, int limit = 10);
        Task<List<RecommendationBookDto>> GetSimilarBooksAsync(int bookId, int limit = 10);
        Task<List<RecommendationBookDto>> GetTrendingAsync(int limit = 10);
    }

    public class RecommendationService : IRecommendationService
    {
        private readonly IRecommendationRepository _repository;
        private readonly HttpClient _httpClient;
        private readonly IMemoryCache _cache;
        private readonly ILogger<RecommendationService> _logger;

        public RecommendationService(
            IRecommendationRepository repository,
            HttpClient httpClient,
            IMemoryCache cache,
            ILogger<RecommendationService> logger)
        {
            _repository = repository;
            _httpClient = httpClient;
            _cache = cache;
            _logger = logger;
        }

        public async Task<List<RecommendationBookDto>> GetForUserAsync(int userId, int limit = 10)
        {
            var cacheKey = $"recommendation:user:{userId}:{limit}";
            if (_cache.TryGetValue(cacheKey, out List<RecommendationBookDto>? cached) && cached != null)
            {
                return cached;
            }

            try
            {
                var trainingData = await _repository.GetTrainingDataAsync(userId);
                var response = await _httpClient.PostAsJsonAsync("/recommend/user", new AiUserRecommendationRequest
                {
                    UserId = userId,
                    Limit = limit,
                    Books = trainingData.Books,
                    Behavior = trainingData.Behavior ?? new UserBehaviorDto { UserId = userId }
                });

                response.EnsureSuccessStatusCode();
                var aiResult = await response.Content.ReadFromJsonAsync<AiRecommendationResponse>(
                    new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                var books = await _repository.GetBooksByRecommendationAsync(aiResult?.Items ?? new());
                if (books.Count == 0)
                {
                    books = await _repository.GetFallbackUserRecommendationsAsync(userId, limit);
                }

                _cache.Set(cacheKey, books, TimeSpan.FromMinutes(5));
                return books;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "AI recommendation service failed for user {UserId}. Fallback is used.", userId);
                return await _repository.GetFallbackUserRecommendationsAsync(userId, limit);
            }
        }

        public async Task<List<RecommendationBookDto>> GetSimilarBooksAsync(int bookId, int limit = 10)
        {
            var cacheKey = $"recommendation:book:{bookId}:{limit}";
            if (_cache.TryGetValue(cacheKey, out List<RecommendationBookDto>? cached) && cached != null)
            {
                return cached;
            }

            try
            {
                var trainingData = await _repository.GetTrainingDataAsync();
                var response = await _httpClient.PostAsJsonAsync("/recommend/book", new AiBookRecommendationRequest
                {
                    BookId = bookId,
                    Limit = limit,
                    Books = trainingData.Books
                });

                response.EnsureSuccessStatusCode();
                var aiResult = await response.Content.ReadFromJsonAsync<AiRecommendationResponse>(
                    new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                var books = await _repository.GetBooksByRecommendationAsync(aiResult?.Items ?? new());
                if (books.Count == 0)
                {
                    books = await _repository.GetFallbackSimilarBooksAsync(bookId, limit);
                }

                _cache.Set(cacheKey, books, TimeSpan.FromMinutes(10));
                return books;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "AI recommendation service failed for book {BookId}. Fallback is used.", bookId);
                return await _repository.GetFallbackSimilarBooksAsync(bookId, limit);
            }
        }

        public async Task<List<RecommendationBookDto>> GetTrendingAsync(int limit = 10)
        {
            var cacheKey = $"recommendation:trending:{limit}";
            if (_cache.TryGetValue(cacheKey, out List<RecommendationBookDto>? cached) && cached != null)
            {
                return cached;
            }

            var books = await _repository.GetTrendingBooksAsync(limit);
            _cache.Set(cacheKey, books, TimeSpan.FromMinutes(3));
            return books;
        }
    }
}

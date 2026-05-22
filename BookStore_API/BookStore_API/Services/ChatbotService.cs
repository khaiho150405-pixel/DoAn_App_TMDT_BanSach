using System.Net.Http.Json;
using System.Text.Json;
using BookStoreAPI.DTOs;

namespace BookStoreAPI.Services
{
    public interface IChatbotService
    {
        Task<ChatbotMessageResponseDto> SendMessageAsync(
            ChatbotMessageRequestDto request,
            CancellationToken cancellationToken = default);
    }

    public class ChatbotService : IChatbotService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatbotService> _logger;

        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        };

        public ChatbotService(
            HttpClient httpClient,
            IConfiguration configuration,
            ILogger<ChatbotService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<ChatbotMessageResponseDto> SendMessageAsync(
            ChatbotMessageRequestDto request,
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(request.Message))
            {
                return new ChatbotMessageResponseDto
                {
                    Reply = "Vui long nhap noi dung can tu van.",
                    RecommendedBooks = new List<ChatbotRecommendedBookDto>()
                };
            }

            try
            {
                using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
                timeoutCts.CancelAfter(TimeSpan.FromSeconds(15));

                var endpoint = BuildChatbotEndpoint();
                var payload = new FastApiChatbotRequestDto
                {
                    Message = request.Message.Trim(),
                    SessionId = request.SessionId,
                    UserId = request.UserId,
                    Metadata = request.Metadata ?? new Dictionary<string, object>()
                };

                payload.Metadata["source"] = "aspnet-api-gateway";

                var response = await _httpClient.PostAsJsonAsync(
                    endpoint,
                    payload,
                    JsonOptions,
                    timeoutCts.Token);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning(
                        "FastAPI chatbot returned status code {StatusCode}",
                        response.StatusCode);
                    return BuildUnavailableResponse();
                }

                var chatbotResponse = await response.Content.ReadFromJsonAsync<FastApiChatbotResponseDto>(
                    JsonOptions,
                    timeoutCts.Token);

                if (chatbotResponse == null || string.IsNullOrWhiteSpace(chatbotResponse.Reply))
                {
                    return BuildFallbackResponse();
                }

                return new ChatbotMessageResponseDto
                {
                    Reply = chatbotResponse.Reply,
                    RecommendedBooks = chatbotResponse.RecommendedBooks ?? new List<ChatbotRecommendedBookDto>()
                };
            }
            catch (OperationCanceledException ex) when (!cancellationToken.IsCancellationRequested)
            {
                _logger.LogWarning(ex, "FastAPI chatbot request timed out.");
                return BuildUnavailableResponse();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "FastAPI chatbot request failed.");
                return BuildFallbackResponse();
            }
        }

        private string BuildChatbotEndpoint()
        {
            var baseUrl = _configuration["AiChatbot:BaseUrl"] ?? "http://localhost:8002";
            return $"{baseUrl.TrimEnd('/')}/chatbot/message";
        }

        private static ChatbotMessageResponseDto BuildUnavailableResponse()
        {
            return new ChatbotMessageResponseDto
            {
                Reply = "Chatbot dang tam thoi ban. Vui long thu lai sau it phut.",
                RecommendedBooks = new List<ChatbotRecommendedBookDto>()
            };
        }

        private static ChatbotMessageResponseDto BuildFallbackResponse()
        {
            return new ChatbotMessageResponseDto
            {
                Reply = "Minh chua the tao cau tra loi luc nay. Ban co the hoi ve ten sach, tac gia, the loai hoac khuyen mai.",
                RecommendedBooks = new List<ChatbotRecommendedBookDto>()
            };
        }
    }
}

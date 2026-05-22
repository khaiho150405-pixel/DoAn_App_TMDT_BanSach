namespace BookStoreAPI.DTOs
{
    public class ChatbotMessageRequestDto
    {
        public string Message { get; set; } = string.Empty;
        public string? SessionId { get; set; }
        public int? UserId { get; set; }
        public Dictionary<string, object> Metadata { get; set; } = new();
    }

    public class ChatbotMessageResponseDto
    {
        public string Reply { get; set; } = string.Empty;
        public List<ChatbotRecommendedBookDto> RecommendedBooks { get; set; } = new();
    }

    public class ChatbotRecommendedBookDto
    {
        public int BookId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Author { get; set; }
        public string? Category { get; set; }
        public string? Image { get; set; }
        public decimal? Price { get; set; }
        public double? Rating { get; set; }
        public string? Reason { get; set; }
    }

    public class FastApiChatbotRequestDto
    {
        public string Message { get; set; } = string.Empty;
        public string? SessionId { get; set; }
        public int? UserId { get; set; }
        public Dictionary<string, object> Metadata { get; set; } = new();
    }

    public class FastApiChatbotResponseDto
    {
        public string Reply { get; set; } = string.Empty;
        public List<ChatbotRecommendedBookDto> RecommendedBooks { get; set; } = new();
    }
}

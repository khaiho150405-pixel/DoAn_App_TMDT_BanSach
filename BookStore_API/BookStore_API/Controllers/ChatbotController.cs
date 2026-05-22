using BookStoreAPI.DTOs;
using BookStoreAPI.Services;
using Microsoft.AspNetCore.Mvc;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ChatbotController : ControllerBase
    {
        private readonly IChatbotService _chatbotService;

        public ChatbotController(
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<ChatbotService> logger)
        {
            _chatbotService = new ChatbotService(
                httpClientFactory.CreateClient(),
                configuration,
                logger);
        }

        [HttpPost("message")]
        public async Task<ActionResult<ChatbotMessageResponseDto>> SendMessage(
            [FromBody] ChatbotMessageRequestDto request,
            CancellationToken cancellationToken)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Message))
            {
                return BadRequest(new
                {
                    message = "Message is required."
                });
            }

            var response = await _chatbotService.SendMessageAsync(request, cancellationToken);
            return Ok(response);
        }
    }
}

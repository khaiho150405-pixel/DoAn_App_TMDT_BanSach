using BookStoreAPI.Services;
using Microsoft.AspNetCore.Mvc;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _service;

        public RecommendationController(IRecommendationService service)
        {
            _service = service;
        }

        [HttpGet("user/{userId:int}")]
        public async Task<IActionResult> GetForUser(int userId, [FromQuery] int limit = 10)
        {
            var result = await _service.GetForUserAsync(userId, limit);
            return Ok(result);
        }

        [HttpGet("book/{bookId:int}")]
        public async Task<IActionResult> GetSimilarBooks(int bookId, [FromQuery] int limit = 10)
        {
            var result = await _service.GetSimilarBooksAsync(bookId, limit);
            return Ok(result);
        }

        [HttpGet("trending")]
        public async Task<IActionResult> GetTrending([FromQuery] int limit = 10)
        {
            var result = await _service.GetTrendingAsync(limit);
            return Ok(result);
        }
    }
}

using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public OrdersController(BookStoreContext context)
        {
            _context = context;
        }

        [HttpGet("recent")]
        public async Task<IActionResult> GetRecentOrders()
        {
            var recentOrders = await _context.Donhangs
                .OrderByDescending(d => d.Ngaydat)
                .Take(10)
                .Select(d => new
                {
                    orderId = d.Madh,
                    customerName = d.Tennguoinhan ?? "Khách hàng",
                    totalAmount = d.Tongtien,
                    status = d.Trangthaidonhang,
                    createdAt = d.Ngaydat
                })
                .ToListAsync();

            return Ok(recentOrders);
        }
    }
}

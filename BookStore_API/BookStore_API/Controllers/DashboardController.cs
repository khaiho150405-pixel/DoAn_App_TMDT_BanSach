using BookStore_API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DashboardController : ControllerBase
    {
        private readonly BookStoreContext _context;

        public DashboardController(BookStoreContext context)
        {
            _context = context;
        }

        [HttpGet("summary")]
        public async Task<IActionResult> GetSummary()
        {
            var totalRevenue = await _context.Donhangs
                .Where(d => d.Trangthaidonhang != "Đã hủy")
                .SumAsync(d => (double?)d.Tongtien) ?? 0.0;

            var today = DateTime.Today;
            var newOrdersToday = await _context.Donhangs
                .CountAsync(d => d.Ngaydat >= today);

            var importCost = await _context.Phieunhaps
                .SumAsync(p => (double?)p.Tongtien) ?? 0.0;

            var activeAccounts = await _context.Taikhoans
                .CountAsync(t => t.Trangthai == "Hoạt động");

            return Ok(new
            {
                totalRevenue = totalRevenue,
                newOrdersToday = newOrdersToday,
                importCost = importCost,
                activeAccounts = activeAccounts
            });
        }

        [HttpGet("revenue-chart")]
        public async Task<IActionResult> GetRevenueChart()
        {
            var today = DateTime.Today;
            var chartPoints = new List<object>();

            for (int i = 6; i >= 0; i--)
            {
                var date = today.AddDays(-i);
                var revenue = await _context.Donhangs
                    .Where(d => d.Ngaydat >= date && d.Ngaydat < date.AddDays(1) && d.Trangthaidonhang != "Đã hủy")
                    .SumAsync(d => (double?)d.Tongtien) ?? 0.0;

                chartPoints.Add(new
                {
                    label = date.ToString("dd/MM"),
                    revenue = revenue
                });
            }

            return Ok(chartPoints);
        }
    }
}

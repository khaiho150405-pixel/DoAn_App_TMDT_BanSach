using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using BookStoreAPI.DTOs;
using BookStoreAPI.Services;
using Microsoft.Extensions.Logging;

namespace BookStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrderController : ControllerBase
    {
        private readonly IOrderService _orderService;
        private readonly ILogger<OrderController> _logger;

        public OrderController(IOrderService orderService, ILogger<OrderController> logger)
        {
            _orderService = orderService;
            _logger = logger;
        }

        [HttpPost("Checkout")]
        public async Task<IActionResult> Checkout([FromBody] CheckoutRequestDto request)
        {
            try
            {
                if (request.Items == null || request.Items.Count == 0)
                {
                    return BadRequest(new { success = false, message = "Giỏ hàng của bạn đang trống, không thể thanh toán!" });
                }

                var result = await _orderService.CreateOrderAsync(request);
                return Ok(new { success = true, message = "Đặt hàng thành công!", data = result });
            }
            catch (System.Exception ex)
            {
                _logger.LogError(ex, "Lỗi Checkout: {Message}", ex.Message);
                return StatusCode(500, new { success = false, message = $"Lỗi hệ thống: {ex.Message}", error = ex.ToString() });
            }
        }

        [HttpGet("Customer/{customerId}")]
        public async Task<IActionResult> GetCustomerOrders(int customerId)
        {
            try
            {
                var orders = await _orderService.GetOrdersByCustomerAsync(customerId);
                return Ok(new { success = true, message = "Success", data = orders });
            }
            catch (System.Exception ex)
            {
                _logger.LogError(ex, "Lỗi GetCustomerOrders: {Message}", ex.Message);
                return StatusCode(500, new { success = false, message = $"Lỗi hệ thống: {ex.Message}" });
            }
        }

        [HttpGet("{orderId}")]
        public async Task<IActionResult> GetOrderDetail(int orderId)
        {
            try
            {
                var order = await _orderService.GetOrderDetailAsync(orderId);
                if (order == null) return NotFound(new { success = false, message = "Không tìm thấy đơn hàng!" });
                return Ok(new { success = true, message = "Success", data = order });
            }
            catch (System.Exception ex)
            {
                _logger.LogError(ex, "Lỗi GetOrderDetail: {Message}", ex.Message);
                return StatusCode(500, new { success = false, message = $"Lỗi hệ thống: {ex.Message}" });
            }
        }
    }
}

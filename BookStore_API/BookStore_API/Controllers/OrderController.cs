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
        [HttpPut("cancel/{orderId}")]
        public async Task<IActionResult> CancelOrder(int orderId)
        {
            try
            {
                var result = await _orderService.CancelOrderAsync(orderId);
                if (!result)
                {
                    return BadRequest(new { success = false, message = "Không thể hủy đơn hàng này" });
                }
                return Ok(new { success = true, message = "Hủy đơn hàng thành công" });
            }
            catch (System.Exception ex)
            {
                _logger.LogError(ex, "Lỗi CancelOrder: {Message}", ex.Message);
                return StatusCode(500, new { success = false, message = $"Lỗi hệ thống: {ex.Message}" });
            }
        }

        [HttpGet("pending")]
        public async Task<IActionResult> GetPendingOrders()
        {
            try
            {
                var orders = await _orderService.GetPendingOrdersAsync();
                return Ok(new { success = true, message = "Success", data = orders });
            }
            catch (System.Exception ex)
            {
                _logger.LogError(ex, "Lỗi GetPendingOrders: {Message}", ex.Message);
                return StatusCode(500, new { success = false, message = $"Lỗi hệ thống: {ex.Message}" });
            }
        }

        [HttpPut("test-confirm/{orderId}")]
        public async Task<IActionResult> TestConfirmOrder(int orderId)
        {
            try
            {
                _logger.LogInformation("Testing Confirm Order: {OrderId}", orderId);
                var result = await _orderService.ConfirmOrderAsync(orderId);
                if (!result)
                {
                    return BadRequest(new { success = false, message = "Không thể xác nhận đơn hàng này (không tồn tại hoặc không ở trạng thái Chờ xác nhận)" });
                }

                var updatedOrder = await _orderService.GetOrderDetailAsync(orderId);
                return Ok(new { success = true, message = "Xác nhận đơn hàng thành công", data = updatedOrder });
            }
            catch (System.Exception ex)
            {
                _logger.LogError(ex, "Lỗi TestConfirmOrder: {Message}", ex.Message);
                return StatusCode(500, new { success = false, message = $"Lỗi hệ thống: {ex.Message}" });
            }
        }
    }
}

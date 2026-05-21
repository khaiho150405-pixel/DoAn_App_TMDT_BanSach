using BookStore_API.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace BookStoreAPI.Repositories
{
    public interface IOrderRepository
    {
        Task<Donhang> CreateOrderAsync(Donhang order, List<Chitietdonhang> details);
        Task<List<Donhang>> GetOrdersByCustomerIdAsync(int customerId);
        Task<Donhang?> GetOrderByIdAsync(int orderId);
        Task<List<Chitietdonhang>> GetOrderDetailsAsync(int orderId);
        Task<bool> CancelOrderAsync(int orderId);
        Task<List<Donhang>> GetPendingOrdersAsync();
        Task<bool> ConfirmOrderAsync(int orderId);
    }
}

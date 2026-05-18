using BookStore_API.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System;

namespace BookStoreAPI.Repositories
{
    public interface IOrderRepository
    {
        Task<Donhang> CreateOrderAsync(Donhang order, List<Chitietdonhang> details);
        Task<List<Donhang>> GetOrdersByCustomerIdAsync(int customerId);
        Task<Donhang?> GetOrderByIdAsync(int orderId);
        Task<List<Chitietdonhang>> GetOrderDetailsAsync(int orderId);
    }

    public class OrderRepository : IOrderRepository
    {
        private readonly BookStoreContext _context;

        public OrderRepository(BookStoreContext context)
        {
            _context = context;
        }

        public async Task<Donhang> CreateOrderAsync(Donhang order, List<Chitietdonhang> details)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                _context.Donhangs.Add(order);
                await _context.SaveChangesAsync();

                foreach (var detail in details)
                {
                    detail.Madh = order.Madh;
                    _context.Chitietdonhangs.Add(detail);
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return order;
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<List<Donhang>> GetOrdersByCustomerIdAsync(int customerId)
        {
            return await _context.Donhangs
                .Where(o => o.Makh == customerId)
                .OrderByDescending(o => o.Ngaydat)
                .ToListAsync();
        }

        public async Task<Donhang?> GetOrderByIdAsync(int orderId)
        {
            return await _context.Donhangs.FirstOrDefaultAsync(o => o.Madh == orderId);
        }

        public async Task<List<Chitietdonhang>> GetOrderDetailsAsync(int orderId)
        {
            return await _context.Chitietdonhangs
                .Include(c => c.MasachNavigation)
                .Where(c => c.Madh == orderId)
                .ToListAsync();
        }
    }
}

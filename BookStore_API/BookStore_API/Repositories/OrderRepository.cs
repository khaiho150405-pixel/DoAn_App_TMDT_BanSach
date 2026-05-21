using BookStore_API.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System;

namespace BookStoreAPI.Repositories
{
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

        public async Task<bool> CancelOrderAsync(int orderId)
        {
            var order = await _context.Donhangs.FirstOrDefaultAsync(o => o.Madh == orderId);
            if (order == null) return false;

            if (order.Trangthaidonhang == "Chờ xác nhận")
            {
                order.Trangthaidonhang = "Đã hủy";
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }

        public async Task<List<Donhang>> GetPendingOrdersAsync()
        {
            return await _context.Donhangs
                .Include(o => o.MakhNavigation)
                .Where(o => o.Trangthaidonhang == "Chờ xác nhận")
                .OrderByDescending(o => o.Ngaydat)
                .ToListAsync();
        }

        public async Task<bool> ConfirmOrderAsync(int orderId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var order = await _context.Donhangs
                    .Include(o => o.Chitietdonhangs)
                    .FirstOrDefaultAsync(o => o.Madh == orderId);
                
                if (order == null || order.Trangthaidonhang != "Chờ xác nhận")
                    return false;

                order.Trangthaidonhang = "Đang chuẩn bị hàng";

                foreach (var detail in order.Chitietdonhangs)
                {
                    var sach = await _context.Saches.FirstOrDefaultAsync(s => s.Masach == detail.Masach);
                    if (sach != null)
                    {
                        sach.Soluongton -= detail.Soluong;
                        
                        if (sach.Soluongton < 0) sach.Soluongton = 0;
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return true;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BookStore_API.Models;
using BookStoreAPI.DTOs;
using BookStoreAPI.Repositories;

namespace BookStoreAPI.Services
{
    public interface IOrderService
    {
        Task<OrderResponseDto> CreateOrderAsync(CheckoutRequestDto request);
        Task<List<OrderResponseDto>> GetOrdersByCustomerAsync(int customerId);
        Task<OrderResponseDto?> GetOrderDetailAsync(int orderId);
    }

    public class OrderService : IOrderService
    {
        private readonly IOrderRepository _repository;

        public OrderService(IOrderRepository repository)
        {
            _repository = repository;
        }

        public async Task<OrderResponseDto> CreateOrderAsync(CheckoutRequestDto request)
        {
            var order = new Donhang
            {
                Makh = request.MaKH,
                Ngaydat = DateTime.Now,
                Tongtien = request.TongTien,
                Tennguoinhan = request.TenNguoiNhan,
                Sdtnhan = request.SdtNhan,
                Diachigiao = request.DiaChiGiao,
                Phuongthucthanhtoan = request.PhuongThucThanhToan,
                Trangthaithanhtoan = request.PhuongThucThanhToan == "COD" ? "Chưa thanh toán" : "Đã thanh toán",
                Trangthaidonhang = "Chờ xác nhận",
                Ghichu = request.GhiChu
            };

            var details = request.Items.Select(i => new Chitietdonhang
            {
                Masach = i.MaSach,
                Soluong = i.SoLuong,
                Dongia = i.DonGia,
                Thanhtien = i.DonGia * i.SoLuong
            }).ToList();

            var createdOrder = await _repository.CreateOrderAsync(order, details);

            return await GetOrderDetailAsync(createdOrder.Madh);
        }

        public async Task<List<OrderResponseDto>> GetOrdersByCustomerAsync(int customerId)
        {
            var orders = await _repository.GetOrdersByCustomerIdAsync(customerId);
            var result = new List<OrderResponseDto>();

            foreach (var order in orders)
            {
                var details = await _repository.GetOrderDetailsAsync(order.Madh);
                result.Add(MapToDto(order, details));
            }

            return result;
        }

        public async Task<OrderResponseDto?> GetOrderDetailAsync(int orderId)
        {
            var order = await _repository.GetOrderByIdAsync(orderId);
            if (order == null) return null;

            var details = await _repository.GetOrderDetailsAsync(orderId);
            return MapToDto(order, details);
        }

        private OrderResponseDto MapToDto(Donhang order, List<Chitietdonhang> details)
        {
            return new OrderResponseDto
            {
                MaDH = order.Madh,
                NgayDat = order.Ngaydat,
                TongTien = order.Tongtien,
                TenNguoiNhan = order.Tennguoinhan,
                SdtNhan = order.Sdtnhan,
                DiaChiGiao = order.Diachigiao,
                PhuongThucThanhToan = order.Phuongthucthanhtoan ?? "COD",
                TrangThaiThanhToan = order.Trangthaithanhtoan ?? "Chưa thanh toán",
                TrangThaiDonHang = order.Trangthaidonhang ?? "Chờ xác nhận",
                SoLuongSanPham = details.Sum(d => d.Soluong),
                ChiTiet = details.Select(d => new OrderDetailDto
                {
                    MaSach = d.Masach,
                    TenSach = d.MasachNavigation?.Tensach ?? "Sách không xác định",
                    HinhAnh = d.MasachNavigation?.Hinhanh ?? "",
                    SoLuong = d.Soluong,
                    DonGia = d.Dongia,
                    ThanhTien = d.Thanhtien ?? (d.Dongia * d.Soluong)
                }).ToList()
            };
        }
    }
}

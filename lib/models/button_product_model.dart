import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ButtonProductModel {
  final String id;
  final String name;
  final String shortName;
  final String brand;
  final String specs;
  final int price;
  final String priceFormatted;
  final String unitPriceFormatted;
  final String? badge;
  final String discountTag;
  final String deliveryTag;
  final double rating;
  final int reviewCount;
  final String description;
  final String category;
  final IconData icon;
  final Color themeColor;

  const ButtonProductModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.brand,
    required this.specs,
    required this.price,
    required this.priceFormatted,
    required this.unitPriceFormatted,
    this.badge,
    required this.discountTag,
    required this.deliveryTag,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.category,
    required this.icon,
    required this.themeColor,
  });

  factory ButtonProductModel.fromJson(Map<String, dynamic> json) {
    final id = json['productId']?.toString() ?? json['id']?.toString() ?? 'prod-00';
    final name = json['name']?.toString() ?? 'Sản phẩm';
    final priceVal = (json['price'] as num?)?.toInt() ?? 50000;
    final category = json['category']?['name']?.toString() ?? json['category']?.toString() ?? 'Nhu yếu phẩm';
    final desc = json['description']?.toString() ?? 'Sản phẩm chính hãng chất lượng cao.';
    final brand = json['brand']?.toString() ?? 'Chính hãng';
    final specs = json['specs']?.toString() ?? json['unit']?.toString() ?? 'Tiêu chuẩn';

    return ButtonProductModel(
      id: id,
      name: name,
      shortName: name.length > 20 ? '${name.substring(0, 18)}...' : name,
      brand: brand,
      specs: specs,
      price: priceVal,
      priceFormatted: '${priceVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ',
      unitPriceFormatted: 'Giá tiêu chuẩn',
      badge: json['isFeatured'] == true ? 'Nổi bật' : null,
      discountTag: 'Ưu đãi đặt qua nút bấm',
      deliveryTag: '⚡ Giao nhanh 2h',
      rating: 4.9,
      reviewCount: 120,
      description: desc,
      category: category,
      icon: LucideIcons.package,
      themeColor: const Color(0xFF0D9488),
    );
  }

  static List<ButtonProductModel> get sampleProducts => const [
    ButtonProductModel(
      id: 'prod-lavie-19l',
      name: 'Nước khoáng thiên nhiên LaVie 19L bình úp (Nestlé Waters)',
      shortName: 'Nước Lavie 20L',
      brand: 'LaVie',
      specs: 'Bình úp 19L • Dành cho máy nước nóng lạnh / úp',
      price: 65000,
      priceFormatted: '65.000đ',
      unitPriceFormatted: '3.421đ / Lít',
      badge: 'Phổ biến nhất',
      discountTag: 'Giảm thêm 5% khi đặt qua nút bấm',
      deliveryTag: '⚡ Giao nhanh 2h',
      rating: 4.9,
      reviewCount: 25737,
      description:
          'Nước khoáng thiên nhiên LaVie được đóng chai tại nguồn bằng công nghệ khép kín hiện đại của Nestlé Waters, chứa 6 khoáng chất thiết yếu tốt cho sức khỏe cả gia đình. Hỗ trợ vác lầu miễn phí.',
      category: 'Nước uống',
      icon: LucideIcons.droplets,
      themeColor: Color(0xFF0284C7),
    ),
    ButtonProductModel(
      id: 'prod-vihawa-20l',
      name: 'Nước tinh khiết Vihawa 20L bình có vòi tiện lợi',
      shortName: 'Nước Vihawa 20L',
      brand: 'Vĩnh Hảo',
      specs: 'Bình có vòi 20L • Uống trực tiếp không cần bình úp',
      price: 58000,
      priceFormatted: '58.000đ',
      unitPriceFormatted: '2.900đ / Lít',
      badge: 'Gợi ý gia đình',
      discountTag: 'Giảm thêm 5% khi đặt qua nút bấm',
      deliveryTag: '⚡ Giao nhanh 2h',
      rating: 4.8,
      reviewCount: 18420,
      description:
          'Nước tinh khiết Vihawa sản xuất theo quy trình lọc RO đa cấp tiệt trùng tia UV và Ozone hiện đại, vị thanh mát, an toàn tuyệt đối cho người lớn và trẻ nhỏ.',
      category: 'Nước uống',
      icon: LucideIcons.droplet,
      themeColor: Color(0xFF0EA5E9),
    ),
    ButtonProductModel(
      id: 'prod-petrolimex-12kg',
      name: 'Bình Gas Petrolimex 12kg van ngang an toàn (Chính hãng)',
      shortName: 'Bình Gas Petrolimex 12kg',
      brand: 'Petrolimex',
      specs: 'Bình thép 12kg • Tem chống giả & màng co niêm phong',
      price: 380000,
      priceFormatted: '380.000đ',
      unitPriceFormatted: '31.666đ / kg',
      badge: 'Chính hãng 100%',
      discountTag: 'Tặng 20.000đ tích lũy cho lần bấm kế',
      deliveryTag: '⚡ Kỹ thuật viên giao & lắp đặt tận nơi',
      rating: 4.9,
      reviewCount: 9860,
      description:
          'Gas Petrolimex cho ngọn lửa xanh không muội than, tiết kiệm gas, bảo hiểm cháy nổ 300 triệu đồng. Kỹ thuật viên kiểm tra rò rỉ gas bằng máy đo chuyên dụng miễn phí.',
      category: 'Năng lượng / Bếp',
      icon: LucideIcons.flame,
      themeColor: Color(0xFFEA580C),
    ),
    ButtonProductModel(
      id: 'prod-saigonpetro-12kg',
      name: 'Bình Gas Saigon Petro 12kg bình xám (SP Gas)',
      shortName: 'Bình Gas Saigon Petro 12kg',
      brand: 'Saigon Petro',
      specs: 'Bình xám 12kg • Van điều áp đạt chuẩn an toàn PCCC',
      price: 365000,
      priceFormatted: '365.000đ',
      unitPriceFormatted: '30.416đ / kg',
      badge: 'Tiết kiệm',
      discountTag: 'Giảm thêm 15.000đ khi reorder',
      deliveryTag: '⚡ Giao nhanh 45 phút',
      rating: 4.7,
      reviewCount: 7450,
      description:
          'Thương hiệu Saigon Petro uy tín lâu năm, gas sạch cháy đều, van xả an toàn tự động ngắt khi có sự cố. Hỗ trợ kiểm tra miễn phí dây dẫn và bếp gas.',
      category: 'Năng lượng / Bếp',
      icon: LucideIcons.flame,
      themeColor: Color(0xFFD97706),
    ),
    ButtonProductModel(
      id: 'prod-gao-st25-5kg',
      name: 'Gạo ST25 Sóc Trăng Thượng Hạng Túi 5kg (Gạo Ngon Nhất Thế Giới)',
      shortName: 'Gạo ST25 5kg',
      brand: 'Gạo Ông Cua',
      specs: 'Túi hút chân không 5kg • Chuẩn ST25 chính hãng',
      price: 165000,
      priceFormatted: '165.000đ',
      unitPriceFormatted: '33.000đ / kg',
      badge: 'Bán chạy tuần này',
      discountTag: 'Giảm thêm 8% khi đặt qua Smart Button',
      deliveryTag: '⚡ Giao trong ngày',
      rating: 4.9,
      reviewCount: 14210,
      description:
          'Hạt gạo thon dài, trắng trong, cơm dẻo mềm thơm mùi lá dứa tự nhiên kể cả khi để nguội. Nguồn gốc Sóc Trăng chính hiệu với mã QR truy xuất nguồn gốc.',
      category: 'Lương thực',
      icon: LucideIcons.wheat,
      themeColor: Color(0xFF16A34A),
    ),
    ButtonProductModel(
      id: 'prod-aquafina-500ml',
      name: 'Thùng Nước Tinh Khiết Aquafina 500ml (Thùng 24 chai chính hãng)',
      shortName: 'Aquafina 500ml (24 chai)',
      brand: 'Aquafina',
      specs: 'Thùng 24 chai x 500ml • Đóng lốc nguyên seal',
      price: 98000,
      priceFormatted: '98.000đ',
      unitPriceFormatted: '4.083đ / chai',
      badge: 'Gợi ý văn phòng',
      discountTag: 'Giảm thêm 5% khi đặt qua nút bấm',
      deliveryTag: '⚡ Giao siêu tốc 2h',
      rating: 4.8,
      reviewCount: 12450,
      description:
          'Sản phẩm của Suntory PepsiCo, xử lý qua công nghệ thẩm thấu ngược Hydro-7 độc quyền mang đến nguồn nước uống tinh khiết đạt chuẩn quốc tế.',
      category: 'Nước uống',
      icon: LucideIcons.cupSoda,
      themeColor: Color(0xFF2563EB),
    ),
    ButtonProductModel(
      id: 'prod-omo-matic-36kg',
      name: 'Nước Giặt OMO Matic Chuyên Dụng Túi 3.6kg (Khử Mùi Ẩm Mốc)',
      shortName: 'Nước giặt OMO 3.6kg',
      brand: 'OMO',
      specs: 'Túi nắp vặn tiết kiệm 3.6kg • Dành cho máy giặt cửa trên',
      price: 175000,
      priceFormatted: '175.000đ',
      unitPriceFormatted: '48.611đ / kg',
      badge: 'Khuyên dùng',
      discountTag: 'Giảm thêm 5% reorder tự động',
      deliveryTag: '⚡ Giao trong 2h',
      rating: 4.8,
      reviewCount: 8730,
      description:
          'Công thức màn chắn kháng bẩn Polyshield 2.0 xoáy bay vết bẩn cứng đầu và khử mùi ẩm mốc vượt trội cho quần áo luôn thơm ngát suốt 24 giờ.',
      category: 'Gia dụng / Vệ sinh',
      icon: LucideIcons.sparkles,
      themeColor: Color(0xFF9333EA),
    ),
    ButtonProductModel(
      id: 'prod-pulppy-10c',
      name: 'Lốc 10 Cuộn Giấy Vệ Sinh Pulppy 3 Lớp Có Lõi (Siêu Mềm Mại)',
      shortName: 'Giấy vệ sinh Pulppy 10 cuộn',
      brand: 'Pulppy',
      specs: 'Lốc 10 cuộn x 3 lớp • 100% bột giấy nguyên chất',
      price: 85000,
      priceFormatted: '85.000đ',
      unitPriceFormatted: '8.500đ / cuộn',
      badge: 'Nhu yếu phẩm',
      discountTag: 'Giảm thêm 5% khi bấm nút đặt lại',
      deliveryTag: '⚡ Freeship đơn từ 150k',
      rating: 4.9,
      reviewCount: 32100,
      description:
          '100% bột giấy nguyên sinh nhập khẩu, giấy trắng mịn tự nhiên không hóa chất tẩy trắng huỳnh quang, cực kỳ dai mềm và an toàn cho làn da mẫn cảm.',
      category: 'Gia dụng / Vệ sinh',
      icon: LucideIcons.package,
      themeColor: Color(0xFF0D9488),
    ),
  ];
}

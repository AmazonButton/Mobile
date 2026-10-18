import 'package:flutter/material.dart';

/// Recent activities list widget for HomeScreen.
class HomeRecentActivities extends StatelessWidget {
  const HomeRecentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'title': '1x Nước Lavie 20L',
        'room': 'Nút Bếp',
        'time': 'Hôm nay, 10:30',
        'price': '65.000đ',
        'status': 'Đã nhận hàng',
      },
      {
        'title': '1x Bình Gas Petrolimex 12kg',
        'room': 'Nút Ban Công',
        'time': '28 Th09, 15:45',
        'price': '380.000đ',
        'status': 'Đã nhận hàng',
      },
    ];

    return Column(
      children: activities.asMap().entries.map((entry) {
        final item = entry.value;
        final isLast = entry.key == activities.length - 1;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item['time']} • ${item['room']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['price']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          item['status']!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  double totalRevenue = 0;
  int totalInvoices = 0;
  // 👉 danh sách doanh thu theo ngày
  List<Map<String, dynamic>> revenueByDate = [];

  // 👉 danh sách doanh thu theo tháng
  List<Map<String, dynamic>> revenueByMonth = [];
  final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  // ================= BIỂU ĐỒ DOANH THU =================
  Widget buildChart() {
    // 👉 Nếu không có dữ liệu thì không vẽ chart
    if (revenueByDate.isEmpty) {
      return const Text("Chưa có dữ liệu");
    }

    // 👉 SizedBox để cố định chiều cao biểu đồ
    return SizedBox(
      height: 220,

      child: LineChart(
        LineChartData(
          // ================= GRID (lưới nền) =================
          gridData: FlGridData(
            show: true, // 👉 bật đường lưới ngang/dọc
          ),

          // ================= BORDER =================
          borderData: FlBorderData(
            show: false, // 👉 tắt viền xung quanh
          ),

          // ================= TRỤC (AXIS) =================
          titlesData: FlTitlesData(
            // ===== TRỤC X (NGÀY) =====
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // 👉 hiển thị chữ dưới trục X
                // 👉 custom hiển thị label
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();

                  // 👉 tránh lỗi index vượt phạm vi
                  if (index < 0 || index >= revenueByDate.length) {
                    return const SizedBox();
                  }

                  // 👉 lấy ngày từ database
                  String date = revenueByDate[index]['d'];

                  return Text(
                    date.substring(5), // 👉 chỉ lấy MM-DD (vd: 04-06)
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),

            // ===== TRỤC Y (TIỀN) =====
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // 👉 hiển thị giá trị tiền
                // 👉 format tiền (triệu)
                getTitlesWidget: (value, meta) {
                  return Text(
                    "${(value / 1000000).toStringAsFixed(1)}M",
                    // 👉 ví dụ: 4.2M
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),

            // 👉 Ẩn trục phải (không cần)
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

            // 👉 Ẩn trục trên (cho gọn)
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          // ================= DATA BIỂU ĐỒ =================
          lineBarsData: [
            LineChartBarData(
              isCurved: true, // 👉 làm đường cong mượt hơn

              color: Colors.blue, // 👉 màu đường

              barWidth: 3, // 👉 độ dày đường
              // 👉 chuyển dữ liệu DB thành điểm (x, y)
              spots: revenueByDate.asMap().entries.map((e) {
                int index = e.key;

                double value = (e.value['total'] as num).toDouble();

                return FlSpot(
                  index.toDouble(), // 👉 trục X (0,1,2,...)
                  value, // 👉 trục Y (tiền)
                );
              }).toList(),

              // 👉 hiển thị chấm tại mỗi điểm
              dotData: FlDotData(show: true),

              // 👉 nền dưới đường (làm đẹp)
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ],

          // ================= TOUCH (bấm vào điểm) =================
          lineTouchData: LineTouchData(
            enabled: true,

            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    "${spot.y.toStringAsFixed(0)} đ",
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // 👉 load dữ liệu
  void loadData() async {
    final revenue = await DBHelper.getTotalRevenue();
    final invoices = await DBHelper.getInvoices();
    // 👉 gọi thống kê mới
    final byDate = await DBHelper.getRevenueByDate();
    final byMonth = await DBHelper.getRevenueByMonth();
    setState(() {
      totalRevenue = revenue;
      totalInvoices = invoices.length;

      // 👉 gán dữ liệu
      revenueByDate = byDate;
      revenueByMonth = byMonth;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // 👉 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thống kê")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== CARD DOANH THU =====
              _buildCard(
                title: "Tổng doanh thu",
                value: format.format(totalRevenue),
                icon: Icons.attach_money,
                color: Colors.green,
              ),

              const SizedBox(height: 16),

              // ===== CARD SỐ HOÁ ĐƠN =====
              _buildCard(
                title: "Số hóa đơn",
                value: totalInvoices.toString(),
                icon: Icons.receipt,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              // ================= BIỂU ĐỒ =================
              const SizedBox(height: 20),

              const Text(
                "Biểu đồ doanh thu",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              buildChart(),
              // ================= DOANH THU THEO NGÀY =================
              const Text(
                "Doanh thu theo ngày",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              // 👉 loop list
              ...revenueByDate.map(
                (e) => ListTile(
                  title: Text(e['d']), // 👉 ngày
                  trailing: Text(format.format(e['total'])), // 👉 tiền
                ),
              ),

              const SizedBox(height: 20),

              // ================= DOANH THU THEO THÁNG =================
              const Text(
                "Doanh thu từng tháng (DB riêng)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // 👉 nếu không có dữ liệu
              if (revenueByMonth.isEmpty) const Text("Chưa có dữ liệu"),

              // 👉 hiển thị list
              ...revenueByMonth.map(
                (e) => ListTile(
                  title: Text("${e['m']}"), // 👉 dạng 2026-04
                  trailing: Text(format.format(e['total'])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 👉 widget card đẹp
  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),

          const SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

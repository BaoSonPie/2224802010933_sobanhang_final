import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  // 👉 danh sách hóa đơn
  List<Map<String, dynamic>> invoices = [];

  // 👉 format tiền VN
  final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  // 👉 biến lưu ngày user chọn để filter
  DateTime? selectedDate;
  // ================= LOAD DATA =================
  void loadData() async {
    // 👉 lấy toàn bộ hóa đơn từ database
    final data = await DBHelper.getInvoices();

    // 👉 nếu user có chọn ngày
    if (selectedDate != null) {
      invoices = data.where((inv) {
        // 👉 parse string -> DateTime
        final d = DateTime.parse(inv['date']);

        // 👉 so sánh ngày/tháng/năm
        return d.year == selectedDate!.year &&
            d.month == selectedDate!.month &&
            d.day == selectedDate!.day;
      }).toList();
    } else {
      // 👉 nếu không filter → lấy tất cả
      invoices = data;
    }

    setState(() {}); // 👉 cập nhật UI
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= SHOW DETAIL =================
  Future<void> showInvoiceDetail(int invoiceId) async {
    // 👉 lấy chi tiết hóa đơn
    final details = await DBHelper.getInvoiceDetails(invoiceId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Hóa đơn #$invoiceId"),

        content: SizedBox(
          width: double.maxFinite,

          child: ListView.builder(
            shrinkWrap: true,
            itemCount: details.length,

            itemBuilder: (context, index) {
              final d = details[index];

              return ListTile(
                title: Text(d['productName']),

                subtitle: Text(
                  "${d['quantity']} x ${format.format(d['price'])}",
                ),

                trailing: Text(
                  format.format(d['quantity'] * d['price']),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hoá đơn"),

        // 👉 thêm icon lịch ở góc phải
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),

            onPressed: () async {
              // 👉 mở popup chọn ngày
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(), // 👉 ngày mặc định
                firstDate: DateTime(2020), // 👉 giới hạn dưới
                lastDate: DateTime(2100), // 👉 giới hạn trên
              );

              // 👉 nếu user có chọn ngày
              if (picked != null) {
                selectedDate = picked; // 👉 lưu lại ngày
                loadData(); // 👉 reload list theo ngày
              }
            },
          ),

          // 👉 BONUS: nút xoá filter (rất nên có)
          IconButton(
            icon: const Icon(Icons.clear),

            onPressed: () {
              selectedDate = null; // 👉 bỏ filter
              loadData(); // 👉 load lại full
            },
          ),
        ],
      ),
      body: invoices.isEmpty
          ? const Center(child: Text("Chưa có hóa đơn"))
          : Column(
              children: [
                // 👉 HIỂN THỊ NGÀY ĐANG LỌC
                if (selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "Đang lọc: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // 👉 DANH SÁCH HOÁ ĐƠN
                Expanded(
                  child: ListView.builder(
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          onTap: () => showInvoiceDetail(invoice['invoiceId']),
                          title: Text(
                            "Hóa đơn #${invoice['invoiceId']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Ngày: ${invoice['date']}"),
                          // ================= TRAILING (TIỀN + XOÁ) =================
                          trailing: Row(
                            mainAxisSize: MainAxisSize
                                .min, // 👉 tránh chiếm full chiều ngang

                            children: [
                              // ===== HIỂN THỊ TIỀN =====
                              Text(
                                format.format(
                                  invoice['total'],
                                ), // 👉 format tiền VN
                                style: const TextStyle(
                                  color: Colors.green, // 👉 màu xanh = tiền
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // ===== NÚT XOÁ =====
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),

                                onPressed: () async {
                                  // 👉 HIỆN POPUP XÁC NHẬN (TRÁNH XOÁ NHẦM)
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Xác nhận"),
                                      content: const Text(
                                        "Bạn có chắc muốn xoá hoá đơn này?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Huỷ"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Xoá"),
                                        ),
                                      ],
                                    ),
                                  );

                                  // 👉 nếu user bấm "Xoá"
                                  if (confirm == true) {
                                    // 👉 gọi DB xoá hoá đơn + chi tiết
                                    await DBHelper.deleteInvoice(
                                      invoice['invoiceId'],
                                    );

                                    // 👉 reload lại danh sách sau khi xoá
                                    loadData();

                                    // 👉 thông báo nhỏ cho user
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Đã xoá hoá đơn"),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../database/db_helper.dart'; // 👉 gọi database SQLite
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

// 👉 StatefulWidget: vì dữ liệu thay đổi liên tục (số lượng, tổng tiền)
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // 👉 quản lý TextField để reset sau khi thanh toán
  Map<int, TextEditingController> controllers = {};
  // 👉 danh sách sản phẩm lấy từ database
  List<Map<String, dynamic>> products = [];

  // 👉 giỏ hàng (cart)
  // key = productId, value = số lượng
  Map<int, int> cart = {};

  // 👉 tổng tiền hóa đơn
  double total = 0;

  // 👉 hàm lưu hoá đơn
  // ================= HÀM THANH TOÁN =================
  Future<void> saveInvoice() async {
    // 👉 Loại bỏ sản phẩm có số lượng <= 0 (tránh dữ liệu rác)
    cart.removeWhere((key, value) => value <= 0);

    // 👉 Kiểm tra giỏ hàng có hợp lệ không
    if (cart.isEmpty || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chưa có sản phẩm để thanh toán")),
      );
      return; // 👉 dừng nếu không hợp lệ
    }

    // ================= KIỂM TRA TỒN KHO =================
    // 👉 Duyệt từng sản phẩm trong giỏ hàng
    for (var item in cart.entries) {
      // 👉 Tìm sản phẩm tương ứng trong danh sách
      final product = products.firstWhere(
        (p) => p['productId'] == item.key,
        orElse: () => {}, // 👉 tránh crash nếu không tìm thấy
      );

      // 👉 nếu không tìm thấy sản phẩm thì bỏ qua
      if (product.isEmpty) continue;

      // 👉 lấy số lượng tồn kho hiện tại
      int stock = product['stock'] ?? 0;

      // 👉 nếu số lượng mua > tồn kho → báo lỗi
      if (item.value > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sản phẩm ${product['name']} không đủ hàng (còn $stock)",
            ),
          ),
        );
        return; // 👉 dừng thanh toán
      }
    }

    // ================= LƯU HÓA ĐƠN =================
    // 👉 thêm hóa đơn vào bảng invoices
    int invoiceId = await DBHelper.insertInvoice({
      'date': DateTime.now().toString(), // 👉 ngày hiện tại
      'total': total, // 👉 tổng tiền
      'isSynced': 0, // 👉 chưa sync Firebase
    });

    // 👉 đồng bộ hóa đơn lên Firebase (nếu có login)
    await SyncService.syncInvoices();
    await DBHelper.updateMonthlyRevenue(total);
    // ================= LƯU CHI TIẾT + TRỪ KHO =================
    // 👉 duyệt từng sản phẩm trong giỏ hàng
    for (var item in cart.entries) {
      final product = products.firstWhere(
        (p) => p['productId'] == item.key,
        orElse: () => {},
      );

      if (product.isEmpty) continue;

      // 👉 tồn kho hiện tại
      int currentStock = product['stock'] ?? 0;

      // 👉 tính tồn kho mới sau khi bán
      int newStock = currentStock - item.value;

      // ================= LƯU CHI TIẾT HÓA ĐƠN =================
      await DBHelper.insertInvoiceDetail({
        'invoiceId': invoiceId, // 👉 liên kết với hóa đơn
        'productId': item.key, // 👉 id sản phẩm
        'productName': product['name'], // 👉 tên sản phẩm
        'quantity': item.value, // 👉 số lượng mua
        'price': product['price'], // 👉 giá tại thời điểm bán
      });

      // ================= TRỪ TỒN KHO =================
      // 👉 cập nhật lại số lượng sản phẩm trong DB
      await DBHelper.updateProductStock(item.key, newStock);
    }

    // 👉 kiểm tra widget còn tồn tại (tránh crash khi async)
    if (!mounted) return;

    // ================= RESET GIỎ HÀNG =================
    cart.clear(); // 👉 xoá toàn bộ giỏ hàng
    total = 0; // 👉 reset tổng tiền

    // 👉 reset toàn bộ ô nhập số lượng
    controllers.forEach((key, c) => c.clear());

    // 👉 cập nhật lại UI
    setState(() {});

    // ================= THÔNG BÁO =================
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Thanh toán thành công")));

    // 👉 reload lại danh sách sản phẩm (để cập nhật tồn kho mới)
    loadData();
  }

  // 👉 load dữ liệu từ database
  void loadData() async {
    products = await DBHelper.getProducts(); // lấy toàn bộ sản phẩm
    setState(() {}); // cập nhật UI
  }

  // 👉 cập nhật số lượng khi user nhập
  void updateQuantity(int productId, double price, int value) {
    // 👉 lưu số lượng vào cart
    // 👉 nếu user nhập <= 0 → xoá khỏi giỏ hàng
    if (value <= 0) {
      cart.remove(productId);
    } else {
      cart[productId] = value;
    }

    // 👉 reset tổng tiền để tính lại từ đầu
    total = 0;

    // 👉 duyệt toàn bộ giỏ hàng để tính lại tổng tiền
    cart.forEach((id, qty) {
      var product = products.firstWhere(
        (p) => p['productId'] == id,
        orElse: () => {}, // 👉 tránh crash nếu lỗi data
      );

      if (product.isEmpty) return;

      // 👉 tính tiền = giá * số lượng
      total += ((product['price'] as num).toDouble() * qty);
    });

    // 👉 cập nhật UI
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadData(); // 👉 chạy khi mở màn hình
  }

  //khai báo format tiền
  final format = NumberFormat("#,###", "vi_VN");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 👉 tiêu đề màn hình
      appBar: AppBar(title: const Text("Bán hàng")),

      body: Column(
        children: [
          // 👉 danh sách sản phẩm
          Expanded(
            child: ListView.builder(
              itemCount: products.length, // số lượng item

              itemBuilder: (context, index) {
                var p = products[index]; // 👉 lấy từng sản phẩm

                return Card(
                  // 👉 bo góc card (giao diện modern 2026)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  // 👉 nội dung card
                  child: ListTile(
                    // 👉 tên sản phẩm
                    title: Text(p['name']),

                    // 👉 giá sản phẩm
                    subtitle: Text(
                      "Giá: ${format.format((p['price'] as num).toDouble())} đ\n"
                      "Tồn: ${p['stock']}",
                      style: const TextStyle(height: 1.4),
                    ),

                    // 👉 phần bên phải (ô nhập số lượng)
                    trailing: SizedBox(
                      width: 80, // 👉 giới hạn chiều rộng ô input

                      child: TextField(
                        controller: controllers.putIfAbsent(
                          p['productId'],
                          () => TextEditingController(),
                        ),
                        textAlign: TextAlign.center, // 👉 căn giữa số
                        keyboardType:
                            TextInputType.number, // 👉 chỉ cho nhập số
                        // 👉 style ô input
                        decoration: InputDecoration(
                          hintText: "SL", // 👉 SL = số lượng
                          // 👉 viền bo tròn đẹp hơn
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        // 👉 khi user nhập số lượng
                        onChanged: (value) {
                          // 👉 nếu rỗng thì coi như 0
                          if (value.isEmpty) {
                            updateQuantity(p['productId'], p['price'], 0);
                            return;
                          }

                          // 👉 parse số
                          int qty = int.tryParse(value) ?? 0;

                          // 👉 chặn số âm (phòng trường hợp bypass)
                          if (qty < 0) qty = 0;

                          // 👉 giới hạn số lượng tối đa
                          if (qty > 999) {
                            qty = 999;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Tối đa 999 sản phẩm"),
                              ),
                            );
                          }

                          updateQuantity(p['productId'], p['price'], qty);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 👉 hiển thị tổng tiền
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Tổng tiền: ${format.format(total)} đ",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          // 👉 🔥 NÚT THANH TOÁN ĐẶT Ở ĐÂY
          Padding(
            padding: const EdgeInsets.all(12),

            child: SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: cart.isEmpty ? null : saveInvoice,
                // onPressed: saveInvoice,
                child: const Text("Thanh toán"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👉 giải phóng controller khi màn hình bị huỷ (tránh memory leak)
  @override
  void dispose() {
    for (var c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
/** 🔥 CHÚ THÍCH QUAN TRỌNG (để bạn hiểu sâu)
🧠 1. cart
Map<int, int> cart = {};

👉 dạng:

{1: 2, 3: 5}
sản phẩm id = 1 → mua 2 cái
sản phẩm id = 3 → mua 5 cái
🧠 2. updateQuantity()

👉 đây là trái tim của màn bán hàng

nhập số lượng → lưu vào cart
tính lại toàn bộ tổng tiền
🧠 3. vì sao phải loop lại?
cart.forEach(...)

👉 vì mỗi lần user nhập:

không biết trước tổng
phải tính lại từ đầu
⚠️ BUG TIỀM ẨN (mình fix luôn cho bạn)
❌ nếu user xoá số → sẽ bị lỗi

👉 sửa lại:

int qty = int.tryParse(value) ?? 0;

if (qty <= 0) {
  cart.remove(p['productId']); // 👉 xoá khỏi giỏ
} else {
  cart[p['productId']] = qty;
}
🚀 BONUS (xịn hơn bài đồ án)
👉 hiển thị tổng đẹp hơn:
import 'package:intl/intl.dart';

final format = NumberFormat("#,###", "vi_VN");

Text(
  "Tổng: ${format.format(total)} đ",
)
🔥 NÚT CHUYỂN MÀN (có chú thích)
appBar: AppBar(
  title: const Text('Sản phẩm'),

  actions: [
    IconButton(
      icon: const Icon(Icons.shopping_cart), // 👉 icon giỏ hàng

      onPressed: () {
        Navigator.push(
          context,

          // 👉 chuyển sang màn bán hàng
          MaterialPageRoute(
            builder: (_) => const SalesScreen(),
          ),
        );
      },
    )
  ],
),
*/ 
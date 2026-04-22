import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

// 👉 StatefulWidget: màn có thay đổi dữ liệu
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  // 👉 controller input
  final TextEditingController edtName = TextEditingController();
  final TextEditingController edtPrice = TextEditingController();

  // 👉 list sản phẩm
  List<Map<String, dynamic>> products = [];

  // 👉 load dữ liệu từ DB
  void loadData() async {
    products = await DBHelper.getProducts();
    setState(() {});
  }

  // 👉 thêm sản phẩm
  void addProduct() async {
    // ❗ kiểm tra input
    if (edtName.text.isEmpty || edtPrice.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nhập đầy đủ dữ liệu")));
      return;
    }

    double price = double.tryParse(edtPrice.text) ?? 0;

    // ❗ không cho giá <= 0
    if (price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Giá phải > 0")));
      return;
    }

    await DBHelper.insertProduct({
      "productId": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": edtName.text,
      "price": price,
      "stock": 0,
      "isActive": 1,
      "isSynced": 0,
    });
    await SyncService.syncProducts();

    // 👉 clear input
    edtName.clear();
    edtPrice.clear();

    loadData();
  }

  // 👉 xoá sản phẩm
  void deleteProduct(String id) async {
    await DBHelper.deleteProduct(id);
    loadData();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // 👉 input tên
            TextField(
              controller: edtName,
              decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
            ),

            // 👉 input giá
            TextField(
              controller: edtPrice,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá'),
            ),

            const SizedBox(height: 10),

            // 👉 nút thêm
            ElevatedButton(
              onPressed: addProduct,
              child: const Text('Thêm sản phẩm'),
            ),

            const SizedBox(height: 10),

            // 👉 list sản phẩm
            Expanded(
              child: ListView.builder(
                itemCount: products.length,

                itemBuilder: (context, index) {
                  var product = products[index];
                  final format = NumberFormat("#,###", "vi_VN");

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 3,

                    child: ListTile(
                      // 👉 tên
                      title: Text(
                        product['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      // 👉 giá (không còn .0)
                      subtitle: Text(
                        "Giá: ${format.format(product['price'] ?? 0)} đ",
                        style: const TextStyle(color: Colors.green),
                      ),

                      // 👉 nút xoá
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),

                        onPressed: () {
                          // 👉 confirm trước khi xoá (xịn hơn)
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Xác nhận"),
                              content: const Text("Bạn muốn xoá sản phẩm?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Huỷ"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteProduct(
                                      product['productId'].toString(),
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Xoá"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

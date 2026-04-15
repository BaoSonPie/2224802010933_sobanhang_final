import 'package:flutter/material.dart';
import 'package:sobanhang/services/sync_service.dart';
// 👉 thư viện UI Flutter
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../database/db_helper.dart';
// 👉 gọi database SQLite để lưu sản phẩm

// ================= DIALOG =================
class AddProductDialog extends StatefulWidget {
  // 👉 callback để reload lại Home sau khi thêm
  final VoidCallback onAdd;

  const AddProductDialog({super.key, required this.onAdd});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  // ================= CONTROLLER =================

  // 👉 nhập tên sản phẩm
  final TextEditingController nameController = TextEditingController();

  // 👉 nhập giá
  final TextEditingController priceController = TextEditingController();

  // 👉 nhập tồn kho (bonus cho bạn luôn)
  final TextEditingController stockController = TextEditingController();
  // 👉 nhập link ảnh
  final TextEditingController imageController = TextEditingController();
  // ================= ẢNH =================

  // 👉 lưu ảnh user chọn (file local)
  File? selectedImage;

  // 👉 object để gọi camera / gallery
  final ImagePicker picker = ImagePicker();
  // ================= CHỌN ẢNH =================
  Future<void> pickImage(ImageSource source) async {
    // 👉 mở camera hoặc thư viện
    final picked = await picker.pickImage(source: source);

    // 👉 nếu user có chọn ảnh
    if (picked != null) {
      setState(() {
        // 👉 lưu lại đường dẫn ảnh
        selectedImage = File(picked.path);
      });
    }
  }

  // ================= HÀM THÊM =================
  void addProduct() async {
    // 👉 kiểm tra rỗng
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    // 👉 parse dữ liệu
    double price = double.tryParse(priceController.text) ?? 0;
    int stock = int.tryParse(stockController.text) ?? 0;

    // 👉 validate
    if (price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Giá phải > 0")));
      return;
    }

    if (stock < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tồn kho không hợp lệ")));
      return;
    }

    // ================= LƯU DATABASE =================
    await DBHelper.insertProduct({
      "name": nameController.text,
      "price": price,
      "stock": stock,
      // 👉 lưu đường dẫn ảnh (nếu chưa chọn thì để rỗng)
      "image": selectedImage?.path ?? "",
      "isActive": 1, // 👉 còn bán
      "isSynced": 0, // 👉 chưa sync Firebase
    });

    await SyncService.syncProducts(); // 👉 reload lại Home
    widget.onAdd();

    // 👉 đóng dialog
    Navigator.pop(context);

    // 👉 thông báo thành công
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Thêm sản phẩm thành công")));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // 👉 tiêu đề
      title: const Text("Thêm sản phẩm"),

      // 👉 nội dung
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== TÊN =====
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Tên sản phẩm",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ===== GIÁ =====
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Giá",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ===== TỒN KHO =====
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Tồn kho",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // ================= ẢNH =================
            Column(
              children: [
                // 👉 HIỂN THỊ ẢNH ĐÃ CHỌN
                selectedImage != null
                    ? Image.file(selectedImage!, height: 120)
                    : const Icon(Icons.image, size: 80),

                const SizedBox(height: 10),

                // 👉 NÚT CHỌN ẢNH
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // ===== CHỌN TỪ THƯ VIỆN =====
                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text("Thư viện"),
                    ),

                    // ===== CHỤP ẢNH =====
                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      // ================= BUTTON =================
      actions: [
        // 👉 huỷ
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Huỷ"),
        ),

        // 👉 thêm
        ElevatedButton(onPressed: addProduct, child: const Text("Thêm")),
      ],
    );
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    // 👉 giải phóng bộ nhớ (rất quan trọng)
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }
}

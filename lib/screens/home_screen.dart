import 'package:flutter/material.dart';
import 'package:sobanhang/services/sync_service.dart';
// 👉 UI Flutter

import '../database/db_helper.dart';
// 👉 SQLite

import 'add_product_dialog.dart';
// 👉 dialog thêm sản phẩm

import 'sales_screen.dart';
import 'invoice_screen.dart';
import 'statistic_screen.dart';
// 👉 các màn khác

import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 👉 login Google
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ================= BIẾN =================
  List<Map<String, dynamic>> products = [];
  bool isLoading = false;
  // ================= SEARCH =================
  String keyword = ""; // 👉 từ khoá tìm kiếm
  final auth = AuthService();
  User? user;
  final format = NumberFormat("#,###", "vi_VN");
  int selectedIndex = 0; // 👉 dùng cho highlight navbar

  // ================= LOAD DATA =================
  void loadProducts() async {
    products = await DBHelper.getProducts();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      SyncService.loadProductsFromFirebase().then((_) {
        loadProducts();
      });
    } else {
      loadProducts();
    }
  }

  // ================= NAV ITEM =================
  Widget _navItem(IconData icon, int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        // 👉 CHỈ đổi index (KHÔNG push màn)
        setState(() => selectedIndex = index);
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        padding: const EdgeInsets.all(10),

        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.15)
              : Colors.transparent,

          borderRadius: BorderRadius.circular(12),
        ),

        child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================= APPBAR =================
      appBar: AppBar(
        title: const Text("Sổ bán hàng"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
      ),

      // ================= BODY (UI NÂNG CẤP - KHÔNG ĐỔI LOGIC) =================
      body: selectedIndex == 0
          ? Container(
              // 👉 nền gradient cho app (bớt basic)
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xfff8fafc), // trắng xám
                    Color(0xffe2e8f0), // xám nhẹ
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),

              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      children: [
                        // ================= SEARCH =================
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Tìm sản phẩm...",
                            prefixIcon: const Icon(Icons.search),

                            // 👉 nền trắng cho đẹp
                            filled: true,
                            fillColor: Colors.white,

                            // 👉 bo góc đẹp hơn
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              keyword = value.toLowerCase();
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // ================= LIST =================
                        Expanded(
                          child: Container(
                            // 👉 làm nền mờ phía sau list
                            padding: const EdgeInsets.all(8),

                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: products.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          size: 70,
                                          color: Colors.white, // 👉 đổi màu
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "Chưa có sản phẩm",
                                          style: TextStyle(
                                            color: Colors.white, // 👉 đổi màu
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Builder(
                                    builder: (context) {
                                      final filtered = products.where((p) {
                                        return (p['name'] ?? "")
                                            .toLowerCase()
                                            .contains(keyword);
                                      }).toList();

                                      return GridView.builder(
                                        itemCount: filtered.length,
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                            ),
                                        itemBuilder: (context, index) {
                                          final p = filtered[index];

                                          return GestureDetector(
                                            onTap: () {
                                              // 👉 GIỮ NGUYÊN LOGIC
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: Text(p['name']),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "Giá: ${format.format((p['price'] as num).toDouble())} đ",
                                                          ),
                                                          Text(
                                                            "Tồn kho: ${p['stock']}",
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },

                                            // ================= LONG PRESS (GIỮ NGUYÊN) =================
                                            onLongPress: () {
                                              // ================= CONTROLLER =================
                                              final nameController =
                                                  TextEditingController(
                                                    text: p['name'],
                                                  );
                                              final priceController =
                                                  TextEditingController(
                                                    text: p['price'].toString(),
                                                  );
                                              final stockController =
                                                  TextEditingController(
                                                    text: p['stock'].toString(),
                                                  );

                                              // ================= ẢNH =================
                                              File? selectedImage;
                                              final picker = ImagePicker();

                                              // ================= DIALOG =================
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                    "Chỉnh sửa sản phẩm",
                                                  ),

                                                  // ================= FORM =================
                                                  content: StatefulBuilder(
                                                    builder: (context, setStateDialog) {
                                                      return SingleChildScrollView(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            // ===== TÊN =====
                                                            TextField(
                                                              controller:
                                                                  nameController,
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        "Tên",
                                                                  ),
                                                            ),

                                                            // ===== GIÁ =====
                                                            TextField(
                                                              controller:
                                                                  priceController,
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        "Giá",
                                                                  ),
                                                            ),

                                                            // ===== TỒN =====
                                                            TextField(
                                                              controller:
                                                                  stockController,
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        "Tồn kho",
                                                                  ),
                                                            ),

                                                            const SizedBox(
                                                              height: 10,
                                                            ),

                                                            // ================= ẢNH =================
                                                            selectedImage !=
                                                                    null
                                                                ? Image.file(
                                                                    selectedImage!,
                                                                    height: 100,
                                                                  )
                                                                : (p['image'] !=
                                                                          null &&
                                                                      p['image'] !=
                                                                          "")
                                                                ? Image.file(
                                                                    File(
                                                                      p['image'],
                                                                    ),
                                                                    height: 100,
                                                                  )
                                                                : const Icon(
                                                                    Icons.image,
                                                                    size: 80,
                                                                  ),

                                                            const SizedBox(
                                                              height: 10,
                                                            ),

                                                            // ================= CHỌN ẢNH =================
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceAround,
                                                              children: [
                                                                ElevatedButton.icon(
                                                                  onPressed: () async {
                                                                    final picked =
                                                                        await picker.pickImage(
                                                                          source:
                                                                              ImageSource.gallery,
                                                                        );

                                                                    if (picked !=
                                                                        null) {
                                                                      setStateDialog(() {
                                                                        selectedImage = File(
                                                                          picked
                                                                              .path,
                                                                        );
                                                                      });
                                                                    }
                                                                  },
                                                                  icon: const Icon(
                                                                    Icons.photo,
                                                                  ),
                                                                  label: const Text(
                                                                    "Thư viện",
                                                                  ),
                                                                ),

                                                                ElevatedButton.icon(
                                                                  onPressed: () async {
                                                                    final picked =
                                                                        await picker.pickImage(
                                                                          source:
                                                                              ImageSource.camera,
                                                                        );

                                                                    if (picked !=
                                                                        null) {
                                                                      setStateDialog(() {
                                                                        selectedImage = File(
                                                                          picked
                                                                              .path,
                                                                        );
                                                                      });
                                                                    }
                                                                  },
                                                                  icon: const Icon(
                                                                    Icons
                                                                        .camera_alt,
                                                                  ),
                                                                  label:
                                                                      const Text(
                                                                        "Camera",
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),

                                                  // ================= ACTION =================
                                                  actions: [
                                                    // ===== HUỶ =====
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text("Huỷ"),
                                                    ),

                                                    // ===== XOÁ =====
                                                    TextButton(
                                                      onPressed: () async {
                                                        await DBHelper.deleteProduct(
                                                          p['productId'],
                                                        );

                                                        loadProducts();
                                                        Navigator.pop(context);

                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              "Đã ngừng bán sản phẩm",
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: const Text(
                                                        "Xoá",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),

                                                    // ===== LƯU =====
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        await DBHelper.updateProduct(
                                                          p['productId'],
                                                          nameController.text,
                                                          double.tryParse(
                                                                priceController
                                                                    .text,
                                                              ) ??
                                                              0,
                                                          int.tryParse(
                                                                stockController
                                                                    .text,
                                                              ) ??
                                                              0,
                                                          selectedImage?.path ??
                                                              p['image'] ??
                                                              "",
                                                        );

                                                        loadProducts();
                                                        Navigator.pop(context);

                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              "Đã cập nhật sản phẩm",
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: const Text("Lưu"),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },

                                            // ================= CARD ĐẸP =================
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),

                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),

                                                // 👉 gradient nhẹ
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white,
                                                    Colors.blue.withOpacity(
                                                      0.1,
                                                    ),
                                                  ],
                                                ),

                                                // 👉 đổ bóng
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),

                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),

                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    // ================= ẢNH =================
                                                    (p['image'] != null &&
                                                            p['image'] != "" &&
                                                            File(
                                                              p['image'],
                                                            ).existsSync())
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            child: Image.file(
                                                              File(p['image']),
                                                              height: 70,
                                                              width: 70,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )
                                                        : const Icon(
                                                            Icons.inventory,
                                                            size: 40,
                                                            color: Colors.blue,
                                                          ),

                                                    const SizedBox(height: 10),

                                                    // ================= TÊN =================
                                                    Text(
                                                      p['name'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),

                                                    // ================= GIÁ =================
                                                    Text(
                                                      "${format.format((p['price'] as num).toDouble())} đ",
                                                      style: const TextStyle(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),

                                                    // ================= TỒN =================
                                                    Text(
                                                      "Tồn: ${p['stock']}",
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ================= LOADING GIỮ NGUYÊN =================
                  if (isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            )
          // 👉 TAB KHÁC
          : (selectedIndex == 1
                ? const SalesScreen()
                : selectedIndex == 2
                ? const InvoiceScreen()
                : const StatisticsScreen()),

      // ================= NÚT + =================
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddProductDialog(onAdd: loadProducts),
          );
        },
        child: const Icon(Icons.add),
      ),

      // ================= NAVBAR CUSTOM =================
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          // ===== THANH NAV =====
          Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.inventory, 0),
                _navItem(Icons.point_of_sale, 1),

                const SizedBox(width: 60),

                _navItem(Icons.receipt, 2),
                _navItem(Icons.bar_chart, 3),
              ],
            ),
          ),

          // ===== NÚT LOGIN GIỮA =====
          Positioned(
            bottom: 15,
            left: MediaQuery.of(context).size.width / 2 - 30,

            child: GestureDetector(
              onTap: () async {
                if (user == null) {
                  setState(() => isLoading = true);

                  final u = await auth.signInWithGoogle();

                  if (u != null) {
                    await SyncService.loadProductsFromFirebase(); // 🔥 kéo về
                  }
                  setState(() {
                    user = u;
                    isLoading = false;
                  });
                } else {
                  await auth.signOut();
                  setState(() => user = null);
                }
              },

              child: Container(
                width: 60,
                height: 60,

                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Center(
                  child: user == null
                      ? const Icon(Icons.login, color: Colors.white)
                      : CircleAvatar(
                          backgroundImage: NetworkImage(user!.photoURL ?? ""),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart'; // 👉 Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart'; // 👉 lấy user login
import '../database/db_helper.dart'; // 👉 SQLite của bạn
import 'dart:developer' as dev;

class SyncService {
  // ================= PRODUCT =================

  // 👉 ĐẨY dữ liệu từ SQLite lên Firebase
  static Future<void> syncProducts() async {
    final db = await DBHelper.getDB(); // 👉 mở database

    // 👉 lấy danh sách chưa sync
    final data = await db.query(
      'products',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    final user = FirebaseAuth.instance.currentUser; // 👉 user hiện tại
    if (user == null) return; // 👉 chưa login thì thôi

    for (var p in data) {
      // 👉 đẩy lên Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('products')
          .add({'name': p['name'], 'price': p['price'], 'image': p['image']});

      // 👉 đánh dấu đã sync
      await db.update(
        'products',
        {'isSynced': 1},
        where: 'productId = ?',
        whereArgs: [p['productId']],
      );
    }
  }

  // 👉 LOAD từ Firebase về SQLite
  static Future<void> loadProductsFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = await DBHelper.getDB();

    // 👉 lấy toàn bộ product trên cloud
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      // 👉 lấy dữ liệu từng product từ Firebase

      // 👉 chuẩn hoá tên sản phẩm
      // tránh lỗi trùng: "Coca", "coca", " COCA "
      final name = (data['name'] as String).trim().toLowerCase();

      // 👉 kiểm tra sản phẩm đã tồn tại trong SQLite chưa
      // dùng LOWER(name) để so sánh không phân biệt hoa/thường
      final exist = await db.query(
        'products',
        where: 'LOWER(name) = ?',
        whereArgs: [name],
      );

      // 👉 nếu sản phẩm đã tồn tại → cập nhật lại thông tin
      if (exist.isNotEmpty) {
        await db.update(
          'products',
          {
            'price': data['price'],

            // 👉 cập nhật giá mới từ Firebase
            'isActive': 1,

            // 👉 đảm bảo sản phẩm đang được bán
            'isSynced': 1,
            // 👉 đánh dấu đã sync để tránh sync lại
          },
          where: 'LOWER(name) = ?',

          // 👉 update đúng sản phẩm theo tên đã chuẩn hoá
          whereArgs: [name],
        );
      }
      // 👉 nếu sản phẩm chưa tồn tại → thêm mới vào SQLite
      else {
        await db.insert('products', {
          'name': data['name'],

          // 👉 tên sản phẩm từ Firebase
          'price': data['price'],

          // 👉 giá sản phẩm
          'stock': 0,

          // 👉 mặc định chưa quản lý tồn kho
          'isActive': 1,

          // 👉 trạng thái đang bán
          'isSynced': 1,
          // 👉 đánh dấu đã sync từ Firebase
        });
      }
    }
  }

  // ================= INVOICE =================

  // 👉 ĐẨY hóa đơn lên Firebase
  static Future<void> syncInvoices() async {
    final db = await DBHelper.getDB();

    // 👉 lấy invoice chưa sync
    final invoices = await db.query(
      'invoices',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var inv in invoices) {
      try {
        // 👉 tạo invoice trên Firebase
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('invoices')
            .add({'date': inv['date'], 'total': inv['total']});

        // 👉 lấy detail từ SQLite
        final details = await db.query(
          'invoice_details',
          where: 'invoiceId = ?',
          whereArgs: [inv['invoiceId']],
        );

        // 👉 nếu KHÔNG có detail → skip (tránh rác data)
        if (details.isEmpty) continue;

        // 👉 push từng detail lên Firebase
        for (var d in details) {
          await docRef.collection('details').add({
            'productName': d['productName'],
            'quantity': d['quantity'],
            'price': d['price'],
          });
        }

        // 👉 đánh dấu đã sync (CHỈ khi thành công)
        await db.update(
          'invoices',
          {'isSynced': 1},
          where: 'invoiceId = ?',
          whereArgs: [inv['invoiceId']],
        );
      } catch (e) {
        // 👉 nếu lỗi thì KHÔNG set isSynced
        // 👉 để lần sau sync lại
        dev.log("❌ Sync invoice lỗi: $e");
      }
    }
  }

  // 👉 LOAD hóa đơn từ Firebase về SQLite
  static Future<void> loadInvoicesFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = await DBHelper.getDB();

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final exist = await db.query(
        'invoices',
        where: 'date = ? AND total = ?',
        whereArgs: [data['date'], data['total']],
      );

      if (exist.isEmpty) {
        await db.insert('invoices', {
          'date': data['date'],
          'total': data['total'],
          'isSynced': 1,
        });
      }
    }
  }
}

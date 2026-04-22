// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/db_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SyncService {
  static final _firestore = FirebaseFirestore.instance;

  // =========================================================
  // ======================= PRODUCT ==========================
  // =========================================================

  // 🔥 LOCAL -> FIREBASE
  static Future<void> syncProducts() async {
    final db = await DBHelper.getDB();

    // 👉 lấy sản phẩm chưa sync
    final data = await db.query(
      'products',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var p in data) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('products')
          .doc(p['productId'].toString()) // 🔥 ID CHUNG
          .set({
            'productId': p['productId'],
            'name': p['name'],
            'price': p['price'],
            'stock': p['stock'],
            'image': p['image'],
            'isActive': p['isActive'],
            'updatedAt': p['updatedAt'],
            'deleted': p['deleted'],
          });

      // 👉 đánh dấu đã sync
      await db.update(
        'products',
        {'isSynced': 1},
        where: 'productId = ?',
        whereArgs: [p['productId'].toString()],
      );
    }
  }

  // 🔥 FIREBASE -> LOCAL
  static Future<void> loadProductsFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = await DBHelper.getDB();

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['stock'] = data['stock'] ?? 0;
      data['price'] = data['price'] ?? 0;
      data['isActive'] = data['isActive'] ?? 1;
      data['deleted'] = data['deleted'] ?? 0;
      data['productId'] = doc.id;
      data['isActive'] = data['isActive'] ?? 1;
      data['deleted'] = data['deleted'] ?? 0;
      final local = await db.query(
        'products',
        where: 'productId = ?',
        whereArgs: [data['productId']?.toString() ?? ""],
      );

      if (local.isEmpty) {
        // 👉 chưa có → insert
        await db.insert('products', {...data, 'isSynced': 1});
      } else {
        String localTime = local.first['updatedAt']?.toString() ?? "";
        String cloudTime = data['updatedAt']?.toString() ?? "";

        // 👉 nếu cloud mới hơn → update
        if (cloudTime.compareTo(localTime) > 0) {
          await db.update(
            'products',
            {...data, 'isSynced': 1},
            where: 'productId = ?',
            whereArgs: [data['productId'].toString()],
          );
        }
      }
    }
  }

  // =========================================================
  // ======================= INVOICE ==========================
  // =========================================================

  // 🔥 LOCAL -> FIREBASE
  static Future<void> syncInvoices() async {
    final db = await DBHelper.getDB();

    final invoices = await db.query(
      'invoices',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var inv in invoices) {
      try {
        // 👉 push invoice
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('invoices')
            .doc(inv['invoiceId'].toString()); // 🔥 ID CHUNG

        await docRef.set({
          'invoiceId': inv['invoiceId'],
          'date': inv['date'],
          'total': inv['total'],
          'updatedAt': inv['updatedAt'],
        });

        // 👉 lấy detail từ SQLite
        final details = await db.query(
          'invoice_details',
          where: 'invoiceId = ?',
          whereArgs: [inv['invoiceId'].toString()],
        );

        // 👉 push từng detail
        for (var d in details) {
          await docRef
              .collection('details')
              .doc(d['detailId'].toString()) // 🔥 ID CHUNG
              .set({
                'detailId': d['detailId'],
                'productId': d['productId'],
                'productName': d['productName'],
                'quantity': d['quantity'],
                'price': d['price'],
              });
        }

        // 👉 đánh dấu đã sync
        await db.update(
          'invoices',
          {'isSynced': 1},
          where: 'invoiceId = ?',
          whereArgs: [inv['invoiceId'].toString()],
        );
      } catch (e) {
        // 👉 lỗi thì bỏ qua để sync lại sau
        print("❌ Sync invoice lỗi: $e");
      }
    }
  }

  // 🔥 FIREBASE -> LOCAL
  static Future<void> loadInvoicesFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = await DBHelper.getDB();

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['invoiceId'] = doc.id;
      data['deleted'] = data['deleted'] ?? 0;
      data['isSynced'] = data['isSynced'] ?? 1;
      final local = await db.query(
        'invoices',
        where: 'invoiceId = ?',
        whereArgs: [data['invoiceId']],
      );

      if (local.isEmpty) {
        // 👉 insert invoice
        await db.insert('invoices', {...data, 'isSynced': 1});

        // 👉 load detail
        final detailsSnap = await doc.reference.collection('details').get();

        for (var d in detailsSnap.docs) {
          await db.insert('invoice_details', d.data());
        }
      }
    }
  }
}

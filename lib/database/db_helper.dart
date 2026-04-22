import 'package:sqflite/sqflite.dart'; // 👉 SQLite
import 'package:path/path.dart'; // 👉 xử lý đường dẫn

class DBHelper {
  static Database? _db; // 👉 biến lưu database

  // 👉 mở database
  static Future<Database> getDB() async {
    if (_db != null) return _db!; // 👉 nếu có rồi thì dùng lại

    _db = await openDatabase(
      join(await getDatabasesPath(), 'app.db'), // 👉 đường dẫn DB

      version: 1,

      onCreate: (db, version) async {
        // ================= CREATE TABLE PRODUCTS =================
        await db.execute('''
CREATE TABLE products(
  productId TEXT PRIMARY KEY, 
  name TEXT,                 
  price REAL,                  
  stock INTEGER,              
  image TEXT,                
  isActive INTEGER,          
  isSynced INTEGER DEFAULT 0,
  updatedAt TEXT,             
  deleted INTEGER DEFAULT 0   
)
''');
        // ===== TABLE INVOICES =====
        await db.execute('''
          CREATE TABLE invoices(
            invoiceId TEXT PRIMARY KEY,
            date TEXT,
            total REAL,
            isSynced INTEGER DEFAULT 0
          )
        ''');

        // ===== TABLE INVOICE DETAILS =====
        await db.execute('''
          CREATE TABLE invoice_details(
            detailId TEXT PRIMARY KEY, 
invoiceId TEXT,           
productId TEXT,            
            productName TEXT,
            quantity INTEGER,
            price REAL
          )
        ''');
        // MONTHLY REVENUE
        await db.execute('''
    CREATE TABLE monthly_revenue(
      revenueId INTEGER PRIMARY KEY AUTOINCREMENT,
      month INTEGER,
      year INTEGER,
      total REAL
    )
  ''');
      },
    );

    return _db!;
  }

  // ================= PRODUCT =================

  // 👉 thêm sản phẩm
  static Future<void> insertProduct(Map<String, dynamic> data) async {
    final db = await getDB();
    await db.insert('products', data);
  }

  // 👉 lấy danh sách sản phẩm
  // 👉 chỉ lấy sản phẩm còn bán
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await getDB();

    return await db.query('products', where: 'isActive = ?', whereArgs: [1]);
    // 👉 SELECT * FROM products
  }

  // 👉 ❗ SOFT DELETE (ngừng bán thay vì xoá)
  static Future<void> deleteProduct(String id) async {
    final db = await getDB();

    await db.update(
      'products',
      {'isActive': 0}, // 👉 0 = ngừng bán
      where: 'productId = ?',
      whereArgs: [id],
    );
  }
  // ================= INVOICE =================

  // 👉 lưu hóa đơn
  static Future<int> insertInvoice(Map<String, dynamic> data) async {
    final db = await getDB();
    return await db.insert('invoices', data);
  }

  // 👉 lưu chi tiết hóa đơn
  static Future<void> insertInvoiceDetail(Map<String, dynamic> data) async {
    final db = await getDB();
    await db.insert('invoice_details', data);
  }

  // 👉 lấy danh sách hóa đơn
  static Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await getDB();
    return db.query('invoices', orderBy: 'invoiceId DESC');
  }

  // 👉 lấy chi tiết hóa đơn theo id
  static Future<List<Map<String, dynamic>>> getInvoiceDetails(
    String invoiceId,
  ) async {
    final db = await getDB();
    return db.query(
      'invoice_details',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );
  }
  // ================= DELETE INVOICE =================

  // 👉 xoá hóa đơn + chi tiết
  static Future<void> deleteInvoice(String invoiceId) async {
    final db = await getDB();

    // 👉 xoá chi tiết trước
    await db.delete(
      'invoice_details',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );

    // 👉 xoá hóa đơn
    await db.delete('invoices', where: 'invoiceId = ?', whereArgs: [invoiceId]);
  }
  // ================= STATISTIC =================

  // 👉 tổng doanh thu
  static Future<double> getTotalRevenue() async {
    final db = await getDB();

    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM invoices',
    );

    // 👉 tránh null
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
  // ================= STATISTIC ADVANCED =================

  // 👉 LẤY DOANH THU THEO NGÀY
  // GROUP BY theo ngày (yyyy-mm-dd)
  static Future<List<Map<String, dynamic>>> getRevenueByDate() async {
    final db = await getDB(); // 👉 mở database

    return db.rawQuery('''
    SELECT date(date) as d, SUM(total) as total
    FROM invoices
    GROUP BY d
    ORDER BY d DESC
  ''');

    /**
   * 🔥 GIẢI THÍCH:
   * date(date): lấy phần ngày (bỏ giờ)
   * SUM(total): cộng tổng tiền trong ngày đó
   * GROUP BY d: gom theo từng ngày
   * ORDER BY: mới nhất lên trước
   */
  }

  // 👉 LẤY DOANH THU THEO THÁNG
  static Future<List<Map<String, dynamic>>> getRevenueByMonth() async {
    final db = await getDB();

    return db.rawQuery('''
    SELECT strftime('%Y-%m', date) as m, SUM(total) as total
    FROM invoices
    GROUP BY m
    ORDER BY m DESC
  ''');

    /**
   * 🔥 GIẢI THÍCH:
   * strftime('%Y-%m'): format thành "2026-04"
   * GROUP BY m: gom theo tháng
   */
  }
  // ================= CLEAR DATA =================

  // 👉 XÓA TOÀN BỘ DỮ LIỆU (dùng khi login/logout để tránh trộn user)
  static Future<void> clearAllData() async {
    final db = await getDB();

    // 👉 xóa bảng sản phẩm
    await db.delete('products');

    // 👉 xóa bảng hóa đơn
    await db.delete('invoices');

    // 👉 xóa bảng chi tiết hóa đơn
    await db.delete('invoice_details');
  }
  // ================= STOCK =================

  // 👉 trừ tồn kho sau khi bán
  static Future<void> updateProductStock(String productId, int newStock) async {
    final db = await getDB();

    await db.update(
      'products',
      {'stock': newStock},
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }
  // ================= MONTHLY REVENUE =================

  // 👉 tạo tháng mới nếu chưa có
  static Future<void> checkNewMonth() async {
    final db = await getDB();

    final now = DateTime.now();
    int month = now.month;
    int year = now.year;

    final result = await db.query(
      'monthly_revenue',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );

    if (result.isEmpty) {
      await db.insert('monthly_revenue', {
        'month': month,
        'year': year,
        'total': 0,
      });
    }
  }

  // 👉 cập nhật doanh thu tháng
  static Future<void> updateMonthlyRevenue(double amount) async {
    final db = await getDB();

    final now = DateTime.now();
    int month = now.month;
    int year = now.year;

    final result = await db.query(
      'monthly_revenue',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );

    if (result.isEmpty) {
      await db.insert('monthly_revenue', {
        'month': month,
        'year': year,
        'total': amount,
      });
    } else {
      double current = (result.first['total'] as num).toDouble();

      await db.update(
        'monthly_revenue',
        {'total': current + amount},
        where: 'month = ? AND year = ?',
        whereArgs: [month, year],
      );
    }
  }

  // 👉 lấy danh sách doanh thu tháng
  static Future<List<Map<String, dynamic>>> getMonthlyRevenue() async {
    final db = await getDB();

    return db.query('monthly_revenue', orderBy: 'year DESC, month DESC');
  }
  // ================= UPDATE PRODUCT =================

  // 👉 hàm cập nhật sản phẩm
  static Future<void> updateProduct(
    String id, // 👉 id sản phẩm cần sửa
    String name, // 👉 tên mới
    double price, // 👉 giá mới
    int stock,
    String image, // 👉 tồn kho mới
  ) async {
    final db = await getDB(); // 👉 mở database

    // 👉 update dữ liệu theo id
    await db.update(
      'products', // 👉 tên bảng

      {
        'name': name, // 👉 cập nhật tên
        'price': price, // 👉 cập nhật giá
        'stock': stock, // 👉 cập nhật tồn kho
        'image': image,
      },

      where: 'productId = ?', // 👉 điều kiện WHERE
      whereArgs: [id], // 👉 truyền id vào
    );
  }
}

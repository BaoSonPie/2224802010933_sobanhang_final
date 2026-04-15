import 'package:flutter/material.dart'; // 👉 thư viện UI Flutter
import 'package:sobanhang/database/db_helper.dart';
import 'package:sobanhang/screens/home_screen.dart'; //👉 gọi màn hình home
import 'package:firebase_core/firebase_core.dart';
// 👉 Thư viện để kết nối Firebase
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// 👉 File cấu hình Firebase (flutterfire tạo)
void main() async {
  // 👉 Đảm bảo Flutter đã khởi tạo xong trước khi chạy async
  WidgetsFlutterBinding.ensureInitialized();
  // // 🔥 XOÁ DATABASE CŨ (CHỈ CHẠY 1 LẦN)
  // await deleteDatabase(join(await getDatabasesPath(), 'app.db'));
  // 👉 Khởi tạo Firebase (BẮT BUỘC)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔥 thêm dòng này
  await DBHelper.checkNewMonth();
  debugPrint("🔥 Firebase đã kết nối thành công");

  // // 👉 TEST ghi dữ liệu lên Firebase
  // await FirebaseFirestore.instance.collection('test').add({
  //   'time': DateTime.now().toString(),
  // });

  debugPrint("🔥 Đã ghi dữ liệu test lên Firestore");
  // 👉 Chạy app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // 👉 constructor có key (chuẩn Flutter)

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sổ bán hàng', // 👉 tên app
      debugShowCheckedModeBanner: false, // 👉 tắt chữ debug
      theme: ThemeData(
        useMaterial3: true, // 🔥 quan trọng
        colorSchemeSeed: Colors.blue,
      ),
      home: HomeScreen(), // 👉 màn hình đầu tiên
    );
  }
}

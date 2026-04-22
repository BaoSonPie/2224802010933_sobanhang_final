import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ImageService {
  static Future<String> uploadImage(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = FirebaseStorage.instance.ref().child('products/$fileName.jpg');

    await ref.putFile(file);

    return await ref.getDownloadURL(); // 🔥 URL ảnh
  }
}

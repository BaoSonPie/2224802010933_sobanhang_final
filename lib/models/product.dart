class Product {
  String? productId;
  // 👉 id (tự tăng trong database)

  String name;
  // 👉 tên sản phẩm

  double price;
  // 👉 giá sản phẩm

  int stock;
  // 👉 số lượng tồn

  bool isActive;
  // 👉 còn bán hay không (true/false)
  String image;
  // 👉 constructor (hàm tạo object)
  Product({
    this.productId,
    required this.name,
    required this.price,
    required this.stock,
    required this.isActive,
    required this.image,
  });

  // 👉 chuyển object thành Map để lưu DB
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'stock': stock,
      'image': image,
      'isActive': isActive ? 1 : 0,
      // 👉 true = 1, false = 0
    };
  }

  // fromMap cho chuẩn
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['productId'],
      name: map['name'] ?? "",
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] ?? 0,
      isActive: map['isActive'] == 1,
      image: map['image'] ?? "", // 👉 QUAN TRỌNG
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class KitchenItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category; // 'fullmeals' or 'snacks'
  final DateTime createdAt;

  KitchenItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.createdAt,
  });

  factory KitchenItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return KitchenItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      category: data['category'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class KitchenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new kitchen item
  Future<bool> addKitchenItem(KitchenItem item) async {
    try {
      await _firestore.collection('kitchen_items').add(item.toMap());
      return true;
    } catch (e) {
      print('Error adding kitchen item: $e');
      return false;
    }
  }

  // Get all items by category
  Stream<List<KitchenItem>> getItemsByCategory(String category) {
    return _firestore
        .collection('kitchen_items')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KitchenItem.fromFirestore(doc))
              .toList(),
        );
  }

  // Delete an item
  Future<bool> deleteItem(String itemId) async {
    try {
      await _firestore.collection('kitchen_items').doc(itemId).delete();
      return true;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

  // Update an item
  Future<bool> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('kitchen_items').doc(itemId).update(updates);
      return true;
    } catch (e) {
      print('Error updating item: $e');
      return false;
    }
  }
}

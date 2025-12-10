import 'package:cloud_firestore/cloud_firestore.dart';

class Kitchen {
  final String id;
  final String name;
  final String description;
  final String ownerId; // Staff member who owns this kitchen
  final String ownerName;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, String>
  operatingHours; // e.g., {"monday": "9:00-17:00", "tuesday": "9:00-17:00"}

  Kitchen({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    this.operatingHours = const {},
  });

  factory Kitchen.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Kitchen(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      operatingHours: Map<String, String>.from(data['operatingHours'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'operatingHours': operatingHours,
    };
  }
}

class KitchenItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category; // 'fullmeals' or 'snacks'
  final String kitchenId; // Which kitchen this item belongs to
  final String ownerId; // For easy filtering
  final bool isAvailable;
  final DateTime createdAt;

  KitchenItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.kitchenId,
    required this.ownerId,
    this.isAvailable = true,
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
      kitchenId: data['kitchenId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
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
      'kitchenId': kitchenId,
      'ownerId': ownerId,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class VendorKitchenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kitchen Management
  Future<bool> createKitchen(Kitchen kitchen) async {
    try {
      await _firestore.collection('kitchens').add(kitchen.toMap());
      return true;
    } catch (e) {
      print('Error creating kitchen: $e');
      return false;
    }
  }

  Stream<List<Kitchen>> getKitchensByOwner(String ownerId) {
    return _firestore
        .collection('kitchens')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Kitchen.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Kitchen>> getAllKitchens() {
    return _firestore
        .collection('kitchens')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Kitchen.fromFirestore(doc)).toList(),
        );
  }

  Future<bool> updateKitchen(
    String kitchenId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('kitchens').doc(kitchenId).update(updates);
      return true;
    } catch (e) {
      print('Error updating kitchen: $e');
      return false;
    }
  }

  Future<bool> deleteKitchen(String kitchenId) async {
    try {
      // Soft delete by setting isActive to false
      await _firestore.collection('kitchens').doc(kitchenId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error deleting kitchen: $e');
      return false;
    }
  }

  // Kitchen Items Management
  Future<bool> addKitchenItem(KitchenItem item) async {
    try {
      await _firestore.collection('kitchen_items').add(item.toMap());
      return true;
    } catch (e) {
      print('Error adding kitchen item: $e');
      return false;
    }
  }

  Stream<List<KitchenItem>> getItemsByKitchen(String kitchenId) {
    return _firestore
        .collection('kitchen_items')
        .where('kitchenId', isEqualTo: kitchenId)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KitchenItem.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<KitchenItem>> getItemsByKitchenAndCategory(
    String kitchenId,
    String category,
  ) {
    return _firestore
        .collection('kitchen_items')
        .where('kitchenId', isEqualTo: kitchenId)
        .where('category', isEqualTo: category)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KitchenItem.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<KitchenItem>> getItemsByOwner(String ownerId) {
    return _firestore
        .collection('kitchen_items')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KitchenItem.fromFirestore(doc))
              .toList(),
        );
  }

  Future<bool> updateKitchenItem(
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('kitchen_items').doc(itemId).update(updates);
      return true;
    } catch (e) {
      print('Error updating kitchen item: $e');
      return false;
    }
  }

  Future<bool> deleteKitchenItem(String itemId) async {
    try {
      await _firestore.collection('kitchen_items').doc(itemId).delete();
      return true;
    } catch (e) {
      print('Error deleting kitchen item: $e');
      return false;
    }
  }

  // Get all items by category across all kitchens (for customer view)
  Stream<List<KitchenItem>> getAllItemsByCategory(String category) {
    return _firestore
        .collection('kitchen_items')
        .where('category', isEqualTo: category)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KitchenItem.fromFirestore(doc))
              .toList(),
        );
  }
}

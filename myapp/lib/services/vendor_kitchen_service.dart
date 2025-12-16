import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// Kitchen Model
// ============================================================================
// represents a vendor's kitchen/store in the system
// each staff member can own multiple kitchens with their own menus
// pickupLocations allows each seller to define custom pickup spots for customers
// ============================================================================
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
  final List<String> pickupLocations; // custom pickup locations set by seller

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
    this.pickupLocations = const [], // defaults to empty, seller adds their own
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
      // convert firestore list to List<String>
      pickupLocations: List<String>.from(data['pickupLocations'] ?? []),
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
      'pickupLocations': pickupLocations,
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

  // Orders
  Future<bool> createOrder(KitchenOrder order) async {
    try {
      await _firestore.collection('orders').add(order.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<KitchenOrder>> getOrdersByKitchen(String kitchenId) {
    return _firestore
        .collection('orders')
        .where('kitchenId', isEqualTo: kitchenId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KitchenOrder.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<KitchenOrder>> getOrdersForUser(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KitchenOrder.fromFirestore(doc))
              .toList(),
        );
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Kitchen Management
  Future<bool> createKitchen(Kitchen kitchen) async {
    try {
      await _firestore.collection('kitchens').add(kitchen.toMap());
      return true;
    } catch (e) {
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
      return false;
    }
  }

  // Kitchen Items Management
  Future<bool> addKitchenItem(KitchenItem item) async {
    try {
      await _firestore.collection('kitchen_items').add(item.toMap());
      return true;
    } catch (e) {
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

  // --------------------------------------------------------------------------
  // Pickup Locations Management
  // --------------------------------------------------------------------------
  // these methods let sellers manage their own custom pickup locations
  // customers will see these when checking out from a specific kitchen

  // adds a new pickup location to a kitchen's list
  Future<bool> addPickupLocation(String kitchenId, String location) async {
    try {
      await _firestore.collection('kitchens').doc(kitchenId).update({
        'pickupLocations': FieldValue.arrayUnion([location]),
      });
      return true;
    } catch (e) {
      print('Error adding pickup location: $e');
      return false;
    }
  }

  // removes a pickup location from a kitchen's list
  Future<bool> removePickupLocation(String kitchenId, String location) async {
    try {
      await _firestore.collection('kitchens').doc(kitchenId).update({
        'pickupLocations': FieldValue.arrayRemove([location]),
      });
      return true;
    } catch (e) {
      print('Error removing pickup location: $e');
      return false;
    }
  }

  // replaces all pickup locations (useful for reordering or bulk edit)
  Future<bool> updatePickupLocations(
    String kitchenId,
    List<String> locations,
  ) async {
    try {
      await _firestore.collection('kitchens').doc(kitchenId).update({
        'pickupLocations': locations,
      });
      return true;
    } catch (e) {
      print('Error updating pickup locations: $e');
      return false;
    }
  }
}

class KitchenOrder {
  KitchenOrder({
    required this.id,
    required this.kitchenId,
    required this.kitchenName,
    this.userId = '',
    required this.ownerId,
    required this.customerName,
    required this.pickupLocation,
    this.status = 'pending',
    required this.total,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final String kitchenId;
  final String kitchenName;
  final String userId;
  final String ownerId;
  final String customerName;
  final String pickupLocation;
  final String status;
  final double total;
  final List<KitchenOrderItem> items;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'kitchenId': kitchenId,
      'kitchenName': kitchenName,
      'userId': userId,
      'ownerId': ownerId,
      'customerName': customerName,
      'pickupLocation': pickupLocation,
      'status': status,
      'total': total,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory KitchenOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KitchenOrder(
      id: doc.id,
      kitchenId: data['kitchenId'] ?? '',
      kitchenName: data['kitchenName'] ?? '',
      userId: data['userId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      customerName: data['customerName'] ?? '',
      pickupLocation: data['pickupLocation'] ?? '',
      status: data['status'] ?? 'pending',
      total: (data['total'] ?? 0).toDouble(),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => KitchenOrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class KitchenOrderItem {
  KitchenOrderItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.qty,
    required this.category,
  });

  final String itemId;
  final String name;
  final double price;
  final int qty;
  final String category;

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'qty': qty,
      'category': category,
    };
  }

  factory KitchenOrderItem.fromMap(Map<String, dynamic> data) {
    return KitchenOrderItem(
      itemId: data['itemId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      qty: (data['qty'] ?? 0).toInt(),
      category: data['category'] ?? '',
    );
  }
}

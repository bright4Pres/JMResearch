import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Pick image from gallery or camera
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage(XFile imageFile, String category) async {
    try {
      final fileName =
          '${category}_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

      // Separate kitchens into their own folder; others stay under kitchen_items
      final path = category == 'kitchens'
          ? 'kitchens/$fileName'
          : 'kitchen_items/$category/$fileName';

      final storageRef = _storage.ref().child(path);

      // Upload the file
      UploadTask uploadTask;
      if (imageFile.path.isNotEmpty) {
        final file = File(imageFile.path);
        if (!file.existsSync()) {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'file-not-found',
            message: 'Local image file not found at path: ${imageFile.path}',
          );
        }
        uploadTask = storageRef.putFile(file);
      } else {
        Uint8List imageData = await imageFile.readAsBytes();
        uploadTask = storageRef.putData(imageData);
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}

import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http; 

// ===================================================================
// CloudinaryService Class
// ===================================================================

class CloudinaryService {
  static const _cloudName = 'dmeua1qwh';
  static const _uploadPreset = 'iskaon_preset';

  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName, 
    _uploadPreset, 
    cache: false
  ); 

  static Future<({String url, String publicId})?> uploadImage(
    File imageFile, 
    {String folder = 'iskaon'}) async{
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return (url: response.secureUrl, publicId: response.publicId);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  static Future<void> deleteImage(String publicId) async {
    try {
      await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'upload_preset': _uploadPreset,
        },
      );
     print('Image deleted successfully: $publicId');
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}
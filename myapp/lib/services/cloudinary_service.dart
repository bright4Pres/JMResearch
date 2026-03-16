import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';


class CloudinaryService {

  static const _cloudName = 'dmeua1qwh';
  static const _uploadPreset = 'iskaon_preset';

  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName, 
    _uploadPreset, 
    cache: false); 

  static Future<String?> uploadImage(File imageFile, {String folder = 'iskaon'}) async{

    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    }

    catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
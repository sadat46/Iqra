import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      // Request appropriate permission based on Android version
      PermissionStatus status;
      if (await Permission.photos.isDenied) {
        status = await Permission.photos.request();
      } else if (await Permission.storage.isDenied) {
        status = await Permission.storage.request();
      } else {
        status = PermissionStatus.granted;
      }
      
      if (status != PermissionStatus.granted) {
        throw Exception('Gallery permission denied');
      }

      // Pick image
      XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  // Take photo with camera
  Future<File?> takePhotoWithCamera() async {
    try {
      // Request camera permission
      PermissionStatus status;
      if (await Permission.camera.isDenied) {
        status = await Permission.camera.request();
      } else {
        status = PermissionStatus.granted;
      }
      
      if (status != PermissionStatus.granted) {
        throw Exception('Camera permission denied');
      }

      // Take photo
      XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String chatId) async {
    try {
      // Compress image if needed
      File processedImage = await compressImageIfNeeded(imageFile);
      
      // Create unique filename
      String fileName = 'chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}_${processedImage.path.split('/').last}';
      
      // Create storage reference
      Reference storageRef = _storage.ref().child(fileName);
      
      // Upload file
      UploadTask uploadTask = storageRef.putFile(
        processedImage,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'chatId': chatId,
            'originalSize': getImageSizeInMB(imageFile).toString(),
            'compressedSize': getImageSizeInMB(processedImage).toString(),
          },
        ),
      );

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      String filePath = Uri.parse(imageUrl).path;
      if (filePath.startsWith('/o/')) {
        filePath = filePath.substring(3);
      }
      if (filePath.contains('?')) {
        filePath = filePath.split('?')[0];
      }
      
      // Decode URL-encoded path
      filePath = Uri.decodeComponent(filePath);
      
      // Delete file
      Reference storageRef = _storage.ref().child(filePath);
      await storageRef.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Get image size in MB
  double getImageSizeInMB(File file) {
    int bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Check if image size is acceptable (max 10MB)
  bool isImageSizeAcceptable(File file) {
    return getImageSizeInMB(file) <= 10.0;
  }

  // Compress image if needed
  Future<File> compressImageIfNeeded(File file) async {
    double sizeInMB = getImageSizeInMB(file);
    
    if (sizeInMB <= 2.0) {
      return file; // No compression needed for small images
    }

    try {
      // Create temporary file for compressed image
      String tempPath = file.path.replaceAll('.jpg', '_compressed.jpg')
          .replaceAll('.jpeg', '_compressed.jpeg')
          .replaceAll('.png', '_compressed.jpg');
      
      // Determine compression quality based on original size
      int quality = 85;
      if (sizeInMB > 5.0) quality = 70;
      if (sizeInMB > 8.0) quality = 60;

      // Compress image
      final xfile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        tempPath,
        quality: quality,
        minWidth: 1024,
        minHeight: 1024,
        rotate: 0,
      );
      File? compressedFile = xfile != null ? File(xfile.path) : null;
      if (compressedFile != null) {
        // Debug info - removed print statement for production
        return compressedFile;
      }
      return file; // Return original if compression fails
    } catch (e) {
      // Image compression failed, returning original file
      return file; // Return original if compression fails
    }
  }
} 
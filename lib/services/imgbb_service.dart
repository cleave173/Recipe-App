import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ImgBBService {
  static const String _apiKey = '2a15abe6b8e2436bf21d19badbef7db2';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  final Dio _dio = Dio();

  /// Upload image bytes to imgBB and return permanent URL
  Future<String?> uploadImageBytes(Uint8List bytes) async {
    try {
      debugPrint('Uploading image to imgBB...');
      
      // Convert to base64
      final base64Image = base64Encode(bytes);

      // Send POST request
      final response = await _dio.post(
        _uploadUrl,
        data: FormData.fromMap({
          'key': _apiKey,
          'image': base64Image,
        }),
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final imageUrl = data['data']['url'] as String;
          debugPrint('Image uploaded successfully: $imageUrl');
          return imageUrl;
        }
      }
      
      debugPrint('imgBB upload failed: ${response.data}');
      return null;
    } catch (e) {
      debugPrint('Error uploading image to imgBB: $e');
      return null;
    }
  }
}

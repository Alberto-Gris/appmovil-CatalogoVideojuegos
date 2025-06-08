import 'dart:io'; //cambiar esta libreria en caso de querer usarlo con chrome
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'dbdkb85oh';
  static const String _uploadPreset = 'upload';
  static const String _apiKey = '511918764597653';
  static const String _apiSecret = '2DFuBLLGE9hJWL2s-aZqKP3a8iQ';

  static const String _baseUrl = 'https://api.cloudinary.com/v1_1/$_cloudName';

  static Future<String?> uploadImage({bool fromCamera = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final File file = File(image.path);
      return await _uploadFile(file, 'image');
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      rethrow;
    }
  }

  // Subir video desde galería
  static Future<String?> uploadVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // Máximo 5 minutos
      );

      if (video == null) return null;

      final File file = File(video.path);
      return await _uploadFile(file, 'video');
    } catch (e) {
      print('Error al seleccionar video: $e');
      rethrow;
    }
  }

  // Subir archivo genérico
  static Future<String?> uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final String extension =
            result.files.single.extension?.toLowerCase() ?? '';

        String resourceType = 'auto';
        if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff'].contains(extension)) {
          resourceType = 'image';
        } else if ([
          'mp4',
          'mov',
          'avi',
          'wmv',
          'flv',
          'webm',
          'mkv',
          '3gp',
        ].contains(extension)) {
          resourceType = 'video';
        }

        return await _uploadFile(file, resourceType);
      }
      return null;
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      rethrow;
    }
  }

  // Función privada para subir archivo a Cloudinary
  static Future<String?> _uploadFile(File file, String resourceType) async {
    try {
      print('=== INICIO UPLOAD CLOUDINARY ===');
      print('Cloud name: $_cloudName');
      print('Upload preset: $_uploadPreset');
      print('Resource type: $resourceType');
      print('File path: ${file.path}');
      
      // Verificar tamaño del archivo
      final fileSize = await file.length();
      print('File size: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
      
      final maxSize = resourceType == 'video' ? 100 * 1024 * 1024 : 10 * 1024 * 1024;
      
      if (fileSize > maxSize) {
        throw Exception('El archivo es demasiado grande. Máximo ${resourceType == 'video' ? '100MB' : '10MB'}');
      }

      final uri = Uri.parse('$_baseUrl/$resourceType/upload');
      print('Upload URL: $uri');
      
      final request = http.MultipartRequest('POST', uri);

      // Agregar el archivo
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      print('Archivo agregado a la request');

      // SOLO parámetros permitidos para unsigned upload
      request.fields['upload_preset'] = _uploadPreset;
      
      print('Parámetros enviados:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });

      print('Enviando request...');
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response data: $responseData');

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseData);
        final secureUrl = jsonData['secure_url'] as String;
        print('✅ Upload exitoso: $secureUrl');
        return secureUrl;
      } else {
        print('❌ Error en upload');
        final error = json.decode(responseData);
        final errorMessage = error['error']?['message'] ?? 'Error desconocido';
        throw Exception('Error ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('💥 Exception en upload: $e');
      print('Exception type: ${e.runtimeType}');
      rethrow;
    }
  }
  // Obtener URL del thumbnail de un video
  static String getVideoThumbnail(String videoUrl) {
    try {
      final uri = Uri.parse(videoUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3) {
        // Encontrar el índice del resource_type
        int versionIndex = -1;
        for (int i = 0; i < pathSegments.length; i++) {
          if (pathSegments[i] == 'video') {
            versionIndex = i;
            break;
          }
        }

        if (versionIndex != -1 && versionIndex + 2 < pathSegments.length) {
          final publicId = pathSegments
              .sublist(versionIndex + 2)
              .join('/')
              .split('.')
              .first;
          
          return 'https://res.cloudinary.com/$_cloudName/video/upload/w_300,h_200,c_fill,f_jpg,so_0/$publicId.jpg';
        }
      }
    } catch (e) {
      print('Error generando thumbnail: $e');
    }

    return videoUrl; // Fallback
  }

  // Extraer public_id de una URL de Cloudinary
  static String? extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Buscar el índice del tipo de recurso
      int resourceIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (['image', 'video', 'raw'].contains(pathSegments[i])) {
          resourceIndex = i;
          break;
        }
      }

      if (resourceIndex != -1 && resourceIndex + 2 < pathSegments.length) {
        return pathSegments
            .sublist(resourceIndex + 2)
            .join('/')
            .split('.')
            .first;
      }
    } catch (e) {
      print('Error extrayendo public_id: $e');
    }
    return null;
  }

  // Eliminar archivo de Cloudinary
  static Future<bool> deleteFile(String publicId, String resourceType) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature({
        'public_id': publicId,
        'timestamp': timestamp,
      });

      final uri = Uri.parse('$_baseUrl/$resourceType/destroy');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['result'] == 'ok';
      }
      return false;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }

  // Generar firma para autenticación
  static String _generateSignature(Map<String, String> params) {
    // Crear string de parámetros ordenados
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    final paramsString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final stringToSign = '$paramsString$_apiSecret';
    
    // Generar SHA1
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  // Validar configuración
  static bool isConfigured() {
    return _cloudName != 'TU_CLOUD_NAME' &&
           _uploadPreset != 'TU_UPLOAD_PRESET' &&
           _apiKey != 'TU_API_KEY' &&
           _apiSecret != 'TU_API_SECRET';
  }

  // Obtener información de un archivo
  static Future<Map<String, dynamic>?> getFileInfo(String publicId, String resourceType) async {
    try {
      final uri = Uri.parse('$_baseUrl/resources/$resourceType/$publicId');
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature({
        'public_id': publicId,
        'timestamp': timestamp,
      });

      final response = await http.get(
        uri.replace(queryParameters: {
          'api_key': _apiKey,
          'timestamp': timestamp,
          'signature': signature,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error obteniendo información del archivo: $e');
      return null;
    }
  }
}
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Tomar foto desde la cámara
  static Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print("Error tomando foto: $e");
      return null;
    }
  }

  // Seleccionar foto de la galería
  static Future<File?> pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print("Error seleccionando foto: $e");
      return null;
    }
  }

  // Copiar imagen al directorio de la app
  static Future<String> saveImageToAppDirectory(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'animal_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = '${directory.path}/$fileName';

      // Copiar el archivo
      await imageFile.copy(path);
      return path;
    } catch (e) {
      print("Error guardando imagen: $e");
      rethrow;
    }
  }

  // Eliminar imagen del directorio
  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error eliminando imagen: $e");
    }
  }
}

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sdlgapp/pages/db_helper.dart';
import 'package:sdlgapp/services/image_service.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Tomar foto con cámara
  static Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      print("Error tomando foto: $e");
      return null;
    }
  }

  // Seleccionar de galería
  static Future<File?> pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      print("Error seleccionando foto: $e");
      return null;
    }
  }

  // Guardar imagen en directorio de la app
  static Future<String?> saveImageToAppDirectory(File imageFile) async {
    try {
      // Obtener directorio de documentos
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDirPath = '${appDir.path}/animal_images';

      // Crear directorio si no existe
      final Directory imagesDir = Directory(imagesDirPath);
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generar nombre único para la imagen
      final String fileName =
          'animal_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}.jpg';
      final String newPath = '${imagesDir.path}/$fileName';

      // Copiar archivo al nuevo directorio
      final File newImage = await imageFile.copy(newPath);

      print("Imagen guardada en: $newPath");
      return newPath;
    } catch (e) {
      print("Error guardando imagen: $e");
      return null;
    }
  }

  // Eliminar imagen
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        print("Imagen eliminada: $imagePath");
        return true;
      }
      return false;
    } catch (e) {
      print("Error eliminando imagen: $e");
      return false;
    }
  }

  // Verificar si una imagen existe
  static Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;
    try {
      final File imageFile = File(imagePath);
      return await imageFile.exists();
    } catch (e) {
      return false;
    }
  }
}

class PagAnimales extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final VoidCallback onRefresh;
  final bool isLoading;

  const PagAnimales({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 60,
        title: Row(
          children: [
            SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 40,
                child: SearchAnchor.bar(
                  barHintText: 'Buscar Animal',
                  barElevation: WidgetStateProperty.all(0),
                  barSide: WidgetStateProperty.all(
                    BorderSide(color: Colors.grey.shade400, width: 1.5),
                  ),
                  barBackgroundColor: WidgetStateProperty.all(Colors.white),
                  barTextStyle: WidgetStateProperty.all(
                    TextStyle(color: Colors.black87),
                  ),
                  barHintStyle: WidgetStateProperty.all(
                    TextStyle(color: Colors.grey[600]),
                  ),
                  suggestionsBuilder:
                      (BuildContext context, SearchController controller) {
                        if (controller.text.isEmpty) {
                          return [
                            ListTile(
                              title: Text("Escribe para buscar animales..."),
                              textColor: Colors.grey,
                            ),
                          ];
                        }
                        return _buildSearchSuggestions(controller.text);
                      },
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 137, 77, 77).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _showAddAnimalDialog(context),
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 182, 128, 128),
                ),
                tooltip: 'Agregar Animal',
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "No hay animales registrados",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              "Presiona el botón + para agregar uno",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final tganado = data[index];
        return _buildAnimalCard(tganado, context);
      },
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> tganado, BuildContext context) {
    final imagePath = tganado['fotogdo']?.toString();

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: FutureBuilder<bool>(
          future: ImageService.imageExists(imagePath),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data! && imagePath != null) {
              return CircleAvatar(
                radius: 25,
                backgroundImage: FileImage(File(imagePath)),
                onBackgroundImageError: (exception, stackTrace) {
                  print("Error cargando imagen: $exception");
                },
              );
            } else {
              return CircleAvatar(
                backgroundColor: const Color.fromARGB(
                  255,
                  182,
                  128,
                  128,
                ).withOpacity(0.2),
                child: Icon(
                  Icons.pets,
                  color: const Color.fromARGB(255, 137, 77, 77),
                ),
              );
            }
          },
        ),
        title: Text(
          tganado['nombregdo'] ?? 'Sin nombre',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            if (tganado['aretegdo'] != null)
              Text('Arete: ${tganado['aretegdo']}'),
            if (tganado['sexogdo'] != null) Text('Sexo: ${tganado['sexogdo']}'),
            if (tganado['nacimientogdo'] != null)
              Text('Nacimiento: ${tganado['nacimientogdo']}'),
            SizedBox(height: 4),
            Text(
              'ID: ${tganado['idgdo']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditAnimalDialog(context, tganado);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, tganado);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color.fromARGB(255, 137, 77, 77),
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = "${picked.day}/${picked.month}/${picked.year}";
      controller.text = formattedDate;
    }
  }

  Future<List<Widget>> _buildSearchSuggestions(String query) async {
    try {
      final resultados = await SQLHelper.searchAnimales(query);

      if (resultados.isEmpty) {
        return [
          ListTile(
            title: Text("No se encontraron animales"),
            textColor: Colors.grey,
          ),
        ];
      }

      return resultados.map((tganado) {
        return ListTile(
          leading: Icon(
            Icons.pets,
            color: const Color.fromARGB(255, 137, 77, 77),
          ),
          title: Text(tganado['nombregdo'] ?? 'Sin nombre'),
          subtitle: Text('${tganado['aretegdo']} - ${tganado['sexogdo']}'),
          onTap: () {},
        );
      }).toList();
    } catch (e) {
      return [
        ListTile(
          title: Text("Error en la búsqueda"),
          subtitle: Text("Intenta de nuevo"),
        ),
      ];
    }
  }

  void _showAddAnimalDialog(BuildContext context) {
    final areteController = TextEditingController();
    final nombreController = TextEditingController();
    final sexoController = TextEditingController();
    final razaController = TextEditingController();
    final fechaNacimientoController = TextEditingController();
    final corralController = TextEditingController();
    final alimentoController = TextEditingController();
    final produccionController = TextEditingController();
    final estatusController = TextEditingController();
    final observacionController = TextEditingController();

    File? selectedImage;
    String? imagePath;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Agregar Animal"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selector de imagen
                    _buildImageSelector(setState, selectedImage, imagePath, (
                      File? newImage,
                      String? newPath,
                    ) {
                      selectedImage = newImage;
                      imagePath = newPath;
                    }),
                    SizedBox(height: 16),

                    TextField(
                      controller: areteController,
                      decoration: InputDecoration(
                        labelText: 'Arete',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: sexoController,
                      decoration: InputDecoration(
                        labelText: 'Sexo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: razaController,
                      decoration: InputDecoration(
                        labelText: 'Raza',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: fechaNacimientoController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () =>
                              _selectDate(context, fechaNacimientoController),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: corralController,
                      decoration: InputDecoration(
                        labelText: 'Corral',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: alimentoController,
                      decoration: InputDecoration(
                        labelText: 'Alimento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: produccionController,
                      decoration: InputDecoration(
                        labelText: 'Tipo de producción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: estatusController,
                      decoration: InputDecoration(
                        labelText: 'Estatus',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: observacionController,
                      decoration: InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (areteController.text.isEmpty ||
                        nombreController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Arete y Nombre son obligatorios'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final nuevoAnimal = {
                      'aretegdo': areteController.text,
                      'nombregdo': nombreController.text,
                      'sexogdo': sexoController.text,
                      'razagdo': razaController.text,
                      'nacimientogdo': fechaNacimientoController.text,
                      'corralgdo': corralController.text,
                      'alimentogdo': alimentoController.text,
                      'prodgdo': produccionController.text,
                      'estatusgdo': estatusController.text,
                      'observaciongdo': observacionController.text,
                      'fotogdo': imagePath ?? '',
                    };

                    try {
                      await SQLHelper.createAnimal(nuevoAnimal);
                      onRefresh();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Animal agregado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar animal: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildImageSelector(
    StateSetter setState,
    File? selectedImage,
    String? imagePath,
    Function(File?, String?) onImageChanged,
  ) {
    return Column(
      children: [
        // Vista previa de la imagen
        Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey),
            color: Colors.grey[100],
          ),
          child: FutureBuilder<bool>(
            future: selectedImage != null
                ? ImageService.imageExists(imagePath)
                : Future.value(false),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data! && selectedImage != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    selectedImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderIcon();
                    },
                  ),
                );
              } else {
                return _buildPlaceholderIcon();
              }
            },
          ),
        ),

        SizedBox(height: 10),

        // Botones de cámara y galería
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final image = await ImageService.takePhoto();
                if (image != null) {
                  final savedPath = await ImageService.saveImageToAppDirectory(
                    image,
                  );
                  if (savedPath != null) {
                    setState(() {
                      onImageChanged(image, savedPath);
                    });
                    print("Ruta de imagen guardada: $savedPath");
                  } else {
                    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar la imagen'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.camera_alt),
              label: Text('Cámara'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final image = await ImageService.pickPhoto();
                if (image != null) {
                  final savedPath = await ImageService.saveImageToAppDirectory(
                    image,
                  );
                  if (savedPath != null) {
                    setState(() {
                      onImageChanged(image, savedPath);
                    });
                    print("Ruta de imagen guardada: $savedPath");
                  } else {
                    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar la imagen'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.photo_library),
              label: Text('Galería'),
            ),
          ],
        ),

        // Botón para quitar foto
        if (selectedImage != null)
          TextButton(
            onPressed: () async {
              // Eliminar archivo físico si existe
              if (imagePath != null) {
                await ImageService.deleteImage(imagePath);
              }
              setState(() {
                onImageChanged(null, null);
              });
            },
            child: Text('Quitar foto', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(Icons.photo_camera, size: 50, color: Colors.grey[400]);
  }

  void _showEditAnimalDialog(
    BuildContext context,
    Map<String, dynamic> tganado,
  ) {
    final areteController = TextEditingController(
      text: tganado['aretegdo']?.toString() ?? '',
    );
    final nombreController = TextEditingController(
      text: tganado['nombregdo']?.toString() ?? '',
    );
    final sexoController = TextEditingController(
      text: tganado['sexogdo']?.toString() ?? '',
    );
    final razaController = TextEditingController(
      text: tganado['razagdo']?.toString() ?? '',
    );
    final fechaNacimientoController = TextEditingController(
      text: tganado['nacimientogdo']?.toString() ?? '',
    );
    final corralController = TextEditingController(
      text: tganado['corralgdo']?.toString() ?? '',
    );
    final alimentoController = TextEditingController(
      text: tganado['alimentogdo']?.toString() ?? '',
    );
    final produccionController = TextEditingController(
      text: tganado['prodgdo']?.toString() ?? '',
    );
    final estatusController = TextEditingController(
      text: tganado['estatusgdo']?.toString() ?? '',
    );
    final observacionController = TextEditingController(
      text: tganado['observaciongdo']?.toString() ?? '',
    );

    File? selectedImage;
    String? imagePath = tganado['fotogdo']?.toString();

    // Cargar imagen existente si hay una
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        selectedImage = file;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Editar Animal"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildImageSelector(setState, selectedImage, imagePath, (
                      File? newImage,
                      String? newPath,
                    ) {
                      selectedImage = newImage;
                      imagePath = newPath;
                    }),
                    SizedBox(height: 16),

                    TextField(
                      controller: areteController,
                      decoration: InputDecoration(
                        labelText: 'Arete',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: sexoController,
                      decoration: InputDecoration(
                        labelText: 'Sexo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: razaController,
                      decoration: InputDecoration(
                        labelText: 'Raza',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: fechaNacimientoController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () =>
                              _selectDate(context, fechaNacimientoController),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: corralController,
                      decoration: InputDecoration(
                        labelText: 'Corral',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: alimentoController,
                      decoration: InputDecoration(
                        labelText: 'Alimento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: produccionController,
                      decoration: InputDecoration(
                        labelText: 'Producción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: estatusController,
                      decoration: InputDecoration(
                        labelText: 'Estatus',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: observacionController,
                      decoration: InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tganado['idgdo'] == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ID del animal no válido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final animalActualizado = {
                      'aretegdo': areteController.text,
                      'nombregdo': nombreController.text,
                      'sexogdo': sexoController.text,
                      'razagdo': razaController.text,
                      'nacimientogdo': fechaNacimientoController.text,
                      'corralgdo': corralController.text,
                      'alimentogdo': alimentoController.text,
                      'prodgdo': produccionController.text,
                      'estatusgdo': estatusController.text,
                      'observaciongdo': observacionController.text,
                      'fotogdo': imagePath ?? '',
                    };

                    try {
                      await SQLHelper.updateAnimal(
                        tganado['idgdo'],
                        animalActualizado,
                      );
                      onRefresh();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Animal actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar animal: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> tganado,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar Animal"),
          content: Text(
            "¿Estás seguro de que quieres eliminar a ${tganado['nombregdo']}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Eliminar imagen si existe
                  final imagePath = tganado['fotogdo']?.toString();
                  if (imagePath != null && imagePath.isNotEmpty) {
                    await ImageService.deleteImage(imagePath);
                  }

                  await SQLHelper.deleteAnimal(tganado['idgdo']);
                  onRefresh();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Animal eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar animal: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

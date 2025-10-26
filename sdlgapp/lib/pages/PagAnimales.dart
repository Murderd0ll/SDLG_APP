import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sdlgapp/pages/db_helper.dart';

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

  void _showAnimalDetails(Map<String, dynamic> animal, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AnimalDetailsDialog(animal: animal),
    );
  }

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
          tganado['aretegdo'] ?? 'Sin arete',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),

            if (tganado['nombregdo'] != null)
              Text('Nombre: ${tganado['nombregdo']}'),

            if (tganado['sexogdo'] != null) Text('Sexo: ${tganado['sexogdo']}'),

            if (tganado['razagdo'] != null)
              Text('Raza: ${tganado['razagdo']} kg'),

            if (tganado['estatusgdo'] != null)
              Text('Estatus: ${tganado['estatusgdo']}'),

            if (tganado['observaciongdo'] != null)
              Text('Observaciones: ${tganado['observaciongdo']}'),

            SizedBox(height: 4),
            Text(
              'ID: ${tganado['idgdo']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => _showAnimalDetails(
          tganado,
          context,
        ), //  Este es para mostrar el popup de los detalles
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'health') {
              _showHealthOptions(context, tganado);
            } else if (value == 'edit') {
              _showEditAnimalDialog(context, tganado);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, tganado);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'health', // salud
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Salud'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'edit', //editar
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete', //eliminar
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
    final razaController = TextEditingController();
    final fechaNacimientoController = TextEditingController();
    final corralController = TextEditingController();
    final alimentoController = TextEditingController();
    final produccionController = TextEditingController();
    final observacionController = TextEditingController();

    String? estatusgdo;
    String? sexoSeleccionado;
    File? selectedImage;
    String? imagePath;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                    }, dialogContext),
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

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: sexoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Sexo',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Macho',
                            child: Text('Macho'),
                          ),
                          DropdownMenuItem(
                            value: 'Hembra',
                            child: Text('Hembra'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            sexoSeleccionado = newValue;
                          });
                        },
                        hint: Text('Selecciona el sexo'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona el sexo';
                          }
                          return null;
                        },
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

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: estatusgdo,
                        decoration: InputDecoration(
                          labelText: 'Estatus',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Activo',
                            child: Text('Activo'),
                          ),
                          DropdownMenuItem(
                            value: 'Inactivo',
                            child: Text('Inactivo'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            estatusgdo = newValue;
                          });
                        },
                        hint: Text('Selecciona el estatus'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona el estatus';
                          }
                          return null;
                        },
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
                      'sexogdo': sexoSeleccionado,
                      'razagdo': razaController.text,
                      'nacimientogdo': fechaNacimientoController.text,
                      'corralgdo': corralController.text,
                      'alimentogdo': alimentoController.text,
                      'prodgdo': produccionController.text,
                      'estatusgdo': estatusgdo,
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
    BuildContext dialogContext,
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
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Imagen tomada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
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
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Imagen seleccionada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
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

  void _showHealthOptions(BuildContext context, Map<String, dynamic> animal) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Registros de Salud - ${animal['nombregdo']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 137, 77, 77),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.add, color: Colors.green),
              title: Text('Agregar Registro de Salud'),
              onTap: () {
                Navigator.pop(context);
                _showAddHealthRecordDialog(context, animal);
              },
            ),
            ListTile(
              leading: Icon(Icons.medical_services, color: Colors.blue),
              title: Text('Ver Historial de Salud'),
              onTap: () {
                Navigator.pop(context);
                _showHealthHistory(context, animal);
              },
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHealthRecordDialog(
    BuildContext context,
    Map<String, dynamic> animal,
  ) {
    final veterinarioController = TextEditingController();
    final procedimientoController = TextEditingController();
    final condicionController = TextEditingController();
    final fechaRevisionController = TextEditingController();
    final observacionesController = TextEditingController();

    File? selectedFile;
    String? filePath;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Agregar Registro de Salud"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Información del animal
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.pets,
                            color: const Color.fromARGB(255, 137, 77, 77),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  animal['nombregdo'] ?? 'Sin nombre',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Arete: ${animal['aretegdo'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    TextField(
                      controller: veterinarioController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Veterinario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: procedimientoController,
                      decoration: InputDecoration(
                        labelText: 'Procedimiento Realizado',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: condicionController,
                      decoration: InputDecoration(
                        labelText: 'Condición de Salud',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: fechaRevisionController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Revisión',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(
                            dialogContext,
                            fechaRevisionController,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: observacionesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Selector de archivo
                    _buildFileSelector(
                      setState,
                      selectedFile,
                      filePath,
                      dialogContext,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (veterinarioController.text.isEmpty ||
                        procedimientoController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Veterinario y Procedimiento son obligatorios',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final nuevoRegistro = {
                      'areteanimal':
                          animal['aretegdo'] ??
                          '', // Solo usamos el arete de la tabla tganado
                      'tipoanimal': 'adulto',
                      'nomvet': veterinarioController.text,
                      'procedimiento': procedimientoController.text,
                      'condicionsalud': condicionController.text,
                      'fecharev': fechaRevisionController.text,
                      'observacionsalud': observacionesController.text,
                      'archivo': filePath ?? '',
                    };

                    try {
                      await SQLHelper.createRegistroSalud(nuevoRegistro);
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Registro de salud agregado exitosamente',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar registro: $e'),
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

  Widget _buildFileSelector(
    StateSetter setState,
    File? selectedFile,
    String? filePath,
    BuildContext dialogContext,
  ) {
    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey),
            color: Colors.grey[100],
          ),
          child: selectedFile != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_file, size: 40, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'Archivo seleccionado',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '(Imagen)',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sin archivo adjunto',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () async {
            // Para PDFs se ocupa  el package file_picker
            // Por ahora  solo usa imágenes
            final image = await ImageService.pickPhoto();
            if (image != null) {
              final savedPath = await ImageService.saveImageToAppDirectory(
                image,
              );
              if (savedPath != null) {
                setState(() {
                  selectedFile = image;
                  filePath = savedPath;
                });
                // USAR dialogContext EN LUGAR DEL CAST
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Imagen adjuntada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar la imagen'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },

          icon: Icon(Icons.attach_file),
          label: Text('Subir Imagen'),
        ),
        if (selectedFile != null)
          TextButton(
            onPressed: () {
              setState(() {
                selectedFile = null;
                filePath = null;
              });
            },
            child: Text('Quitar archivo', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
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

    final observacionController = TextEditingController(
      text: tganado['observaciongdo']?.toString() ?? '',
    );
    String? estatusgdo = tganado['estatusgdo']?.toString();
    String? sexoSeleccionado = tganado['sexogdo']?.toString();

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
      builder: (BuildContext dialogContext) {
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
                    }, dialogContext),
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

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: sexoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Sexo',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Macho',
                            child: Text('Macho'),
                          ),
                          DropdownMenuItem(
                            value: 'Hembra',
                            child: Text('Hembra'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            sexoSeleccionado = newValue;
                          });
                        },
                        hint: Text('Selecciona el sexo'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona el sexo';
                          }
                          return null;
                        },
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

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: estatusgdo,
                        decoration: InputDecoration(
                          labelText: 'Estatus',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Activo',
                            child: Text('Activo'),
                          ),
                          DropdownMenuItem(
                            value: 'Inactivo',
                            child: Text('Inactivo'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            estatusgdo = newValue;
                          });
                        },
                        hint: Text('Selecciona el estatus'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona el estatus';
                          }
                          return null;
                        },
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
                      'sexogdo': sexoSeleccionado,
                      'razagdo': razaController.text,
                      'nacimientogdo': fechaNacimientoController.text,
                      'corralgdo': corralController.text,
                      'alimentogdo': alimentoController.text,
                      'prodgdo': produccionController.text,
                      'estatusgdo': estatusgdo,
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

class AnimalDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailsDialog({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final imagePath = animal['fotogdo']?.toString();

    return Dialog(
      insetPadding: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y botón cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalles del Animal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 137, 77, 77),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Foto del animal
              _buildPhotoSection(imagePath),

              SizedBox(height: 20),

              // Información básica
              _buildBasicInfoSection(),

              SizedBox(height: 20),

              // Información adicional
              _buildAdditionalInfoSection(),

              if (animal['observaciongdo'] != null &&
                  animal['observaciongdo'].toString().isNotEmpty)
                Column(
                  children: [SizedBox(height: 20), _buildObservationsSection()],
                ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(String? imagePath) {
    return Center(
      child: FutureBuilder<bool>(
        future: ImageService.imageExists(imagePath),
        builder: (context, snapshot) {
          final bool imageExists = snapshot.data ?? false;

          if (imageExists && imagePath != null) {
            return Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderPhoto();
                  },
                ),
              ),
            );
          } else {
            return _buildPlaceholderPhoto();
          }
        },
      ),
    );
  }

  Widget _buildPlaceholderPhoto() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, size: 50, color: Colors.grey[400]),
          SizedBox(height: 8),
          Text(
            'Sin foto',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 245, 245),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 232, 218, 218)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Básica',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 137, 77, 77),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow('Nombre', animal['nombregdo'] ?? 'No especificado'),
          _buildInfoRow('Arete', animal['aretegdo'] ?? 'No especificado'),
          _buildInfoRow('Sexo', animal['sexogdo'] ?? 'No especificado'),
          _buildInfoRow('Raza', animal['razagdo'] ?? 'No especificado'),
          _buildInfoRow(
            'Fecha Nacimiento',
            animal['nacimientogdo'] ?? 'No especificado',
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 245, 245),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 232, 218, 218)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Adicional',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 137, 77, 77),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow('Corral', animal['corralgdo'] ?? 'No especificado'),
          _buildInfoRow('Alimento', animal['alimentogdo'] ?? 'No especificado'),
          _buildInfoRow(
            'Tipo de Producción',
            animal['prodgdo'] ?? 'No especificado',
          ),
          _buildInfoRow('Estatus', animal['estatusgdo'] ?? 'No especificado'),
        ],
      ),
    );
  }

  Widget _buildObservationsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 245, 245),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 232, 218, 218)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observaciones',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 137, 77, 77),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            animal['observaciongdo'].toString(),
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 137, 77, 77),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}

void _showHealthHistory(BuildContext context, Map<String, dynamic> animal) {
  showDialog(
    context: context,
    builder: (context) => HealthHistoryDialog(animal: animal),
  );
}

// esta clase es para mostrar el historial d salud del animal desde el botoncito, sale ocmo popup xD
class HealthHistoryDialog extends StatefulWidget {
  final Map<String, dynamic> animal;

  const HealthHistoryDialog({super.key, required this.animal});

  @override
  State<HealthHistoryDialog> createState() => _HealthHistoryDialogState();
}

class _HealthHistoryDialogState extends State<HealthHistoryDialog> {
  List<Map<String, dynamic>> _registrosSalud = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrosSalud();
  }

  Future<void> _loadRegistrosSalud() async {
    try {
      final registros = await SQLHelper.getRegistrosSaludPorAreteYTipo(
        widget.animal['areteanimal'] ?? '',
        'adulto',
      );
      setState(() {
        _registrosSalud = registros;
        _isLoading = false;
      });
    } catch (e) {
      print("Error cargando registros de salud: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          AppBar(
            backgroundColor: const Color.fromARGB(255, 137, 77, 77),
            title: Text(
              'Historial del arete: ${widget.animal['aretegdo']}',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _registrosSalud.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay registros de salud',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Agrega el primer registro',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _registrosSalud.length,
                    itemBuilder: (context, index) {
                      final registro = _registrosSalud[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.medical_services,
                            color: Colors.green,
                          ),
                          title: Text(
                            registro['procedimiento'] ?? 'Sin procedimiento',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Veterinario: ${registro['nomvet'] ?? 'No especificado'}',
                              ),
                              Text(
                                'Fecha: ${registro['fecharev'] ?? 'No especificada'}',
                              ),
                              if (registro['condicion_salud'] != null)
                                Text(
                                  'Condición: ${registro['condicionsalud']}',
                                ),
                            ],
                          ),
                          trailing:
                              registro['archivo_adjunto'] != null &&
                                  registro['archivo_adjunto']
                                      .toString()
                                      .isNotEmpty
                              ? Icon(Icons.attach_file, color: Colors.blue)
                              : null,
                          onTap: () {
                            // Podrías mostrar más detalles aquí
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

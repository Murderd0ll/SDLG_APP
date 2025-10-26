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
      final String imagesDirPath = '${appDir.path}/becerro_images';

      // Crear directorio si no existe
      final Directory imagesDir = Directory(imagesDirPath);
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generar nombre único para la imagen
      final String fileName =
          'becerro_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}.jpg';
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

class PagBecerros extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final VoidCallback onRefresh;
  final bool isLoading;

  const PagBecerros({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.isLoading,
  });

  void _showBecerroDetails(
    Map<String, dynamic> tbecerros,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) => AnimalDetailsDialog(tbecerros: tbecerros),
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
                  barHintText: 'Buscar Becerros',
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
                              title: Text("Escribe para buscar becerros..."),
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
                color: const Color.fromARGB(255, 77, 137, 95).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _showAddBecerroDialog(context),
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 77, 137, 95),
                ),
                tooltip: 'Agregar Becerro',
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
            Icon(Icons.agriculture, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "No hay becerros registrados",
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
        final tbecerros = data[index];
        return _buildBecerroCard(tbecerros, context);
      },
    );
  }

  Widget _buildBecerroCard(
    Map<String, dynamic> tbecerros,
    BuildContext context,
  ) {
    final imagePath = tbecerros['fotobece']?.toString();
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
          tbecerros['aretebece'] ?? 'Sin arete',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),

            if (tbecerros['nombrebece'] != null)
              Text('Nombre: ${tbecerros['nombrebece']} kg'),

            if (tbecerros['pesobece'] != null)
              Text('Peso al nacer: ${tbecerros['pesobece']} kg'),

            if (tbecerros['sexobece'] != null)
              Text('Sexo: ${tbecerros['sexobece']}'),

            if (tbecerros['razabece'] != null)
              Text('Raza: ${tbecerros['razabece']} kg'),

            if (tbecerros['nacimientobece'] != null)
              Text('Nacimiento: ${tbecerros['nacimientobece']}'),

            if (tbecerros['estatusbece'] != null)
              Text('Estatus: ${tbecerros['estatusbece']}'),

            if (tbecerros['observacionbece'] != null)
              Text('Observaciones: ${tbecerros['observacionbece']}'),

            SizedBox(height: 4),
            Text(
              'ID: ${tbecerros['idbece']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => _showBecerroDetails(tbecerros, context),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'health') {
              _showHealthOptions(context, tbecerros);
            }
            if (value == 'edit') {
              _showEditBecerroDialog(context, tbecerros);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, tbecerros);
            }
          },

          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'health', //Salud
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Salud'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'edit', //Editar
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete', //Eliminar
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
      final resultados = await SQLHelper.searchBecerros(query);

      if (resultados.isEmpty) {
        return [
          ListTile(
            title: Text("No se encontraron becerros"),
            textColor: Colors.grey,
          ),
        ];
      }

      return resultados.map((tbecerros) {
        return ListTile(
          leading: Icon(
            Icons.agriculture,
            color: const Color.fromARGB(255, 77, 137, 95),
          ),
          title: Text(tbecerros['nombrebece'] ?? 'Sin nombre'),
          subtitle: Text('pesobece: ${tbecerros['pesobece']}'),
          onTap: () {
            // Aquí puedes navegar a los detalles del becerro
          },
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

  void _showAddBecerroDialog(BuildContext context) {
    final aretebeceController = TextEditingController();
    final nombrebeceController = TextEditingController();
    final pesobeceController = TextEditingController();
    final razabeceController = TextEditingController();
    final nacimientobeceController = TextEditingController();
    final corralbeceController = TextEditingController();
    final aretemadreController = TextEditingController();
    final observacionbeceController = TextEditingController();

    String? estatusbece;
    String? sexoSeleccionado;
    File? selectedImage;
    String? imagePath;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Agregar Becerro"),
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
                      controller: aretebeceController,
                      decoration: InputDecoration(
                        labelText: 'Arete',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: nombrebeceController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: pesobeceController,
                      decoration: InputDecoration(
                        labelText: 'Peso al Nacer (kg)',
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
                      controller: razabeceController,
                      decoration: InputDecoration(
                        labelText: 'Raza',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: nacimientobeceController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () =>
                              _selectDate(context, nacimientobeceController),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: corralbeceController,
                      decoration: InputDecoration(
                        labelText: 'Corral',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: estatusbece,
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
                          DropdownMenuItem(
                            value: 'Vendido',
                            child: Text('Vendido'),
                          ),
                          DropdownMenuItem(
                            value: 'Muerto',
                            child: Text('Muerto'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            estatusbece = newValue;
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
                      controller: aretemadreController,
                      decoration: InputDecoration(
                        labelText: 'Arete de la Madre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: observacionbeceController,
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
                    final nuevoBecerro = {
                      'aretebece': aretebeceController.text,
                      'nombrebece': nombrebeceController.text,
                      'pesobece': pesobeceController.text,
                      'sexobece': sexoSeleccionado,
                      'razabece': razabeceController.text,
                      'nacimientobece': nacimientobeceController.text,
                      'corralbece': corralbeceController.text,
                      'estatusbece': estatusbece,
                      'aretemadre': aretemadreController.text,
                      'observacionbece': observacionbeceController.text,
                      'fotobece': imagePath ?? '',
                    };

                    try {
                      await SQLHelper.createBecerro(nuevoBecerro);
                      onRefresh();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Becerro agregado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar becerro: $e'),
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

  void _showHealthOptions(
    BuildContext context,
    Map<String, dynamic> tbecerros,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Registros de Salud - ${tbecerros['nombrebece']}',
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
                _showAddHealthRecordDialog(context, tbecerros);
              },
            ),
            ListTile(
              leading: Icon(Icons.medical_services, color: Colors.blue),
              title: Text('Ver Historial de Salud'),
              onTap: () {
                Navigator.pop(context);
                _showHealthHistory(context, tbecerros);
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
    Map<String, dynamic> tbecerros,
  ) {
    final veterinarioController = TextEditingController();
    final procedimientoController = TextEditingController();
    final fechaRevisionController = TextEditingController();
    final observacionesController = TextEditingController();

    String? condicion;
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
                                  tbecerros['nombrebece'] ?? 'Sin nombre',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Arete: ${tbecerros['aretebece'] ?? 'N/A'}',
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

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: condicion,
                        decoration: InputDecoration(
                          labelText: 'Condición de Salud',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Buena',
                            child: Text('Buena'),
                          ),
                          DropdownMenuItem(
                            value: 'Regular',
                            child: Text('Regular'),
                          ),
                          DropdownMenuItem(value: 'Mala', child: Text('Mala')),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            condicion = newValue;
                          });
                        },
                        hint: Text('Selecciona la condición'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona la condición';
                          }
                          return null;
                        },
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
                          tbecerros['aretebece'] ??
                          '', // Solo usamos el arete de la tabla tbecerro
                      'tipoanimal': 'becerro',
                      'nomvet': veterinarioController.text,
                      'procedimiento': procedimientoController.text,
                      'condicionsalud': condicion,
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

  void _showEditBecerroDialog(
    BuildContext context,
    Map<String, dynamic> tbecerros,
  ) {
    final aretebeceController = TextEditingController(
      text: tbecerros['aretebece'] ?? '',
    );
    final nombrebeceController = TextEditingController(
      text: tbecerros['nombrebece'] ?? '',
    );
    final pesobeceController = TextEditingController(
      text: tbecerros['pesobece']?.toString() ?? '',
    );
    final razabeceController = TextEditingController(
      text: tbecerros['razabece']?.toString() ?? '',
    );
    final nacimientobeceController = TextEditingController(
      text: tbecerros['nacimientobece']?.toString() ?? '',
    );
    final corralbeceController = TextEditingController(
      text: tbecerros['corralbece']?.toString() ?? '',
    );
    final aretemadreController = TextEditingController(
      text: tbecerros['aretemadre']?.toString() ?? '',
    );
    final observacionbeceController = TextEditingController(
      text: tbecerros['observacionbece']?.toString() ?? '',
    );

    String? estatusbece = tbecerros['estatusbece']?.toString();

    String? sexoSeleccionado = tbecerros['sexobece']?.toString();

    File? selectedImage;
    String? imagePath = tbecerros['fotobece']?.toString();

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
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text("Editar Becerro"),
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
                      controller: aretebeceController,
                      decoration: InputDecoration(
                        labelText: 'Arete',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: nombrebeceController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: pesobeceController,
                      decoration: InputDecoration(
                        labelText: 'Peso',
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
                      controller: razabeceController,
                      decoration: InputDecoration(
                        labelText: 'Raza',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: nacimientobeceController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () =>
                              _selectDate(context, nacimientobeceController),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: corralbeceController,
                      decoration: InputDecoration(
                        labelText: 'Corral',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: estatusbece,
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
                          DropdownMenuItem(
                            value: 'Vendido',
                            child: Text('Vendido'),
                          ),
                          DropdownMenuItem(
                            value: 'Muerto',
                            child: Text('Muerto'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            estatusbece = newValue;
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
                      controller: aretemadreController,
                      decoration: InputDecoration(
                        labelText: 'Arete de la Madre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: observacionbeceController,
                      decoration: InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
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
                    final becerroActualizado = {
                      'aretebece': aretebeceController.text,
                      'nombrebece': nombrebeceController.text,
                      'pesobece': pesobeceController.text,
                      'sexobece': sexoSeleccionado,
                      'razabece': razabeceController.text,
                      'nacimientobece': nacimientobeceController.text,
                      'corralbece': corralbeceController.text,
                      'estatusbece': estatusbece,
                      'aretemadre': aretemadreController.text,
                      'observacionbece': observacionbeceController.text,
                      'fotobece': imagePath ?? '',
                    };

                    try {
                      await SQLHelper.updateBecerro(
                        tbecerros['idbece'],
                        becerroActualizado,
                      );
                      onRefresh();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Becerro actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar becerro: $e'),
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
    Map<String, dynamic> tbecerros,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar Becerro"),
          content: Text(
            "¿Estás seguro de que quieres eliminar a ${tbecerros['nombrebece']}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await SQLHelper.deleteBecerro(tbecerros['idbece']);
                  onRefresh();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Becerro eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar becerro: $e'),
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
  final Map<String, dynamic> tbecerros;

  const AnimalDetailsDialog({super.key, required this.tbecerros});

  @override
  Widget build(BuildContext context) {
    final imagePath = tbecerros['fotobece']?.toString();

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
                    'Detalles del Becerro',
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

              if (tbecerros['observacionbece'] != null &&
                  tbecerros['observacionbece'].toString().isNotEmpty)
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
          _buildInfoRow('Nombre', tbecerros['nombrebece'] ?? 'No especificado'),
          _buildInfoRow('Arete', tbecerros['aretebece'] ?? 'No especificado'),
          _buildInfoRow('Peso', tbecerros['pesobece'] ?? 'No especificado'),
          _buildInfoRow('Sexo', tbecerros['sexobece'] ?? 'No especificado'),
          _buildInfoRow(
            'Fecha Nacimiento',
            tbecerros['nacimientobece'] ?? 'No especificado',
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
          _buildInfoRow('razabece', tbecerros['razabece'] ?? 'No especificado'),
          _buildInfoRow(
            'nacimientobece',
            tbecerros['nacimientobece'] ?? 'No especificado',
          ),
          _buildInfoRow('Corral', tbecerros['corralbece'] ?? 'No especificado'),
          _buildInfoRow(
            'Estatus',
            tbecerros['estatusbece'] ?? 'No especificado',
          ),

          _buildInfoRow(
            'Arete Madre',
            tbecerros['aretemadre'] ?? 'No especificado',
          ),
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
            tbecerros['observacionbece'].toString(),
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

void _showHealthHistory(BuildContext context, Map<String, dynamic> tbecerros) {
  showDialog(
    context: context,
    builder: (context) => HealthHistoryDialog(tbecerros: tbecerros),
  );
}

// esta clase es para mostrar el historial d salud del animal desde el botoncito, sale ocmo popup xD
class HealthHistoryDialog extends StatefulWidget {
  final Map<String, dynamic> tbecerros;

  const HealthHistoryDialog({super.key, required this.tbecerros});

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
        widget.tbecerros['aretebece'] ?? '',
        'becerro',
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
              'Historial del arete: ${widget.tbecerros['aretebece']}',
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
                              if (registro['condicionsalud'] != null)
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

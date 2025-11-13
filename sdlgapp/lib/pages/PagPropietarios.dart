import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sdlgapp/pages/db_helper.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Tomar foto con cámara y convertir a bytes
  static Future<Uint8List?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image != null ? await image.readAsBytes() : null;
    } catch (e) {
      print("Error tomando foto: $e");
      return null;
    }
  }

  // Seleccionar de galería y convertir a bytes
  static Future<Uint8List?> pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image != null ? await image.readAsBytes() : null;
    } catch (e) {
      print("Error seleccionando foto: $e");
      return null;
    }
  }

  // Convertir base64 string de vuelta a bytes para mostrar imagen
  static Uint8List? base64ToBytes(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      // Si el string contiene "data:image", extraer solo la parte base64
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      return base64Decode(base64String);
    } catch (e) {
      print("Error decodificando base64: $e");
      return null;
    }
  }

  // Convertir bytes a base64 string (para mostrar)
  static String? bytesToBase64(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      return base64Encode(bytes);
    } catch (e) {
      print("Error codificando a base64: $e");
      return null;
    }
  }

  // Crear Image widget desde bytes
  static Widget bytesToImage(Uint8List? bytes) {
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderIcon();
        },
      );
    } else {
      return _buildPlaceholderIcon();
    }
  }

  // Crear Image widget desde base64 string (para compatibilidad)
  static Widget base64ToImage(String? base64String) {
    final bytes = base64ToBytes(base64String);
    return bytesToImage(bytes);
  }

  // Crear MemoryImage para CircleAvatar desde bytes
  static MemoryImage? bytesToMemoryImage(Uint8List? bytes) {
    return bytes != null && bytes.isNotEmpty ? MemoryImage(bytes) : null;
  }

  // Crear MemoryImage para CircleAvatar desde base64 (para compatibilidad)
  static MemoryImage? base64ToMemoryImage(String? base64String) {
    final bytes = base64ToBytes(base64String);
    return bytesToMemoryImage(bytes);
  }

  static Widget _buildPlaceholderIcon() {
    return Icon(Icons.photo_camera, size: 50, color: Colors.grey[400]);
  }

  // Verificar si los bytes de imagen son válidos
  static bool isImageBytesValid(Uint8List? bytes) {
    return bytes != null && bytes.isNotEmpty;
  }

  // Verificar si una imagen en base64 es válida
  static bool isBase64ImageValid(String? base64String) {
    if (base64String == null || base64String.isEmpty) return false;
    try {
      base64ToBytes(base64String);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Comprimir imagen si es muy grande
  static Future<Uint8List?> compressImageIfNeeded(Uint8List? imageBytes) async {
    if (imageBytes == null) return null;

    // Verificar tamaño (5MB como en tu software)
    if (imageBytes.length <= 5 * 1024 * 1024) {
      return imageBytes;
    }

    try {
      // Comprimir la imagen
      final compressedImage = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 800,
        minWidth: 800,
        quality: 85,
      );
      return Uint8List.fromList(compressedImage);
    } catch (e) {
      print("Error comprimiendo imagen: $e");
      return imageBytes; // Retornar original si falla la compresión
    }
  }
}

class PagPropietarios extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final VoidCallback onRefresh;
  final bool isLoading;

  const PagPropietarios({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.isLoading,
  });

  void _showPropietarioDetails(
    Map<String, dynamic> tpropietarios,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          PropietarioDetailsDialog(tpropietarios: tpropietarios),
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
                  barHintText: 'Buscar Propietario',
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
                              title: Text(
                                "Escribe para buscar propietarios...",
                              ),
                              textColor: Colors.grey,
                            ),
                          ];
                        }
                        return _buildSearchSuggestions(
                          controller.text,
                          context,
                        );
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
                onPressed: () => _showAddPropietarioDialog(context),
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 182, 128, 128),
                ),
                tooltip: 'Agregar Propietario',
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
            Icon(Icons.person, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "No hay propietarios registrados",
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
        final tpropietarios = data[index];
        return _buildPropietarioCard(tpropietarios, context);
      },
    );
  }

  Widget _buildPropietarioCard(
    Map<String, dynamic> tpropietarios,
    BuildContext context,
  ) {
    final fotoData = tpropietarios['fotoprop'];
    Uint8List? imageBytes;

    if (fotoData is Uint8List) {
      // Si ya viene como bytes, usar directamente
      imageBytes = fotoData;
    } else if (fotoData is String) {
      // Si viene como base64, convertir a bytes
      imageBytes = ImageService.base64ToBytes(fotoData);
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: _buildPropietarioAvatar(imageBytes),
        title: Text(
          tpropietarios['nombreprop'] ?? 'Sin Nombre',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),

            if (tpropietarios['telprop'] != null)
              Text('Teléfono: ${tpropietarios['telprop']}'),

            if (tpropietarios['correoprop'] != null)
              Text('Correo: ${tpropietarios['correoprop']}'),

            if (tpropietarios['dirprop'] != null)
              Text('Dirección: ${tpropietarios['dirprop']}'),

            if (tpropietarios['rfcprop'] != null)
              Text('RFC: ${tpropietarios['rfcprop']}'),

            if (tpropietarios['psgprop'] != null)
              Text('PSG: ${tpropietarios['psgprop']}'),

            if (tpropietarios['uppprop'] != null)
              Text('UPP: ${tpropietarios['uppprop']}'),

            if (tpropietarios['observacionprop'] != null)
              Text('Observaciones: ${tpropietarios['observacionprop']}'),

            SizedBox(height: 4),
            Text(
              'ID: ${tpropietarios['idprop']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => _showPropietarioDetails(tpropietarios, context),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditPropietarioDialog(context, tpropietarios);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, tpropietarios);
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

  Widget _buildPropietarioAvatar(Uint8List? imageBytes) {
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        final memoryImage = ImageService.bytesToMemoryImage(imageBytes);
        if (memoryImage != null) {
          return CircleAvatar(
            radius: 25,
            backgroundImage: memoryImage,
            onBackgroundImageError: (exception, stackTrace) {
              print("Error cargando imagen: $exception");
            },
          );
        }
      } catch (e) {
        print("Error cargando imagen: $e");
      }
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      backgroundColor: const Color.fromARGB(
        255,
        182,
        128,
        128,
      ).withOpacity(0.2),
      child: Icon(Icons.person, color: const Color.fromARGB(255, 137, 77, 77)),
    );
  }

  Future<List<Widget>> _buildSearchSuggestions(
    String query,
    BuildContext context,
  ) async {
    try {
      final resultados = await SQLHelper.searchPropietarios(query);

      if (resultados.isEmpty) {
        return [
          ListTile(
            title: Text("No se encontraron propietarios"),
            textColor: Colors.grey,
          ),
        ];
      }

      return resultados.map((tpropietarios) {
        return ListTile(
          leading: Icon(
            Icons.person,
            color: const Color.fromARGB(255, 137, 77, 77),
          ),
          title: Text(tpropietarios['nombreprop'] ?? 'Sin nombre'),
          subtitle: Text(
            'Teléfono: ${tpropietarios['telprop']} - Dirección: ${tpropietarios['dirprop']}',
          ),
          onTap: () {
            Navigator.pop(context); // Cerrar el SearchAnchor
            _showPropietarioDetails(tpropietarios, context);
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

  void _showAddPropietarioDialog(BuildContext context) {
    final nombreController = TextEditingController();
    final telController = TextEditingController();
    final dirController = TextEditingController();
    final correoController = TextEditingController();
    final rfcController = TextEditingController();
    final psgController = TextEditingController();
    final uppController = TextEditingController();
    final observacionController = TextEditingController();

    Uint8List? selectedImageBytes;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Agregar Propietario"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selector de imagen
                    _buildImageSelectorBytes(setState, selectedImageBytes, (
                      Uint8List? newImageBytes,
                    ) {
                      selectedImageBytes = newImageBytes;
                    }, dialogContext),
                    SizedBox(height: 16),

                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: telController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: dirController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: correoController,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: rfcController,
                      decoration: InputDecoration(
                        labelText: 'RFC',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: psgController,
                      decoration: InputDecoration(
                        labelText: 'PSG',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: uppController,
                      decoration: InputDecoration(
                        labelText: 'UPP',
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
                    if (nombreController.text.isEmpty ||
                        telController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Nombre y Teléfono son obligatorios'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Uint8List? fotoFinal =
                        await ImageService.compressImageIfNeeded(
                          selectedImageBytes,
                        );

                    final nuevoPropietario = {
                      'nombreprop': nombreController.text,
                      'telprop': telController.text,
                      'correoprop': correoController.text,
                      'dirprop': dirController.text,
                      'rfcprop': rfcController.text,
                      'psgprop': psgController.text,
                      'uppprop': uppController.text,
                      'observacionprop': observacionController.text,
                      'fotoprop': fotoFinal,
                    };

                    try {
                      await SQLHelper.createPropietario(nuevoPropietario);
                      onRefresh();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Propietario agregado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar propietario: $e'),
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

  Widget _buildImageSelectorBytes(
    StateSetter setState,
    Uint8List? selectedImageBytes,
    Function(Uint8List?) onImageChanged,
    BuildContext dialogContext,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Marca o identificación visual del propietario',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Vista previa de la imagen
        Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey),
            color: Colors.grey[100],
          ),
          child: selectedImageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    selectedImageBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderIcon();
                    },
                  ),
                )
              : _buildPlaceholderIcon(),
        ),

        SizedBox(height: 10),

        // Botones de cámara y galería
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final imageBytes = await ImageService.takePhoto();
                if (imageBytes != null) {
                  setState(() {
                    onImageChanged(imageBytes);
                  });
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Imagen tomada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: Icon(Icons.camera_alt),
              label: Text('Cámara'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final imageBytes = await ImageService.pickPhoto();
                if (imageBytes != null) {
                  setState(() {
                    onImageChanged(imageBytes);
                  });
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Imagen seleccionada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: Icon(Icons.photo_library),
              label: Text('Galería'),
            ),
          ],
        ),

        // Botón para quitar foto
        if (selectedImageBytes != null)
          TextButton(
            onPressed: () {
              setState(() {
                onImageChanged(null);
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

  void _showEditPropietarioDialog(
    BuildContext context,
    Map<String, dynamic> tpropietarios,
  ) {
    final nombreController = TextEditingController(
      text: tpropietarios['nombreprop']?.toString() ?? '',
    );

    final telController = TextEditingController(
      text: tpropietarios['telprop']?.toString() ?? '',
    );

    final dirController = TextEditingController(
      text: tpropietarios['dirprop']?.toString() ?? '',
    );

    final correoController = TextEditingController(
      text: tpropietarios['correoprop']?.toString() ?? '',
    );

    final rfcController = TextEditingController(
      text: tpropietarios['rfcprop']?.toString() ?? '',
    );

    final psgController = TextEditingController(
      text: tpropietarios['psgprop']?.toString() ?? '',
    );

    final uppController = TextEditingController(
      text: tpropietarios['uppprop']?.toString() ?? '',
    );

    final observacionController = TextEditingController(
      text: tpropietarios['observacionprop']?.toString() ?? '',
    );

    Uint8List? selectedImageBytes;

    final fotoData = tpropietarios['fotoprop'];
    if (fotoData is Uint8List) {
      selectedImageBytes = fotoData;
    } else if (fotoData is String) {
      selectedImageBytes = ImageService.base64ToBytes(fotoData);
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Editar Propietario"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildImageSelectorBytes(setState, selectedImageBytes, (
                      Uint8List? newImageBytes,
                    ) {
                      selectedImageBytes = newImageBytes;
                    }, dialogContext),
                    SizedBox(height: 16),

                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: telController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: dirController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: correoController,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: rfcController,
                      decoration: InputDecoration(
                        labelText: 'RFC',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: psgController,
                      decoration: InputDecoration(
                        labelText: 'PSG',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: uppController,
                      decoration: InputDecoration(
                        labelText: 'UPP',
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
                    if (tpropietarios['idprop'] == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ID del propietario no válido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Uint8List? fotoFinal =
                        await ImageService.compressImageIfNeeded(
                          selectedImageBytes,
                        );

                    final propietarioactualizado = {
                      'nombreprop': nombreController.text,
                      'telprop': telController.text,
                      'correoprop': correoController.text,
                      'dirprop': dirController.text,
                      'rfcprop': rfcController.text,
                      'psgprop': psgController.text,
                      'uppprop': uppController.text,
                      'observacionprop': observacionController.text,
                      'fotoprop': fotoFinal,
                    };

                    try {
                      await SQLHelper.updatePropietario(
                        tpropietarios['idprop'],
                        propietarioactualizado,
                      );
                      onRefresh();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Propietario actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al actualizar el propietario: $e',
                          ),
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
    Map<String, dynamic> tpropietarios,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar Propietario"),
          content: Text(
            "¿Estás seguro de que quieres eliminar a ${tpropietarios['nombreprop']}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await SQLHelper.deletePropietario(tpropietarios['idprop']);
                  onRefresh();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Propietario eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar propietario: $e'),
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

class PropietarioDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> tpropietarios;

  const PropietarioDetailsDialog({super.key, required this.tpropietarios});

  @override
  Widget build(BuildContext context) {
    final fotoData = tpropietarios['fotoprop'];
    Uint8List? imageBytes;

    if (fotoData is Uint8List) {
      imageBytes = fotoData;
    } else if (fotoData is String) {
      imageBytes = ImageService.base64ToBytes(fotoData);
    }

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
                    'Detalles del propietario',
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

              // Foto del propietario
              _buildPhotoSection(imageBytes),

              SizedBox(height: 20),

              // Información básica
              _buildBasicInfoSection(),

              SizedBox(height: 20),

              // Información adicional
              _buildAdditionalInfoSection(),

              if (tpropietarios['observacionprop'] != null &&
                  tpropietarios['observacionprop'].toString().isNotEmpty)
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

  Widget _buildPhotoSection(Uint8List? imageBytes) {
    return Center(
      child: imageBytes != null && imageBytes.isNotEmpty
          ? Container(
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
                child: ImageService.bytesToImage(imageBytes),
              ),
            )
          : _buildPlaceholderPhoto(),
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
          _buildInfoRow(
            'Nombre',
            tpropietarios['nombreprop'] ?? 'No especificado',
          ),
          _buildInfoRow(
            'Telefono',
            tpropietarios['telprop'] ?? 'No especificado',
          ),
          _buildInfoRow(
            'Correo electrónico',
            tpropietarios['correoprop'] ?? 'No especificado',
          ),
          _buildInfoRow(
            'Dirección',
            tpropietarios['dirprop'] ?? 'No especificado',
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
          _buildInfoRow('RFC', tpropietarios['rfcprop'] ?? 'No especificado'),
          _buildInfoRow('PSG', tpropietarios['psgprop'] ?? 'No especificado'),
          _buildInfoRow('UPP', tpropietarios['uppprop'] ?? 'No especificado'),
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
            tpropietarios['observacionprop'].toString(),
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

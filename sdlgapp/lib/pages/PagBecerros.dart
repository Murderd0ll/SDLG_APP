import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:sdlgapp/pages/db_helper.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Tomar foto con cámara y convertir a bytes
  static Future<Uint8List?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
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
        imageQuality: 70,
        maxWidth: 800,
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

  // Crear Image widget desde base64 string
  static Widget base64ToImage(String? base64String) {
    final bytes = base64ToBytes(base64String);
    if (bytes != null) {
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

  // Crear MemoryImage para CircleAvatar
  static MemoryImage? base64ToMemoryImage(String? base64String) {
    final bytes = base64ToBytes(base64String);
    return bytes != null ? MemoryImage(bytes) : null;
  }

  static Widget _buildPlaceholderIcon() {
    return Icon(Icons.photo_camera, size: 50, color: Colors.grey[400]);
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
}

final List<String> opcionesMedicinaPreventiva = [
  'Vacuna contra Brucelosis',
  'Vacuna contra IBR',
  'Vacuna contra BVD',
  'Bacterina contra clostridiosis',
  'Bacterina contra pasteurelosis',
  'Baño garrapaticida',
  'Control de moscas',
  'Desparacitación interna',
  'Desparacitación externa',
  'Cortado de cuernos',
  'Rebajado de pezuñas',
];

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
                onPressed: () => _showAddBecerroDialog(context),
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 182, 128, 128),
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
            Icon(Symbols.pediatrics, size: 64, color: Colors.grey[400]),
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
    final imageBase64 = tbecerros['fotobece']?.toString();

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: _buildBecerroAvatar(imageBase64),
        title: Text(
          tbecerros['aretebece'] ?? 'Sin arete',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),

            if (tbecerros['nombrebece'] != null)
              Text('Nombre: ${tbecerros['nombrebece']}'),

            if (tbecerros['pesobece'] != null)
              Text('Peso al nacer: ${tbecerros['pesobece']} kg'),

            if (tbecerros['sexobece'] != null)
              Text('Sexo: ${tbecerros['sexobece']}'),

            if (tbecerros['razabece'] != null)
              Text('Raza: ${tbecerros['razabece']}'),

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
              value: 'health',
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Salud'),
                ],
              ),
            ),
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

  Widget _buildBecerroAvatar(String? imageBase64) {
    if (imageBase64 != null &&
        imageBase64.isNotEmpty &&
        ImageService.isBase64ImageValid(imageBase64)) {
      try {
        final memoryImage = ImageService.base64ToMemoryImage(imageBase64);
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
        print("Error decodificando imagen: $e");
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
      child: Icon(
        Symbols.pediatrics,
        color: const Color.fromARGB(255, 137, 77, 77),
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

  Future<List<Widget>> _buildSearchSuggestions(
    String query,
    BuildContext context,
  ) async {
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
            Symbols.pediatrics,
            color: const Color.fromARGB(255, 77, 137, 95),
          ),
          title: Text(tbecerros['nombrebece'] ?? 'Sin nombre'),
          subtitle: Text(
            'Arete: ${tbecerros['aretebece']} - Sexo: ${tbecerros['sexobece']}',
          ),
          onTap: () {
            Navigator.pop(context);
            _showBecerroDetails(tbecerros, context);
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
    final aretemadreController = TextEditingController();
    final observacionbeceController = TextEditingController();

    String? estatusbece;
    String? sexoSeleccionado;
    String? corralSeleccionado;
    Uint8List? selectedImageBytes;

    List<String> corralesDisponibles = [];
    bool cargandoCorrales = true;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _cargarCorrales() async {
              try {
                final corrales = await SQLHelper.getNombresCorrales();
                setState(() {
                  corralesDisponibles = corrales;
                  cargandoCorrales = false;
                });
              } catch (e) {
                print("Error cargando corrales: $e");
                setState(() {
                  cargandoCorrales = false;
                });
              }
            }

            if (cargandoCorrales) {
              _cargarCorrales();
            }

            return AlertDialog(
              title: Text("Agregar Becerro"),
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

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: corralSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Corral',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          // Opción para "Sin corral"
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'Selecciona un corral',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          // Opciones de corrales existentes
                          ...corralesDisponibles.map((String corral) {
                            return DropdownMenuItem(
                              value: corral,
                              child: Text(corral),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            corralSeleccionado = newValue;
                          });
                        },
                        hint: cargandoCorrales
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Cargando corrales...'),
                                ],
                              )
                            : Text('Selecciona un corral'),
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
                    if (aretebeceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('El arete es obligatorio'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (pesobeceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('El peso es obligatorio'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (sexoSeleccionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('El sexo es obligatorio'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final nuevoBecerro = {
                      'aretebece': aretebeceController.text,
                      'nombrebece': nombrebeceController.text,
                      'pesobece': pesobeceController.text,
                      'sexobece': sexoSeleccionado,
                      'razabece': razabeceController.text,
                      'nacimientobece': nacimientobeceController.text,
                      'corralbece': corralSeleccionado ?? '',
                      'estatusbece': estatusbece,
                      'aretemadre': aretemadreController.text,
                      'observacionbece': observacionbeceController.text,
                      'fotobece': selectedImageBytes,
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

  Widget _buildImageSelectorBytes(
    StateSetter setState,
    Uint8List? selectedImageBytes,
    Function(Uint8List?) onImageChanged,
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
    Uint8List? selectedImageBytes;
    List<String> medicinasSeleccionadas = [];

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
                            Symbols.pediatrics, // Usando Material Symbols
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
                      ),
                    ),
                    SizedBox(height: 12),

                    _buildMedicinaPreventivaSection(medicinasSeleccionadas, (
                      List<String> nuevasSelecciones,
                    ) {
                      setState(() {
                        medicinasSeleccionadas = nuevasSelecciones;
                      });
                    }, dialogContext),
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

                    // Selector de imagen adaptado para salud
                    _buildImageSelectorForHealthBytes(
                      setState,
                      selectedImageBytes,
                      (Uint8List? newImageBytes) {
                        selectedImageBytes = newImageBytes;
                      },
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
                    String medicinasString = medicinasSeleccionadas.join(', ');

                    final nuevoRegistro = {
                      'areteanimal': tbecerros['aretebece'] ?? '',
                      'tipoanimal': 'becerro',
                      'nomvet': veterinarioController.text,
                      'procedimiento': procedimientoController.text,
                      'condicionsalud': condicion,
                      'medprev': medicinasString,
                      'fecharev': fechaRevisionController.text,
                      'observacionsalud': observacionesController.text,
                      'archivo': selectedImageBytes,
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

  Widget _buildImageSelectorForHealthBytes(
    StateSetter setState,
    Uint8List? selectedImageBytes,
    Function(Uint8List?) onImageChanged,
    BuildContext dialogContext,
  ) {
    return Column(
      children: [
        // Título de la imagen
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Imagen del Procedimiento Médico',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 137, 77, 77),
            ),
          ),
        ),

        // Subtítulo opcional
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Documentación visual del tratamiento',
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
            child: Text('Quitar imagen', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildMedicinaPreventivaSection(
    List<String> seleccionadas,
    Function(List<String>) onSeleccionChanged,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la sección
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.medical_services, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Medicina Preventiva', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),

        // Contenedor de checkboxes
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.green[50],
          ),
          child: Column(
            children: [
              // Botón para expandir/contraer
              InkWell(
                onTap: () {
                  _mostrarDialogoMedicinasCompleto(
                    context,
                    seleccionadas,
                    onSeleccionChanged,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Med. Preventiva - Manejo',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.green),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 8),

              // Mostrar selecciones actuales
              if (seleccionadas.isNotEmpty) ...[
                Text(
                  'Seleccionadas:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: seleccionadas.map((medicina) {
                    return Chip(
                      label: Text(medicina, style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.green[100],
                      deleteIcon: Icon(Icons.close, size: 14),
                      onDeleted: () {
                        List<String> nuevasSelecciones = List.from(
                          seleccionadas,
                        );
                        nuevasSelecciones.remove(medicina);
                        onSeleccionChanged(nuevasSelecciones);
                      },
                    );
                  }).toList(),
                ),
              ] else ...[
                Text(
                  'No hay opciones seleccionadas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  //Diálogo completo para selección de medicinas
  void _mostrarDialogoMedicinasCompleto(
    BuildContext context,
    List<String> seleccionadas,
    Function(List<String>) onSeleccionChanged,
  ) {
    List<String> seleccionesTemporales = List.from(seleccionadas);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.medical_services, color: Colors.green),
                SizedBox(width: 8),
                Text('Medicina preventiva\ny Manejo'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lista de checkboxes
                  Container(
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: opcionesMedicinaPreventiva.length,
                      itemBuilder: (context, index) {
                        final medicina = opcionesMedicinaPreventiva[index];
                        return CheckboxListTile(
                          title: Text(medicina),
                          value: seleccionesTemporales.contains(medicina),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                seleccionesTemporales.add(medicina);
                              } else {
                                seleccionesTemporales.remove(medicina);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),

                  // Contador de selecciones
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${seleccionesTemporales.length} opciones seleccionadas',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
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
                onPressed: () {
                  onSeleccionChanged(seleccionesTemporales);
                  Navigator.pop(context);
                },
                child: Text('Aceptar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Método para el selector de imágenes en salud

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
    final aretemadreController = TextEditingController(
      text: tbecerros['aretemadre']?.toString() ?? '',
    );
    final observacionbeceController = TextEditingController(
      text: tbecerros['observacionbece']?.toString() ?? '',
    );

    String? estatusbece = tbecerros['estatusbece']?.toString();
    String? sexoSeleccionado = tbecerros['sexobece']?.toString();
    String? corralSeleccionado = tbecerros['corralbece']?.toString();

    Uint8List? selectedImageBytes;
    String? existingImageBase64 = tbecerros['fotobece']?.toString();

    List<String> corralesDisponibles = [];
    bool cargandoCorrales = true;

    // Cargar imagen existente si hay una
    if (existingImageBase64 != null && existingImageBase64.isNotEmpty) {
      selectedImageBytes = ImageService.base64ToBytes(existingImageBase64);
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            Future<void> _cargarCorrales() async {
              try {
                final corrales = await SQLHelper.getNombresCorrales();
                setState(() {
                  corralesDisponibles = corrales;
                  cargandoCorrales = false;
                });
              } catch (e) {
                print("Error cargando corrales: $e");
                setState(() {
                  cargandoCorrales = false;
                });
              }
            }

            if (cargandoCorrales) {
              _cargarCorrales();
            }
            return AlertDialog(
              title: Text("Editar Becerro"),
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

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: _validarValorCorral(
                          corralSeleccionado,
                          corralesDisponibles,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Corral',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'Selecciona un corral',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ...corralesDisponibles.map((String corral) {
                            return DropdownMenuItem(
                              value: corral,
                              child: Text(corral),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            corralSeleccionado = newValue;
                          });
                        },
                        hint: cargandoCorrales
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Cargando corrales...'),
                                ],
                              )
                            : Text('Selecciona un corral'),
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
                      'corralbece': corralSeleccionado ?? '',
                      'estatusbece': estatusbece,
                      'aretemadre': aretemadreController.text,
                      'observacionbece': observacionbeceController.text,
                      'fotobece': selectedImageBytes,
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

  String? _validarValorCorral(String? valor, List<String> corralesDisponibles) {
    if (valor == null) return null;

    // Verificar si el valor existe exactamente en la lista
    if (corralesDisponibles.contains(valor)) {
      return valor;
    }

    // Buscar coincidencias ignorando case sensitivity (mayus o minus xd)
    final valorLower = valor.toLowerCase();
    for (final corral in corralesDisponibles) {
      if (corral.toLowerCase() == valorLower) {
        return corral; // devuelve el valor correcto de la lista
      }
    }

    // Si no se encuentra, retornar null para evitar el error y se trabe la app
    print(
      'Valor de corral no encontrado: "$valor". Corrales disponibles: $corralesDisponibles',
    );
    return null;
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

  Widget _buildPhotoSection(String? imageBase64) {
    return Center(
      child:
          imageBase64 != null &&
              imageBase64.isNotEmpty &&
              ImageService.isBase64ImageValid(imageBase64)
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
                child: ImageService.base64ToImage(imageBase64),
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

  void _showImageDialog(String imageBase64, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 137, 77, 77),
                ),
              ),
            ),
            // CAMBIO: Usar base64 en lugar de File
            if (ImageService.isBase64ImageValid(imageBase64))
              Container(
                width: 300,
                height: 300,
                child: ImageService.base64ToImage(imageBase64),
              )
            else
              Container(
                width: 300,
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Imagen no disponible'),
                    ],
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Historial de Salud de\n${widget.tbecerros['nombrebece']}',
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

              // Información del becerro
              _buildBecerroInfoSection(),

              SizedBox(height: 20),

              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_registrosSalud.isEmpty)
                _buildEmptyState()
              else
                _buildRegistrosSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBecerroInfoSection() {
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
            'Información del Becerro',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 137, 77, 77),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            'Nombre',
            widget.tbecerros['nombrebece'] ?? 'No especificado',
          ),
          _buildInfoRow(
            'Arete',
            widget.tbecerros['aretebece'] ?? 'No especificado',
          ),
          _buildInfoRow(
            'Peso',
            widget.tbecerros['pesobece'] ?? 'No especificado',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 245, 245),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 232, 218, 218)),
      ),
      child: Column(
        children: [
          Icon(
            Symbols.medical_services, // Usando el icono de Material Symbols
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No hay registros de salud',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega el primer registro desde el menú de opciones',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registros de Salud (${_registrosSalud.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 137, 77, 77),
          ),
        ),
        SizedBox(height: 16),
        ..._registrosSalud.asMap().entries.map((entry) {
          final index = entry.key;
          final registro = entry.value;
          return _buildRegistroCard(registro, index);
        }).toList(),
      ],
    );
  }

  Widget _buildRegistroCard(Map<String, dynamic> registro, int index) {
    final hasImage =
        registro['archivo'] != null &&
        registro['archivo'].toString().isNotEmpty &&
        ImageService.isBase64ImageValid(registro['archivo'].toString());

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 245, 245),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 232, 218, 218)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del registro
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 137, 77, 77).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.medical_services, // Usando Material Symbols
                  color: const Color.fromARGB(255, 137, 77, 77),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registro ${index + 1} - ${registro['fecharev'] ?? 'Fecha no especificada'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 137, 77, 77),
                      fontSize: 16,
                    ),
                  ),
                ),
                if (hasImage)
                  IconButton(
                    icon: Icon(Icons.photo_library, color: Colors.blue),
                    onPressed: () {
                      _showImageDialog(
                        registro['archivo'].toString(),
                        registro['procedimiento'] ?? 'Imagen del procedimiento',
                      );
                    },
                  ),
              ],
            ),
          ),

          // Contenido del registro
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRegistroInfoRow(
                  'Veterinario',
                  registro['nomvet'] ?? 'No especificado',
                ),
                _buildRegistroInfoRow(
                  'Procedimiento',
                  registro['procedimiento'] ?? 'No especificado',
                ),
                _buildRegistroInfoRow(
                  'Condición de Salud',
                  registro['condicionsalud'] ?? 'No especificado',
                ),
                _buildRegistroInfoRow(
                  'Med. Preventiva - Manejo',
                  registro['medprev'] ?? 'No especificado',
                ),
                _buildRegistroInfoRow(
                  'Fecha de Revisión',
                  registro['fecharev'] ?? 'No especificada',
                ),
                if (registro['observacionsalud'] != null &&
                    registro['observacionsalud'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        'Observaciones:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 137, 77, 77),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        registro['observacionsalud'].toString(),
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
              ],
            ),
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
            width: 100,
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

  Widget _buildRegistroInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
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

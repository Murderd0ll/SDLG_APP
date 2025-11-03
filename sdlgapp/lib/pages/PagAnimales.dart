import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sdlgapp/pages/db_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
            FaIcon(FontAwesomeIcons.cow, size: 64, color: Colors.grey[400]),
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
    final bool eshembra =
        tganado['sexogdo']?.toString().toLowerCase() == 'hembra';

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
                child: FaIcon(
                  FontAwesomeIcons.cow,
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
            } else if (value == 'reproduccion') {
              _showReproductionOptions(context, tganado);
            } else if (value == 'edit') {
              _showEditAnimalDialog(context, tganado);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, tganado);
            }
          },

          itemBuilder: (BuildContext context) {
            final List<PopupMenuEntry<String>> items = [
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
            ];
            if (eshembra) {
              items.add(
                PopupMenuItem<String>(
                  value: 'reproduccion',
                  child: Row(
                    children: [
                      Icon(Icons.family_restroom, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Reproducción'),
                    ],
                  ),
                ),
              );
            }
            items.addAll([
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
            ]);
            return items;
          },
        ),
      ),
    );
  }

  void _showReproductionOptions(
    BuildContext context,
    Map<String, dynamic> animal,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reproducción - ${animal['areteanimal']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 137, 77, 77),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.pregnant_woman, color: Colors.purple),
              title: Text('Registrar'),
              onTap: () {
                Navigator.pop(context);
                _showAddPregnancyDialog(context, animal);
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.orange),
              title: Text('Ver Historial Reproductivo'),
              onTap: () {
                Navigator.pop(context);
                _showReproductionHistory(context, animal);
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

  // Métodos placeholder para las funcionalidades de reproducción
  void _showAddPregnancyDialog(
    BuildContext context,
    Map<String, dynamic> animal,
  ) {
    final cantpartosController = TextEditingController();
    final fServicioActualController = TextEditingController();
    final fNuevoServicioController = TextEditingController();
    final fAproxPartoController = TextEditingController();
    final observacionController = TextEditingController();

    String? cargada;
    String? tecnica;

    void _calcularFechas(String fechaServicio) {
      if (fechaServicio.isEmpty) return;

      try {
        final fechaServicioDate = DateTime.parse(fechaServicio);

        // Calcular fecha aproximada de parto (9 meses después)
        final fechaParto = DateTime(
          fechaServicioDate.year,
          fechaServicioDate.month + 9,
          fechaServicioDate.day,
        );

        // Calcular fecha de próximo servicio (3 meses después del parto = 12 meses después del servicio)
        final fechaProximoServicio = DateTime(
          fechaServicioDate.year,
          fechaServicioDate.month + 12,
          fechaServicioDate.day,
        );

        // Actualizar los controladores
        fAproxPartoController.text =
            "${fechaParto.year}-${fechaParto.month.toString().padLeft(2, '0')}-${fechaParto.day.toString().padLeft(2, '0')}";
        fNuevoServicioController.text =
            "${fechaProximoServicio.year}-${fechaProximoServicio.month.toString().padLeft(2, '0')}-${fechaProximoServicio.day.toString().padLeft(2, '0')}";
      } catch (e) {
        print('Error calculando fechas: $e');
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Agregar Registro de Reproducción"),
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
                          FaIcon(
                            FontAwesomeIcons.cow,
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

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: cargada,
                        decoration: InputDecoration(
                          labelText: 'Se encuentra cargada?',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: 'Si', child: Text('Si')),
                          DropdownMenuItem(value: 'No', child: Text('No')),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            cargada = newValue;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: tecnica,
                        decoration: InputDecoration(
                          labelText: 'Tecnica de Preñez',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Monta natural',
                            child: Text('Monta natural'),
                          ),
                          DropdownMenuItem(
                            value: 'Inseminación artificial',
                            child: Text('Inseminación artificial'),
                          ),
                          DropdownMenuItem(
                            value: 'Inseminación a tiempo fijo',
                            child: Text('Inseminación a tiempo fijo'),
                          ),
                          DropdownMenuItem(
                            value: 'Transferencia de embriones',
                            child: Text('Transferencia de embriones'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            tecnica = newValue;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: cantpartosController,
                      decoration: InputDecoration(
                        labelText: 'Cantidad de Partos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: fServicioActualController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Servicio Actual',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDateForReproduction(
                            dialogContext,
                            fServicioActualController,
                            (fechaSeleccionada) {
                              _calcularFechas(fechaSeleccionada);
                            },
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        // Calcular automáticamente cuando se escribe manualmente
                        if (value.length == 10) {
                          // Formato YYYY-MM-DD
                          _calcularFechas(value);
                        }
                      },
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: fAproxPartoController,
                      decoration: InputDecoration(
                        labelText: 'Fecha Aproximada de Parto',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 222, 222, 224),
                      ),
                      readOnly:
                          true, // Solo lectura porque se calcula d forma automatica
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: fNuevoServicioController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Próximo Servicio',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 222, 222, 224),
                      ),
                      readOnly:
                          true, // Solo lectura porque se calcula d forma automatica
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: observacionController,
                      maxLines: 3,
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (cargada == null ||
                        fServicioActualController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Estado de servicio y Fecha de Servicio Actual son obligatorios',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final nuevoRegistro = {
                      'areteanimal': animal['aretegdo'] ?? '',
                      'cargada': cargada ?? '',
                      'cantpartos': cantpartosController.text,
                      'fservicioactual': fServicioActualController.text,
                      'faproxparto': fAproxPartoController.text,
                      'fnuevoservicio': fNuevoServicioController.text,
                      'tecnica': tecnica ?? '',
                      'observacion': observacionController.text,
                    };

                    try {
                      await SQLHelper.createRegistroReproduccion(nuevoRegistro);
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Registro de reproducción agregado exitosamente',
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

  // este es especificamente para el de reproducción xddd
  void _selectDateForReproduction(
    BuildContext context,
    TextEditingController controller,
    Function(String)
    onDateSelected, // Callback q pedia para la suma d meses y eso
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formattedDate =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      controller.text = formattedDate;

      // se llama al callback para calcular las fechas automáticamente
      onDateSelected(formattedDate);
    }
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
          leading: FaIcon(
            FontAwesomeIcons.cow,
            color: const Color.fromARGB(255, 137, 77, 77),
          ),
          title: Text(tganado['nombregdo'] ?? 'Sin nombre'),
          subtitle: Text(
            'Arete: ${tganado['aretegdo']} - Sexo: ${tganado['sexogdo']}',
          ),
          onTap: () {
            Navigator.pop(context); // Cerrar el SearchAnchor
            _showAnimalDetails(tganado, context);
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

  void _showAddAnimalDialog(BuildContext context) {
    final areteController = TextEditingController();
    final nombreController = TextEditingController();
    final razaController = TextEditingController();
    final fechaNacimientoController = TextEditingController();
    final alimentoController = TextEditingController();
    final observacionController = TextEditingController();

    String? produccion;
    String? estatusgdo;
    String? sexoSeleccionado;
    String? corralSeleccionado;
    File? selectedImage;
    String? imagePath;

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

                    TextField(
                      controller: alimentoController,
                      decoration: InputDecoration(
                        labelText: 'Alimento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: produccion,
                        decoration: InputDecoration(
                          labelText: 'Tipo de producción',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Exportacion',
                            child: Text('Exportación'),
                          ),
                          DropdownMenuItem(
                            value: 'Rastro',
                            child: Text('Rastro'),
                          ),
                          DropdownMenuItem(value: 'Cria', child: Text('Cría')),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            produccion = newValue;
                          });
                        },
                        hint: Text('Selecciona la producción'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona la producción';
                          }
                          return null;
                        },
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
                      'corralgdo': corralSeleccionado ?? '',
                      'alimentogdo': alimentoController.text,
                      'prodgdo': produccion,
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
    final fechaRevisionController = TextEditingController();
    final observacionesController = TextEditingController();

    File? selectedImage;
    String? imagePath;
    String? condicionSalud;
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
                          FaIcon(
                            FontAwesomeIcons.cow,
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

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: condicionSalud,
                        decoration: InputDecoration(
                          labelText: 'Condición de salud',
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
                            condicionSalud = newValue;
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

                    // Selector de imagen para el registro de salud
                    _buildImageSelectorForHealth(
                      setState,
                      selectedImage,
                      imagePath,
                      (File? newImage, String? newPath) {
                        selectedImage = newImage;
                        imagePath = newPath;
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
                      'areteanimal': animal['aretegdo'] ?? '',
                      'tipoanimal': 'adulto',
                      'nomvet': veterinarioController.text,
                      'procedimiento': procedimientoController.text,
                      'condicionsalud': condicionSalud,
                      'medprev': medicinasString,
                      'fecharev': fechaRevisionController.text,
                      'observacionsalud': observacionesController.text,
                      'archivo': imagePath ?? '',
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

  Widget _buildImageSelectorForHealth(
    StateSetter setState,
    File? selectedImage,
    String? imagePath,
    Function(File?, String?) onImageChanged,
    BuildContext dialogContext,
  ) {
    return Column(
      children: [
        //titulo de la imagen
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Imagen del Registro de Salud',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 137, 77, 77),
            ),
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
              // Eliminar archivo si existe
              if (imagePath != null) {
                await ImageService.deleteImage(imagePath);
              }
              setState(() {
                onImageChanged(null, null);
              });
            },
            child: Text('Quitar imagen', style: TextStyle(color: Colors.red)),
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
    String? corralSeleccionado = tganado['corralgdo']?.toString();

    File? selectedImage;
    String? imagePath = tganado['fotogdo']?.toString();

    List<String> corralesDisponibles = [];
    bool cargandoCorrales = true;

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
                      'corralgdo': corralSeleccionado ?? '',
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
        widget.animal['aretegdo'] ?? '',
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

  void _showImageDialog(String imagePath, String title) {
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
            FutureBuilder<bool>(
              future: ImageService.imageExists(imagePath),
              builder: (context, snapshot) {
                if (snapshot.hasData == true && snapshot.data!) {
                  return Container(
                    width: 300,
                    height: 300,
                    child: Image.file(File(imagePath), fit: BoxFit.cover),
                  );
                } else {
                  return Container(
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
                  );
                }
              },
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
              // Header con título y botón cerrar (igual que en AnimalDetailsDialog)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historial de Salud - ${widget.animal['nombregdo']}',
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

              // Información del animal
              _buildAnimalInfoSection(),

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

  Widget _buildAnimalInfoSection() {
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
            'Información del Animal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 137, 77, 77),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            'Nombre',
            widget.animal['nombregdo'] ?? 'No especificado',
          ),
          _buildInfoRow(
            'Arete',
            widget.animal['aretegdo'] ?? 'No especificado',
          ),
          _buildInfoRow('Raza', widget.animal['razagdo'] ?? 'No especificado'),
          _buildInfoRow(
            'Estatus',
            widget.animal['estatusgdo'] ?? 'No especificado',
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
          Icon(Icons.medical_services, size: 64, color: Colors.grey[400]),
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
        registro['archivo'].toString().isNotEmpty;

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
                  Icons.medical_services,
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

//reproduccion
void _showReproductionHistory(
  BuildContext context,
  Map<String, dynamic> animal,
) {
  showDialog(
    context: context,
    builder: (context) => ReproductionHistoryDialog(animal: animal),
  );
}

// esta clase es para mostrar el historial d reproduccion
class ReproductionHistoryDialog extends StatefulWidget {
  final Map<String, dynamic> animal;

  const ReproductionHistoryDialog({super.key, required this.animal});

  @override
  State<ReproductionHistoryDialog> createState() =>
      _ReproductionHistoryDialogState();
}

class _ReproductionHistoryDialogState extends State<ReproductionHistoryDialog> {
  List<Map<String, dynamic>> _registrosReproduccion = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrosReproduccion();
  }

  Future<void> _loadRegistrosReproduccion() async {
    try {
      final registros = await SQLHelper.getRegistrosReproduccionPorArete(
        widget.animal['aretegdo'] ?? '',
      );
      setState(() {
        _registrosReproduccion = registros;
        _isLoading = false;
      });
    } catch (e) {
      print("Error cargando registros de reproducción: $e");
      setState(() => _isLoading = false);
    }
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
              // Header con título y botón cerrar (igual que en AnimalDetailsDialog)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historial de Reproducción\nde ${widget.animal['nombregdo']}',
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

              // Información del animal
              _buildAnimalInfoSection(),

              SizedBox(height: 20),

              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_registrosReproduccion.isEmpty)
                _buildEmptyState()
              else
                _buildRegistrosSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalInfoSection() {
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
            'Información del Animal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 137, 77, 77),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            'Nombre',
            widget.animal['nombregdo'] ?? 'No especificado',
          ),
          _buildInfoRow(
            'Arete',
            widget.animal['aretegdo'] ?? 'No especificado',
          ),
          _buildInfoRow('Raza', widget.animal['razagdo'] ?? 'No especificado'),
          _buildInfoRow(
            'Estatus',
            widget.animal['estatusgdo'] ?? 'No especificado',
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
          Icon(Icons.medical_services, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No hay registros de reproducción',
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
          'Registros de Reproducción (${_registrosReproduccion.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 137, 77, 77),
          ),
        ),
        SizedBox(height: 16),
        ..._registrosReproduccion.asMap().entries.map((entry) {
          final index = entry.key;
          final registro = entry.value;
          return _buildRegistroCard(registro, index);
        }).toList(),
      ],
    );
  }

  Widget _buildRegistroCard(Map<String, dynamic> registro, int index) {
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
                  Icons.medical_services,
                  color: const Color.fromARGB(255, 137, 77, 77),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registro ${index + 1} - ${registro['fservicioactual'] ?? 'Fecha no especificada'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 137, 77, 77),
                      fontSize: 16,
                    ),
                  ),
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
                  'Cargada',
                  registro['cargada'] ?? 'No especificado',
                ),
                _buildRegistroInfoRow(
                  'Cantidad de partos',
                  registro['cantpartos'] ?? 'No especificado',
                ),
                _buildRegistroInfoRow(
                  'Fecha de servicio actual',
                  registro['fservicioactual'] ?? 'No especificado',
                ),
                _buildRegistroInfoRow(
                  'Fecha aprox. de parto',
                  registro['faproxparto'] ?? 'No especificado',
                ),
                _buildRegistroInfoRow(
                  'Fecha de proximo servicio',
                  registro['fnuevoservicio'] ?? 'No especificada',
                ),
                if (registro['observacion'] != null &&
                    registro['observacion'].toString().isNotEmpty)
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
                        registro['observacion'].toString(),
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

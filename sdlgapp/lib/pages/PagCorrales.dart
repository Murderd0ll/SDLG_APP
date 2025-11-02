import 'package:flutter/material.dart';
import 'package:sdlgapp/pages/db_helper.dart';

class PagCorrales extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final VoidCallback onRefresh;
  final bool isLoading;

  const PagCorrales({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  State<PagCorrales> createState() => _PagCorralesState();
}

class _PagCorralesState extends State<PagCorrales> {
  @override
  void initState() {
    super.initState();
    // Actualizar cantidades al iniciar
    _actualizarCapacidadesAlIniciar();
  }

  Future<void> _actualizarCapacidadesAlIniciar() async {
    try {
      await SQLHelper.actualizarCapacidadActualTodosCorrales();
      widget.onRefresh(); // Refrescar la lista
    } catch (e) {
      print("Error actualizando capacidades al iniciar: $e");
    }
  }

  // Método para forzar actualización de capacidades
  Future<void> _forzarActualizacionCapacidades() async {
    try {
      await SQLHelper.actualizarCapacidadActualTodosCorrales();
      widget.onRefresh();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Capacidades actualizadas correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error actualizando capacidades: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  barHintText: 'Buscar Corrales',
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
                              title: Text("Escribe para buscar corrales..."),
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
                color: const Color.fromARGB(255, 92, 77, 137).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _forzarActualizacionCapacidades,
                icon: Icon(
                  Icons.refresh,
                  color: const Color.fromARGB(255, 139, 128, 182),
                ),
                tooltip: 'Actualizar Capacidades',
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 137, 77, 77).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _showAddCorralDialog(context),
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 182, 128, 128),
                ),
                tooltip: 'Agregar Corral',
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (widget.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fence, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "No hay corrales registrados",
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
      itemCount: widget.data.length,
      itemBuilder: (context, index) {
        final tcorral = widget.data[index];
        return _buildCorralCard(tcorral, context);
      },
    );
  }

  Widget _buildCorralCard(Map<String, dynamic> tcorral, BuildContext context) {
    final capacidadMaxima =
        int.tryParse(tcorral['capmax']?.toString() ?? '0') ?? 0;
    final capacidadActual =
        int.tryParse(tcorral['capactual']?.toString() ?? '0') ?? 0;
    final porcentajeUso = capacidadMaxima > 0
        ? (capacidadActual / capacidadMaxima) * 100
        : 0;
    Color colorEstado = Colors.green;
    if (porcentajeUso >= 90) {
      colorEstado = Colors.red;
    } else if (porcentajeUso >= 70) {
      colorEstado = Colors.orange;
    }
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(
            255,
            137,
            119,
            77,
          ).withOpacity(0.2),
          child: Icon(
            Icons.fence,
            color: const Color.fromARGB(255, 137, 119, 77),
          ),
        ),
        title: Text(
          tcorral['nomcorral'] ?? 'Sin nombre',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            if (tcorral['identcorral'] != null)
              Text('Identificador: ${tcorral['identcorral']}'),

            if (tcorral['ubicorral'] != null)
              Text('Ubicación: ${tcorral['ubicorral']}'),

            if (tcorral['capmax'] != null)
              Text('Capacidad: ${tcorral['capmax']}'),

            Row(
              children: [
                Text('Cantidad Actual: '),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colorEstado),
                  ),
                  child: Text(
                    '${tcorral['capactual'] ?? '0'} animales',
                    style: TextStyle(
                      color: colorEstado,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Barra de progreso visual
            if (capacidadMaxima > 0) ...[
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: capacidadActual / capacidadMaxima,
                backgroundColor: Colors.grey[300],
                color: colorEstado,
                minHeight: 6,
              ),
              SizedBox(height: 2),
              Text(
                '${porcentajeUso.toStringAsFixed(1)}% de uso',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],

            if (tcorral['fechamant'] != null)
              Text('Fecha de Mantenimiento: ${tcorral['fechamant']}'),

            if (tcorral['condicion'] != null)
              Text('Condición: ${tcorral['condicion']}'),

            if (tcorral['observacioncorral'] != null)
              Text('Observaciones: ${tcorral['observacioncorral']}'),
            SizedBox(height: 4),
            Text(
              'ID: ${tcorral['idcorral']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditCorralDialog(context, tcorral);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, tcorral);
            } else if (value == 'refresh_capacity') {
              _actualizarCapacidadCorralIndividual(tcorral);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'refresh_capacity',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Actualizar Capacidad'),
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

  // Método para actualizar capacidad de un corral individual
  Future<void> _actualizarCapacidadCorralIndividual(
    Map<String, dynamic> corral,
  ) async {
    final nombreCorral = corral['nomcorral']?.toString();
    if (nombreCorral == null) return;

    try {
      await SQLHelper.actualizarCapacidadActualCorral(nombreCorral);
      widget.onRefresh(); // Refrescar la lista

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Capacidad de $nombreCorral actualizada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error actualizando capacidad: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      final resultados = await SQLHelper.searchCorrales(query);

      if (resultados.isEmpty) {
        return [
          ListTile(
            title: Text("No se encontraron corrales"),
            textColor: Colors.grey,
          ),
        ];
      }

      return resultados.map((tcorral) {
        return ListTile(
          leading: Icon(
            Icons.fence,
            color: const Color.fromARGB(255, 137, 119, 77),
          ),
          title: Text(tcorral['nomcorral'] ?? 'Sin nombre'),
          subtitle: Text('${tcorral['identcorral']} - ${tcorral['capactual']}'),
          onTap: () {
            Navigator.pop(context);
            _showEditCorralDialog(context, tcorral);
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

  void _showAddCorralDialog(BuildContext context) {
    final nomcorralController = TextEditingController();
    final identcorralController = TextEditingController();
    final ubicorralController = TextEditingController();
    final capmaxController = TextEditingController();
    final capactualController = TextEditingController(text: '0');
    final fechamantController = TextEditingController();
    final observacioncorralController = TextEditingController();

    String? condicion;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Agregar Corral"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomcorralController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Corral',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: identcorralController,
                      decoration: InputDecoration(
                        labelText: 'Identificador del Corral',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: ubicorralController,
                      decoration: InputDecoration(
                        labelText: 'Ubicación',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: capmaxController,
                      decoration: InputDecoration(
                        labelText: 'Capacidad máxima',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: capactualController,
                      decoration: InputDecoration(
                        labelText: 'Capacidad actual',
                        border: OutlineInputBorder(),
                        enabled:
                            false, // Deshabilitado porque se calculará automáticamente
                      ),
                      readOnly: true, // Solo lectura
                    ),
                    SizedBox(height: 8),
                    Text(
                      'La capacidad actual se calculará automáticamente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: fechamantController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Mantenimiento',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () =>
                              _selectDate(context, fechamantController),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: condicion,
                        decoration: InputDecoration(
                          labelText: 'Condición del Corral',
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
                          DropdownMenuItem(
                            value: 'No apto',
                            child: Text('No apto'),
                          ),
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
                      controller: observacioncorralController,
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
                    if (nomcorralController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('El nombre del corral es obligatorio'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final nuevoCorral = {
                      'identcorral': identcorralController.text,
                      'nomcorral': nomcorralController.text,
                      'ubicorral': ubicorralController.text,
                      'capmax': capmaxController.text,
                      'capactual': '0',
                      'fechamant': fechamantController.text,
                      'condicion': condicion,
                      'observacioncorral': observacioncorralController.text,
                    };

                    try {
                      await SQLHelper.createCorral(nuevoCorral);
                      await SQLHelper.actualizarCapacidadActualCorral(
                        nomcorralController.text,
                      );
                      widget.onRefresh();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Corral agregado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar corral: $e'),
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

  void _showEditCorralDialog(
    BuildContext context,
    Map<String, dynamic> tcorral,
  ) {
    final identcorralController = TextEditingController(
      text: tcorral['identcorral'] ?? '',
    );
    final nomcorralController = TextEditingController(
      text: tcorral['nomcorral'] ?? '',
    );
    final ubicorralController = TextEditingController(
      text: tcorral['ubicorral'] ?? '',
    );
    final capmaxController = TextEditingController(
      text: tcorral['capmax']?.toString() ?? '',
    );

    final capactualController = TextEditingController(
      text: tcorral['capactual']?.toString() ?? '',
    );

    final fechamantController = TextEditingController(
      text: tcorral['fechamant'] ?? '',
    );

    final observacioncorralController = TextEditingController(
      text: tcorral['observacioncorral'] ?? '',
    );

    String? condicion = tcorral['condicion'].toString();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Editar Corral"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomcorralController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Corral',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: identcorralController,
                      decoration: InputDecoration(
                        labelText: 'Identificador del Corral',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: ubicorralController,
                      decoration: InputDecoration(
                        labelText: 'Ubicación del Corral',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: capmaxController,
                      decoration: InputDecoration(
                        labelText: 'Capacidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: capactualController,
                      decoration: InputDecoration(
                        labelText: 'Capacidad Actual',
                        border: OutlineInputBorder(),
                        enabled: false,
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      readOnly: true,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'La capacidad actual se calcula automáticamente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 12),

                    TextField(
                      controller: fechamantController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Mantenimiento',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () =>
                              _selectDate(context, fechamantController),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: condicion,
                        decoration: InputDecoration(
                          labelText: 'Condición del Corral',
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
                          DropdownMenuItem(
                            value: 'No apto',
                            child: Text('No apto'),
                          ),
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
                      controller: observacioncorralController,
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
                    final corralActualizado = {
                      'nomcorral': nomcorralController.text,
                      'identcorral': identcorralController.text,
                      'ubicorral': ubicorralController.text,
                      'capmax': capmaxController.text,
                      'capactual': tcorral['capactual'].toString() ?? '0',
                      'fechamant': fechamantController.text,
                      'condicion': condicion,
                      'observacioncorral': observacioncorralController.text,
                    };

                    try {
                      await SQLHelper.updateCorral(
                        tcorral['idcorral'],
                        corralActualizado,
                      );
                      await SQLHelper.actualizarCapacidadActualCorral(
                        nomcorralController.text,
                      );
                      widget.onRefresh();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Corral actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar corral: $e'),
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
    Map<String, dynamic> tcorral,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar Corral"),
          content: Text(
            "¿Estás seguro de que quieres eliminar el corral ${tcorral['nombre']}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await SQLHelper.deleteCorral(tcorral['idcorral']);
                  widget.onRefresh();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Corral eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar corral: $e'),
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

import 'package:flutter/material.dart';
import 'package:sdlgapp/pages/db_helper.dart';

class PagCorrales extends StatelessWidget {
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
                        return _buildSearchSuggestions(controller.text);
                      },
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 137, 119, 77).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _showAddCorralDialog(context),
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 137, 119, 77),
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
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty) {
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
      itemCount: data.length,
      itemBuilder: (context, index) {
        final tcorral = data[index];
        return _buildCorralCard(tcorral, context);
      },
    );
  }

  Widget _buildCorralCard(Map<String, dynamic> tcorral, BuildContext context) {
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

            if (tcorral['capactual'] != null)
              Text('Capacidad Actual: ${tcorral['capactual']}'),

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
            // Aquí puedes navegar a los detalles del corral
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
    final capactualController = TextEditingController();
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
                    final nuevoCorral = {
                      'identcorral': identcorralController.text,
                      'nomcorral': nomcorralController.text,
                      'ubicorral': ubicorralController.text,
                      'capmax': capmaxController.text,
                      'capactual': capactualController.text,
                      'fechamant': fechamantController.text,
                      'condicion': condicion,
                      'observacioncorral': observacioncorralController.text,
                    };

                    try {
                      await SQLHelper.createCorral(nuevoCorral);
                      onRefresh();
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
                      'capactual': capactualController.text,
                      'fechamant': fechamantController.text,
                      'condicion': condicion,
                      'observacioncorral': observacioncorralController.text,
                    };

                    try {
                      await SQLHelper.updateCorral(
                        tcorral['idcorral'],
                        corralActualizado,
                      );
                      onRefresh();
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
                  onRefresh();
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

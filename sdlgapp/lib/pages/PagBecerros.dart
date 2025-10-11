import 'package:flutter/material.dart';
import 'package:sdlgapp/pages/db_helper.dart';

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
        final becerro = data[index];
        return _buildBecerroCard(becerro, context);
      },
    );
  }

  Widget _buildBecerroCard(Map<String, dynamic> becerro, BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(
            255,
            77,
            137,
            95,
          ).withOpacity(0.2),
          child: Icon(
            Icons.agriculture,
            color: const Color.fromARGB(255, 77, 137, 95),
          ),
        ),
        title: Text(
          becerro['nombre'] ?? 'Sin nombre',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            if (becerro['fechaNacimiento'] != null)
              Text('Nacimiento: ${becerro['fechaNacimiento']}'),
            if (becerro['pesoNacimiento'] != null)
              Text('Peso al nacer: ${becerro['pesoNacimiento']} kg'),
            if (becerro['observaciones'] != null)
              Text('Observaciones: ${becerro['observaciones']}'),
            if (becerro['madreId'] != null)
              Text('Madre ID: ${becerro['madreId']}'),
            if (becerro['padreId'] != null)
              Text('Padre ID: ${becerro['padreId']}'),
            SizedBox(height: 4),
            Text(
              'ID: ${becerro['id']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditBecerroDialog(context, becerro);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, becerro);
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

      return resultados.map((becerro) {
        return ListTile(
          leading: Icon(
            Icons.agriculture,
            color: const Color.fromARGB(255, 77, 137, 95),
          ),
          title: Text(becerro['nombre'] ?? 'Sin nombre'),
          subtitle: Text('Nacimiento: ${becerro['fechaNacimiento']}'),
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
    final nombreController = TextEditingController();
    final fechaNacimientoController = TextEditingController();
    final pesoNacimientoController = TextEditingController();
    final observacionesController = TextEditingController();
    final madreIdController = TextEditingController();
    final padreIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Agregar Becerro"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: fechaNacimientoController,
                  decoration: InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: pesoNacimientoController,
                  decoration: InputDecoration(
                    labelText: 'Peso al Nacer (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: observacionesController,
                  decoration: InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: madreIdController,
                  decoration: InputDecoration(
                    labelText: 'ID de la Madre (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: padreIdController,
                  decoration: InputDecoration(
                    labelText: 'ID del Padre (opcional)',
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
                  'nombre': nombreController.text,
                  'fechaNacimiento': fechaNacimientoController.text,
                  'pesoNacimiento': double.tryParse(
                    pesoNacimientoController.text,
                  ),
                  'observaciones': observacionesController.text,
                  'madreId': int.tryParse(madreIdController.text),
                  'padreId': int.tryParse(padreIdController.text),
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
  }

  void _showEditBecerroDialog(
    BuildContext context,
    Map<String, dynamic> becerro,
  ) {
    final nombreController = TextEditingController(
      text: becerro['nombre'] ?? '',
    );
    final fechaNacimientoController = TextEditingController(
      text: becerro['fechaNacimiento'] ?? '',
    );
    final pesoNacimientoController = TextEditingController(
      text: becerro['pesoNacimiento']?.toString() ?? '',
    );
    final observacionesController = TextEditingController(
      text: becerro['observaciones'] ?? '',
    );
    final madreIdController = TextEditingController(
      text: becerro['madreId']?.toString() ?? '',
    );
    final padreIdController = TextEditingController(
      text: becerro['padreId']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Editar Becerro"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: fechaNacimientoController,
                  decoration: InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: pesoNacimientoController,
                  decoration: InputDecoration(
                    labelText: 'Peso al Nacer (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: observacionesController,
                  decoration: InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: madreIdController,
                  decoration: InputDecoration(
                    labelText: 'ID de la Madre',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: padreIdController,
                  decoration: InputDecoration(
                    labelText: 'ID del Padre',
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
                final becerroActualizado = {
                  'nombre': nombreController.text,
                  'fechaNacimiento': fechaNacimientoController.text,
                  'pesoNacimiento': double.tryParse(
                    pesoNacimientoController.text,
                  ),
                  'observaciones': observacionesController.text,
                  'madreId': int.tryParse(madreIdController.text),
                  'padreId': int.tryParse(padreIdController.text),
                };

                try {
                  await SQLHelper.updateBecerro(
                    becerro['id'],
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
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> becerro,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar Becerro"),
          content: Text(
            "¿Estás seguro de que quieres eliminar a ${becerro['nombre']}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await SQLHelper.deleteBecerro(becerro['id']);
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

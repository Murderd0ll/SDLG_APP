import 'package:flutter/material.dart';
import 'package:sdlgapp/pages/db_helper.dart';

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
                  barHintText: 'Buscar Propietarios',
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
                        return _buildSearchSuggestions(controller.text);
                      },
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 137, 77, 119).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _showAddPropietarioDialog(context),
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 137, 77, 119),
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
            Icon(Icons.people, size: 64, color: Colors.grey[400]),
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
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(
            255,
            137,
            77,
            119,
          ).withOpacity(0.2),
          child: Icon(
            Icons.person,
            color: const Color.fromARGB(255, 137, 77, 119),
          ),
        ),
        title: Text(
          '${tpropietarios['nombreprop']} ${tpropietarios['telprop']}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
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

  Future<List<Widget>> _buildSearchSuggestions(String query) async {
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
            color: const Color.fromARGB(255, 137, 77, 119),
          ),
          title: Text('${tpropietarios['nombreprop']}'),
          subtitle: Text(tpropietarios['telprop'] ?? 'Sin teléfono'),
          onTap: () {
            // FALTA AGREGAR PARA VER DETALLES DEL PROPIETARIO **************
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
    final nombrepropController = TextEditingController();
    final telpropController = TextEditingController();
    final correopropController = TextEditingController();
    final dirpropController = TextEditingController();
    final rfcpropController = TextEditingController();
    final psgpropController = TextEditingController();
    final upppropController = TextEditingController();
    final observacionpropController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Agregar Propietario"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombrepropController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: telpropController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: correopropController,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: dirpropController,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: rfcpropController,
                  decoration: InputDecoration(
                    labelText: 'RFC',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: psgpropController,
                  decoration: InputDecoration(
                    labelText: 'PSG',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: upppropController,
                  decoration: InputDecoration(
                    labelText: 'UPP',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: observacionpropController,
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
                final nuevoPropietario = {
                  'nombreprop': nombrepropController.text,
                  'telprop': telpropController.text,
                  'correoprop': correopropController.text,
                  'dirprop': dirpropController.text,
                  'rfcprop': rfcpropController.text,
                  'psgprop': psgpropController.text,
                  'uppprop': upppropController.text,
                  'observacionprop': observacionpropController.text,
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
  }

  void _showEditPropietarioDialog(
    BuildContext context,
    Map<String, dynamic> tpropietarios,
  ) {
    final nombrepropController = TextEditingController(
      text: tpropietarios['nombreprop'] ?? '',
    );
    final telpropController = TextEditingController(
      text: tpropietarios['telprop'] ?? '',
    );
    final correopropController = TextEditingController(
      text: tpropietarios['correoprop'] ?? '',
    );
    final dirpropController = TextEditingController(
      text: tpropietarios['dirprop'] ?? '',
    );
    final rfcpropController = TextEditingController(
      text: tpropietarios['rfcprop'] ?? '',
    );
    final psgpropController = TextEditingController(
      text: tpropietarios['psgprop'] ?? '',
    );
    final upppropController = TextEditingController(
      text: tpropietarios['uppprop'] ?? '',
    );
    final observacionpropController = TextEditingController(
      text: tpropietarios['observacionprop'] ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Editar Propietario"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombrepropController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                TextField(
                  controller: telpropController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                TextField(
                  controller: correopropController,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                TextField(
                  controller: dirpropController,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                TextField(
                  controller: rfcpropController,
                  decoration: InputDecoration(
                    labelText: 'RFC',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                TextField(
                  controller: psgpropController,
                  decoration: InputDecoration(
                    labelText: 'PSG',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                TextField(
                  controller: upppropController,
                  decoration: InputDecoration(
                    labelText: 'UPP',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                TextField(
                  controller: observacionpropController,
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
                final propietarioActualizado = {
                  'nombreprop': nombrepropController.text,
                  'telprop': telpropController.text,
                  'correoprop': correopropController.text,
                  'dirprop': dirpropController.text,
                  'rfcprop': rfcpropController.text,
                  'psgprop': psgpropController.text,
                  'uppprop': upppropController.text,
                  'observacionprop': observacionpropController.text,
                };

                try {
                  await SQLHelper.updatePropietario(
                    tpropietarios['idprop'],
                    propietarioActualizado,
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
                      content: Text('Error al actualizar propietario: $e'),
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

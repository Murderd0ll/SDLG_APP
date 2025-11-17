import 'package:flutter/material.dart';
import 'package:sdlgapp/pages/db_helper.dart';
import 'package:sdlgapp/services/database_import_service.dart';

class ImportDatabasePage extends StatefulWidget {
  final VoidCallback onDatabaseUpdated;

  const ImportDatabasePage({super.key, required this.onDatabaseUpdated});

  @override
  State<ImportDatabasePage> createState() => _ImportDatabasePageState();
}

class _ImportDatabasePageState extends State<ImportDatabasePage> {
  bool _isImporting = false;
  String _statusMessage = '';
  bool _hasError = false;
  Map<String, dynamic>? _lastImportResult;

  Future<void> _importDatabase() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'Seleccionando archivo de base de datos...';
      _hasError = false;
      _lastImportResult = null;
    });

    try {
      // Seleccionar archivo
      final file = await DatabaseImportService.pickDatabaseFile();
      if (file == null) {
        setState(() {
          _statusMessage = 'Operación cancelada';
          _isImporting = false;
        });
        return;
      }

      // Mostrar opciones de fusión
      final mergeStrategies =
          await DatabaseImportService.showMergeOptionsDialog(context);
      if (mergeStrategies == null) {
        setState(() {
          _statusMessage = 'Operación cancelada por el usuario';
          _isImporting = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Creando backup de seguridad...';
      });

      // Crear backup
      final backupCreated = await DatabaseImportService.createBackup();
      if (!backupCreated) {
        setState(() {
          _statusMessage = 'Advertencia: No se pudo crear backup de seguridad';
        });
        await Future.delayed(Duration(seconds: 2));
      }

      setState(() {
        _statusMessage = 'Fusionando datos...\nEsto puede tomar unos momentos.';
      });

      // Realizar fusión
      final result = await DatabaseImportService.importDatabaseWithMerge(
        file,
        customStrategies: mergeStrategies,
      );

      setState(() {
        _isImporting = false;
        _hasError = !result['success'];
        _statusMessage = result['message'];
        _lastImportResult = result;
      });

      if (result['success']) {
        // Mostrar resumen detallado
        if (mounted) {
          _showMergeSummary(result);
        }

        // Notificar que la base de datos fue actualizada
        widget.onDatabaseUpdated();
      } else {
        // En caso de error, ofrecer restaurar backup
        if (mounted) {
          _showErrorDialog();
        }
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _hasError = true;
        _statusMessage = 'Error inesperado: $e';
      });

      if (mounted) {
        _showErrorDialog();
      }
    }
  }

  void _showMergeSummary(Map<String, dynamic> result) {
    final summary = result['summary'] as Map<String, dynamic>?;
    final details = result['details'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [SizedBox(width: 10), Text('Fusión Completada')]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary != null) ...[
                _buildSummaryItem(
                  '➕ Registros nuevos',
                  summary['imported'].toString(),
                ),
                _buildSummaryItem(
                  '🔄 Registros actualizados',
                  summary['updated'].toString(),
                ),
                _buildSummaryItem(
                  '⏭️ Registros saltados',
                  summary['skipped'].toString(),
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(10),

                  child: Text(
                    'Total procesados: ${summary['totalProcessed']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              SizedBox(height: 15),
              if (details != null) ...[
                Text(
                  'Detalles por tabla:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 10),
                ...details.entries.map(
                  (entry) => _buildTableDetail(entry.key, entry.value),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTableDetail(String tableName, Map<String, dynamic> stats) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _getTableDisplayName(tableName),
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('+${stats['imported']}', Colors.green),
                _buildStatChip('↻${stats['updated']}', Colors.blue),
                _buildStatChip('⏭${stats['skipped']}', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getTableDisplayName(String tableName) {
    switch (tableName) {
      case 'tganado':
        return 'Animales';
      case 'tbecerros':
        return 'Becerros';
      case 'tsalud':
        return 'Salud';
      case 'treproduccion':
        return 'Reproducción';
      case 'tcorral':
        return 'Corrales';
      case 'tpropietarios':
        return 'Propietarios';
      case 'tusuarios':
        return 'Usuarios';
      case 'tbitacora':
        return 'Bitácora';

      default:
        return tableName;
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('Error en la Fusión'),
          ],
        ),
        content: Text(
          'Hubo un problema durante la fusión. ¿Deseas restaurar el backup anterior?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _statusMessage = 'Restaurando backup...';
                _isImporting = true;
              });

              final restored = await DatabaseImportService.restoreFromBackup();
              setState(() {
                _isImporting = false;
                if (restored) {
                  _statusMessage = 'Backup restaurado exitosamente';
                  _hasError = false;
                  widget.onDatabaseUpdated();
                } else {
                  _statusMessage = 'No se pudo restaurar el backup';
                }
              });
            },
            child: Text('Restaurar Backup'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Opciones de Base de Datos'),
        backgroundColor: const Color.fromARGB(255, 27, 26, 34),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Exportar Base de Datos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Esta función le permite exportar una copia de seguridad completa de la base de datos actual.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Formato de archivo: .db',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            // Botón de importación
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  SQLHelper.exportRealDatabase();
                },
                icon: Icon(Icons.outbox_outlined),
                label: Text('Exportar Base de Datos'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: const Color.fromARGB(255, 63, 167, 181),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 20),
            // Información
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Fusionar Base de Datos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Esta función combina los datos de tu software existente con los datos actuales de la aplicación.'
                      ' Puedes elegir cómo fusionar cada tipo de información.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Formato de archivos soportado: .db, .sqlite, .sqlite3',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Botón de importación
            Center(
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _importDatabase,
                icon: _isImporting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.merge),
                label: Text(_isImporting ? 'Fusionando...' : 'Iniciar Fusión'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Estado de la importación
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasError ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hasError ? Colors.red : Colors.green,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasError
                          ? Icons.error
                          : _isImporting
                          ? Icons.hourglass_bottom
                          : Icons.info,
                      color: _hasError
                          ? Colors.red
                          : _isImporting
                          ? Colors.blue
                          : Colors.green,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _hasError
                              ? Colors.red[700]
                              : _isImporting
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),

            // Advertencias
            if (!_isImporting)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[800]),
                          SizedBox(width: 8),
                          Text(
                            'Antes de continuar con la fusión:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Puedes elegir cómo fusionar cada tipo de dato\n'
                        '• Los datos existentes se preservarán\n'
                        '• Asegúrate de que el archivo sea compatible',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

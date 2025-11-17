import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sdlgapp/pages/db_helper.dart';
import 'package:flutter/material.dart';

// estas son las "estrategias" q se usan para fusionar los datos de las tablas q se suban
enum MergeStrategy {
  skipExisting, // Saltar registros
  updateExisting, // Actualizar registros
  mergeData, // Combinar datos
}

class DatabaseImportService {
  // este es para seleccionar el archivo
  static Future<File?> pickDatabaseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
        allowMultiple: false,
        dialogTitle: 'Seleccionar base de datos del software',
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print("Error seleccionando archivo: $e");
      return null;
    }
  }

  // aqui valida q esten las tablas de la bdd
  static Future<bool> validateDatabaseStructure(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );

      final tableNames = tables
          .map((table) => table['name'] as String)
          .toList();

      // estas son las tablas minimas q debe tener la bdd
      final requiredTables = [
        'tganado',
        'tbecerros',
        'tsalud',
        'treprod',
        'tcorral',
        'tpropietarios',
        'tusuarios',
        'tbitacora',
      ];
      for (var table in requiredTables) {
        if (!tableNames.contains(table)) {
          print("Tabla faltante: $table");
          return false;
        }
      }

      return true;
    } catch (e) {
      print("Error validando estructura: $e");
      return false;
    }
  }

  // fusion x tabla en este caso son todas por update
  static final Map<String, MergeStrategy> _mergeStrategies = {
    'tganado': MergeStrategy.updateExisting,
    'tbecerros': MergeStrategy.updateExisting,
    'tsalud': MergeStrategy.updateExisting,
    'treproduccion': MergeStrategy.updateExisting,
    'tcorral': MergeStrategy.updateExisting,
    'tpropietarios': MergeStrategy.updateExisting,
    'tusuarios': MergeStrategy.updateExisting,
    'tbitacora': MergeStrategy.updateExisting,
  };

  //este es para identificar registros q ya existan y no duplicarlos
  static final Map<String, List<String>> _uniqueKeys = {
    'tganado': ['idgdo', 'aretegdo'],
    'tbecerros': ['idbece', 'aretebece'],
    'tsalud': ['areteanimal', 'tipoanimal', 'fecharev'],
    'treproduccion': ['idreprod', 'areteanimal', 'fservicioactual'],
    'tcorral': ['idcorral', 'identcorral'],
    'tpropietarios': ['idprop', 'nombreprop'],
    'tbitacora': ['idbitacora'],
  };

  // aqui empieza la fusion
  static Future<Map<String, dynamic>> importTableWithMerge({
    required Database sourceDb,
    required Database targetDb,
    required String tableName,
    required List<String> columns,
    required MergeStrategy strategy,
  }) async {
    try {
      final data = await sourceDb.query(tableName);
      int importedCount = 0;
      int updatedCount = 0;
      int skippedCount = 0;

      final uniqueKeys = _uniqueKeys[tableName] ?? ['id'];

      for (var sourceRow in data) {
        try {
          // aqui verifica si alguno ya existe
          final whereClause = uniqueKeys.map((key) => '$key = ?').join(' AND ');
          final whereArgs = uniqueKeys.map((key) => sourceRow[key]).toList();

          final existingRows = await targetDb.query(
            tableName,
            where: whereClause,
            whereArgs: whereArgs,
          );

          if (existingRows.isNotEmpty) {
            // si el registro existe entonces lo salta
            switch (strategy) {
              case MergeStrategy.skipExisting:
                skippedCount++;
                continue;

              case MergeStrategy.updateExisting:
                // actualiza el registro con los demas
                final filteredRow = <String, dynamic>{};
                for (var column in columns) {
                  if (sourceRow.containsKey(column) &&
                      sourceRow[column] != null) {
                    filteredRow[column] = sourceRow[column];
                  }
                }

                await targetDb.update(
                  tableName,
                  filteredRow,
                  where: whereClause,
                  whereArgs: whereArgs,
                );
                updatedCount++;
                break;

              case MergeStrategy.mergeData:
                // aqui combina los q ya estan
                final existingRow = existingRows.first;
                final mergedRow = Map<String, dynamic>.from(existingRow);

                for (var column in columns) {
                  if (sourceRow.containsKey(column) &&
                      sourceRow[column] != null &&
                      sourceRow[column].toString().isNotEmpty) {
                    mergedRow[column] = sourceRow[column];
                  }
                }

                await targetDb.update(
                  tableName,
                  mergedRow,
                  where: whereClause,
                  whereArgs: whereArgs,
                );
                updatedCount++;
                break;
            }
          } else {
            // si es un registro nuevo lo guarda
            final filteredRow = <String, dynamic>{};
            for (var column in columns) {
              if (sourceRow.containsKey(column)) {
                filteredRow[column] = sourceRow[column];
              }
            }

            await targetDb.insert(tableName, filteredRow);
            importedCount++;
          }
        } catch (e) {
          print("Error procesando fila en $tableName: $e");
          skippedCount++;
        }
      }

      return {
        'imported': importedCount,
        'updated': updatedCount,
        'skipped': skippedCount,
        'total': data.length,
      };
    } catch (e) {
      print("Error importando tabla $tableName: $e");
      return {'imported': 0, 'updated': 0, 'skipped': 0, 'total': 0};
    }
  }

  // esta es toda la estructura principal de la fusión
  static Future<Map<String, dynamic>> importDatabaseWithMerge(
    File sourceFile, {
    Map<String, MergeStrategy>? customStrategies,
  }) async {
    try {
      // aqui se crea una copia temporal del archivo seleccionado
      final tempDir = await getDatabasesPath();
      final tempPath = path.join(tempDir, 'temp_import.db');
      await sourceFile.copy(tempPath);

      final sourceDb = await openDatabase(tempPath);

      // valida la estructura de la bdd
      if (!await validateDatabaseStructure(sourceDb)) {
        await sourceDb.close();
        await File(tempPath).delete();
        return {
          'success': false,
          'message': 'Estructura de base de datos inválida',
        };
      }

      // Usa las "estrategias" personalizadas o las predeterminadas
      final strategies = customStrategies ?? _mergeStrategies;

      // jala la bdd de destino (la de la app)
      final targetDb = await SQLHelper.db();

      final importResults = <String, Map<String, dynamic>>{};

      final tableMappings = {
        'tganado': [
          'idgdo',
          'aretegdo',
          'nombregdo',
          'sexogdo',
          'razagdo',
          'nacimientogdo',
          'corralgdo',
          'alimentogdo',
          'prodgdo',
          'estatusgdo',
          'observaciongdo',
          'fotogdo',
        ],
        'tbecerros': [
          'idbece',
          'aretebece',
          'nombrebece',
          'pesobece',
          'sexobece',
          'razabece',
          'nacimientobece',
          'corralbece',
          'estatusbece',
          'aretemadre',
          'observacionbece',
          'fotobece',
        ],
        'tsalud': [
          'idsalud',
          'areteanimal',
          'tipoanimal',
          'nomvet',
          'procedimiento',
          'condicionsalud',
          'medprev',
          'fecharev',
          'observacionsalud',
          'archivo',
        ],
        'treproduccion': [
          'idrepro',
          'areteanimal',
          'cargada',
          'cantpartos',
          'fservicioactual',
          'faproxparto',
          'fnuevoservicio',
          'tecnica',
          'observacion',
        ],
        'tcorral': [
          'idcorral',
          'nomcorral',
          'ubicorral',
          'capmax',
          'capactual',
          'fechamant',
          'condicion',
          'observacioncorral',
        ],
        'tpropietarios': [
          'idprop',
          'nombreprop',
          'telprop',
          'correoprop',
          'dirprop',
          'rfcprop',
          'psgprop',
          'uppprop',
          'observacionprop',
          'fotoprop',
        ],
        'tusuarios': [
          'idusuario',
          'nombre',
          'telefono',
          'usuario',
          'pass',
          'rol',
        ],
        'tbitacora': [
          'idbitacora',
          'fecha',
          'usuario',
          'modulo',
          'accion',
          'descripcion',
          'detalles',
          'arete_afectado',
        ],
      };

      // importar cada tabla fusionada
      for (var entry in tableMappings.entries) {
        final tableName = entry.key;
        final columns = entry.value;
        final strategy = strategies[tableName] ?? MergeStrategy.skipExisting;

        try {
          final result = await importTableWithMerge(
            sourceDb: sourceDb,
            targetDb: targetDb,
            tableName: tableName,
            columns: columns,
            strategy: strategy,
          );

          importResults[tableName] = result;
          print(
            'Tabla $tableName: ${result['imported']} nuevos, '
            '${result['updated']} actualizados, '
            '${result['skipped']} saltados',
          );
        } catch (e) {
          print("Error importando $tableName: $e");
          importResults[tableName] = {
            'imported': 0,
            'updated': 0,
            'skipped': 0,
            'total': 0,
            'error': e.toString(),
          };
        }
      }

      // Calcular resumen
      final totalImported = importResults.values.fold(
        0,
        (sum, result) => sum + (result['imported'] as int),
      );
      final totalUpdated = importResults.values.fold(
        0,
        (sum, result) => sum + (result['updated'] as int),
      );
      final totalSkipped = importResults.values.fold(
        0,
        (sum, result) => sum + (result['skipped'] as int),
      );

      // Limpiar
      await sourceDb.close();
      await File(tempPath).delete();

      return {
        'success': true,
        'message': 'Fusión completada exitosamente',
        'details': importResults,
        'summary': {
          'imported': totalImported,
          'updated': totalUpdated,
          'skipped': totalSkipped,
          'totalProcessed': totalImported + totalUpdated + totalSkipped,
        },
      };
    } catch (e) {
      print("Error en fusión: $e");
      return {'success': false, 'message': 'Error durante la fusión: $e'};
    }
  }

  // Método para mostrar opciones de fusión al usuario
  static Future<Map<String, MergeStrategy>?> showMergeOptionsDialog(
    BuildContext context,
  ) async {
    final strategies = <String, MergeStrategy>{};

    return await showDialog<Map<String, MergeStrategy>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Inicializar con estrategias predeterminadas
          if (strategies.isEmpty) {
            strategies.addAll(_mergeStrategies);
          }

          return AlertDialog(
            title: Text('Estrategia de Fusión'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selecciona cómo fusionar los datos para cada tabla:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 20),
                  _buildMergeOption(
                    context,
                    'Animales Adultos',
                    'Actualizar información de animales existentes',
                    strategies['tganado']!,
                    (value) {
                      setState(() {
                        strategies['tganado'] = value;
                      });
                    },
                  ),
                  SizedBox(height: 15),
                  _buildMergeOption(
                    context,
                    'Becerros',
                    'Actualizar información de becerros existentes',
                    strategies['tbecerros']!,
                    (value) {
                      setState(() {
                        strategies['tbecerros'] = value;
                      });
                    },
                  ),
                  SizedBox(height: 15),
                  _buildMergeOption(
                    context,
                    'Registros de Salud',
                    'Mantener todos los registros (no actualizar existentes)',
                    strategies['tsalud']!,
                    (value) {
                      setState(() {
                        strategies['tsalud'] = value;
                      });
                    },
                  ),
                  SizedBox(height: 15),
                  _buildMergeOption(
                    context,
                    'Registros de Reproducción',
                    'Mantener todos los registros (no actualizar existentes)',
                    strategies['treproduccion']!,
                    (value) {
                      setState(() {
                        strategies['treproduccion'] = value;
                      });
                    },
                  ),
                  SizedBox(height: 15),
                  _buildMergeOption(
                    context,
                    'Registros de Corrales',
                    'Mantener todos los registros (no actualizar existentes)',
                    strategies['tcorral']!,
                    (value) {
                      setState(() {
                        strategies['tcorral'] = value;
                      });
                    },
                  ),
                  SizedBox(height: 15),
                  _buildMergeOption(
                    context,
                    'Registros de Propietarios',
                    'Mantener todos los registros (no actualizar existentes)',
                    strategies['tpropietarios']!,
                    (value) {
                      setState(() {
                        strategies['tpropietarios'] = value;
                      });
                    },
                  ),
                  SizedBox(height: 15),
                  _buildMergeOption(
                    context,
                    'Registros de Salud',
                    'Mantener todos los registros (no actualizar existentes)',
                    strategies['tsalud']!,
                    (value) {
                      setState(() {
                        strategies['tsalud'] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('Cancelar', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, strategies),
                child: Text('Continuar con Fusión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildMergeOption(
    BuildContext context,
    String title,
    String description,
    MergeStrategy currentStrategy,
    Function(MergeStrategy) onChanged,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            DropdownButton<MergeStrategy>(
              value: currentStrategy,
              isExpanded: true,
              onChanged: (newStrategy) {
                if (newStrategy != null) {
                  onChanged(newStrategy);
                }
              },
              items: [
                DropdownMenuItem(
                  value: MergeStrategy.skipExisting,
                  child: Text('Saltar existentes'),
                ),
                DropdownMenuItem(
                  value: MergeStrategy.updateExisting,
                  child: Text('Actualizar existentes'),
                ),
                DropdownMenuItem(
                  value: MergeStrategy.mergeData,
                  child: Text('Combinar datos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Método para hacer backup de la base de datos actual antes de importar
  static Future<bool> createBackup() async {
    try {
      final databasesPath = await getDatabasesPath();
      final originalPath = path.join(databasesPath, 'sdlgapp.db');
      final backupPath = path.join(
        databasesPath,
        'sdlgapp_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );

      final originalFile = File(originalPath);
      if (await originalFile.exists()) {
        await originalFile.copy(backupPath);
        print('Backup creado en: $backupPath');
        return true;
      }
      return false;
    } catch (e) {
      print("Error creando backup: $e");
      return false;
    }
  }

  // Método para restaurar desde backup si hay problemas
  static Future<bool> restoreFromBackup() async {
    try {
      final databasesPath = await getDatabasesPath();
      final originalPath = path.join(databasesPath, 'sdlgapp.db');

      // Buscar el backup más reciente
      final directory = Directory(databasesPath);
      final files = await directory.list().toList();
      final backupFiles = files.where((file) {
        return file.path.contains('sdlgapp_backup_') &&
            file.path.endsWith('.db');
      }).toList();

      if (backupFiles.isNotEmpty) {
        // Ordenar por fecha (el más reciente primero)
        backupFiles.sort((a, b) => b.path.compareTo(a.path));
        final latestBackup = backupFiles.first.path;

        await File(latestBackup).copy(originalPath);
        print('Backup restaurado desde: $latestBackup');
        return true;
      }
      return false;
    } catch (e) {
      print("Error restaurando backup: $e");
      return false;
    }
  }
}

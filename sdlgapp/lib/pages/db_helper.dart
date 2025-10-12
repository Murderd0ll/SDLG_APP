// db_helper.dart - Versión completa y corregida
import 'package:sdlgapp/pages/PagAnimales.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class SQLHelper {
  // En SQLHelper class
  static Future<void> debugAnimalImages() async {
    final db = await SQLHelper.db();
    try {
      final animales = await db.query('tganado');
      print("=== DEBUG IMÁGENES ANIMALES ===");
      for (var animal in animales) {
        print("ID: ${animal['idgdo']}, Nombre: ${animal['nombregdo']}");
        print("Ruta imagen: ${animal['fotogdo']}");

        if (animal['fotogdo'] != null &&
            animal['fotogdo'].toString().isNotEmpty) {
          final exists = await ImageService.imageExists(
            animal['fotogdo'].toString(),
          );
          print("Imagen existe: $exists");
        } else {
          print("Sin imagen");
        }
        print("---");
      }
      print("=================================");
    } catch (e) {
      print("Error en debugAnimalImages: $e");
    }
  }

  static Future<sql.Database> db() async {
    try {
      final databasePath = await sql.getDatabasesPath();
      final String dbPath = path.join(databasePath, 'SDLGAPP.db');

      print("Ruta de la base de datos: $dbPath");

      return await sql.openDatabase(
        dbPath,
        version: 1,
        onCreate: (sql.Database database, int version) async {
          print("Creando base de datos por primera vez...");
          await createAllTables(database);
        },
      );
    } catch (e) {
      print("Error crítico abriendo base de datos: $e");
      rethrow;
    }
  }

  static Future<void> createAllTables(sql.Database database) async {
    try {
      print("Creando tablas...");

      // Tabla de tganado
      await database.execute("""CREATE TABLE IF NOT EXISTS tganado(
        idgdo INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        aretegdo TEXT,
        nombregdo TEXT,
        sexogdo TEXT,
        razagdo TEXT,
        nacimientogdo TEXT,
        corralgdo TEXT,
        alimentogdo TEXT,
        prodgdo TEXT,
        estatusgdo TEXT,
        observaciongdo TEXT,
        fotogdo TEXT
      )""");
      print("Tabla 'tganado' creada/verificada");

      // Tabla de Becerros
      await database.execute("""CREATE TABLE IF NOT EXISTS becerros(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nombre TEXT,
        madreId INTEGER,
        padreId INTEGER,
        fechaNacimiento TEXT,
        pesoNacimiento REAL,
        observaciones TEXT,
        createdAt TEXT
      )""");
      print("Tabla 'becerros' creada/verificada");

      // Tabla de Propietarios
      await database.execute("""CREATE TABLE IF NOT EXISTS propietarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nombre TEXT,
        apellido TEXT,
        telefono TEXT,
        email TEXT,
        direccion TEXT,
        createdAt TEXT
      )""");
      print("Tabla 'propietarios' creada/verificada");

      // Tabla de Corrales
      await database.execute("""CREATE TABLE IF NOT EXISTS corrales(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nombre TEXT,
        capacidad INTEGER,
        ubicacion TEXT,
        observaciones TEXT,
        createdAt TEXT
      )""");
      print("Tabla 'corrales' creada/verificada");

      print("Todas las tablas creadas exitosamente");
    } catch (e) {
      print("Error creando tablas: $e");
      rethrow;
    }
  }

  // Método para resetear la base de datos
  static Future<void> resetDatabase() async {
    try {
      final databasePath = await sql.getDatabasesPath();
      final String dbPath = path.join(databasePath, 'SDLGAPP.db');
      await sql.deleteDatabase(dbPath);
      print("Base de datos reiniciada exitosamente");
    } catch (e) {
      print("Error reiniciando base de datos: $e");
    }
  }

  // Método para debug: verificar estado de la base de datos
  static Future<void> debugDatabaseStatus() async {
    try {
      final database = await db();
      final tables = await database.rawQuery("""
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name NOT LIKE 'sqlite_%'
      """);

      print("=== ESTADO DE LA BASE DE DATOS ===");
      print("Tablas existentes:");
      if (tables.isEmpty) {
        print(" - No hay tablas");
      } else {
        for (var table in tables) {
          print(" - ${table['name']}");
        }
      }
      print("=================================");

      await database.close();
    } catch (e) {
      print("Error en debugDatabaseStatus: $e");
    }
  }

  // ========== MÉTODOS PARA ANIMALES ==========
  static Future<int> createAnimal(Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final animalData = {
        'aretegdo': data['aretegdo'] ?? '',
        'nombregdo': data['nombregdo'] ?? '',
        'sexogdo': data['sexogdo'] ?? '',
        'razagdo': data['razagdo'] ?? '',
        'nacimientogdo': data['nacimientogdo'] ?? '',
        'corralgdo': data['corralgdo'] ?? '',
        'alimentogdo': data['alimentogdo'] ?? '',
        'prodgdo': data['prodgdo'] ?? '',
        'estatusgdo': data['estatusgdo'] ?? '',
        'observaciongdo': data['observaciongdo'] ?? '',
        'fotogdo': data['fotogdo'] ?? '',
      };

      final idgdo = await db.insert(
        'tganado',
        animalData,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      print("Animal creado con ID: $idgdo");
      return idgdo;
    } catch (e) {
      print("Error creando animal: $e");
      await debugDatabaseStatus();
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllAnimales() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query('tganado', orderBy: "idgdo DESC");
      print("Animales obtenidos: ${result.length} registros");
      return result;
    } catch (e) {
      print("Error obteniendo animales: $e");
      await debugDatabaseStatus();
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAnimal(int idgdo) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tganado',
        where: "idgdo = ?",
        whereArgs: [idgdo],
        limit: 1,
      );
      return result;
    } catch (e) {
      print("Error obteniendo animal: $e");
      return [];
    }
  }

  static Future<int> updateAnimal(int idgdo, Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      print("=== ACTUALIZANDO ANIMAL EN BD ===");
      print("ID: $idgdo");

      // Filtrar solo los campos que existen en la tabla
      final camposValidos = [
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
      ];

      final datosFiltrados = Map<String, dynamic>.fromEntries(
        data.entries.where((entry) => camposValidos.contains(entry.key)),
      );

      print("Datos filtrados: $datosFiltrados");

      final result = await db.update(
        'tganado',
        datosFiltrados,
        where: "idgdo = ?",
        whereArgs: [idgdo],
      );

      print("Animal actualizado: $result filas afectadas");
      return result;
    } catch (e) {
      print("ERROR en updateAnimal: $e");
      rethrow;
    }
  }

  static Future<void> deleteAnimal(int idgdo) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("tganado", where: "idgdo = ?", whereArgs: [idgdo]);
      print("Animal eliminado con ID: $idgdo");
    } catch (e) {
      print("Error eliminando animal: $e");
      rethrow;
    }
  }

  // ========== MÉTODOS PARA BECERROS ==========
  static Future<int> createBecerro(Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final becerroData = {
        'nombre': data['nombre'] ?? '',
        'madreId': data['madreId'],
        'padreId': data['padreId'],
        'fechaNacimiento': data['fechaNacimiento'] ?? '',
        'pesoNacimiento': data['pesoNacimiento'],
        'observaciones': data['observaciones'] ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final id = await db.insert(
        'becerros',
        becerroData,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      print("Becerro creado con ID: $id");
      return id;
    } catch (e) {
      print("Error creando becerro: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllBecerros() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query('becerros', orderBy: "id DESC");
      print("Becerros obtenidos: ${result.length} registros");
      return result;
    } catch (e) {
      print("Error obteniendo becerros: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getBecerro(int id) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'becerros',
        where: "id = ?",
        whereArgs: [id],
        limit: 1,
      );
      return result;
    } catch (e) {
      print("Error obteniendo becerro: $e");
      return [];
    }
  }

  static Future<int> updateBecerro(int id, Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.update(
        'becerros',
        data,
        where: "id = ?",
        whereArgs: [id],
      );
      print("Becerro actualizado: $result filas afectadas");
      return result;
    } catch (e) {
      print("Error actualizando becerro: $e");
      rethrow;
    }
  }

  static Future<void> deleteBecerro(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("becerros", where: "id = ?", whereArgs: [id]);
      print("Becerro eliminado con ID: $id");
    } catch (e) {
      print("Error eliminando becerro: $e");
      rethrow;
    }
  }

  // ========== MÉTODOS PARA PROPIETARIOS ==========
  static Future<int> createPropietario(Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final propietarioData = {
        'nombre': data['nombre'] ?? '',
        'apellido': data['apellido'] ?? '',
        'telefono': data['telefono'] ?? '',
        'email': data['email'] ?? '',
        'direccion': data['direccion'] ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final id = await db.insert(
        'propietarios',
        propietarioData,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      print("Propietario creado con ID: $id");
      return id;
    } catch (e) {
      print("Error creando propietario: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllPropietarios() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query('propietarios', orderBy: "id DESC");
      print("Propietarios obtenidos: ${result.length} registros");
      return result;
    } catch (e) {
      print("Error obteniendo propietarios: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPropietario(int id) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'propietarios',
        where: "id = ?",
        whereArgs: [id],
        limit: 1,
      );
      return result;
    } catch (e) {
      print("Error obteniendo propietario: $e");
      return [];
    }
  }

  static Future<int> updatePropietario(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.update(
        'propietarios',
        data,
        where: "id = ?",
        whereArgs: [id],
      );
      print("Propietario actualizado: $result filas afectadas");
      return result;
    } catch (e) {
      print("Error actualizando propietario: $e");
      rethrow;
    }
  }

  static Future<void> deletePropietario(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("propietarios", where: "id = ?", whereArgs: [id]);
      print("Propietario eliminado con ID: $id");
    } catch (e) {
      print("Error eliminando propietario: $e");
      rethrow;
    }
  }

  // ========== MÉTODOS PARA CORRALES ==========
  static Future<int> createCorral(Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final corralData = {
        'nombre': data['nombre'] ?? '',
        'capacidad': data['capacidad'],
        'ubicacion': data['ubicacion'] ?? '',
        'observaciones': data['observaciones'] ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final id = await db.insert(
        'corrales',
        corralData,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      print("Corral creado con ID: $id");
      return id;
    } catch (e) {
      print("Error creando corral: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllCorrales() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query('corrales', orderBy: "id DESC");
      print("Corrales obtenidos: ${result.length} registros");
      return result;
    } catch (e) {
      print("Error obteniendo corrales: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCorral(int id) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'corrales',
        where: "id = ?",
        whereArgs: [id],
        limit: 1,
      );
      return result;
    } catch (e) {
      print("Error obteniendo corral: $e");
      return [];
    }
  }

  static Future<int> updateCorral(int id, Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.update(
        'corrales',
        data,
        where: "id = ?",
        whereArgs: [id],
      );
      print("Corral actualizado: $result filas afectadas");
      return result;
    } catch (e) {
      print("Error actualizando corral: $e");
      rethrow;
    }
  }

  static Future<void> deleteCorral(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("corrales", where: "id = ?", whereArgs: [id]);
      print("Corral eliminado con ID: $id");
    } catch (e) {
      print("Error eliminando corral: $e");
      rethrow;
    }
  }

  // ========== MÉTODOS DE BÚSQUEDA ==========
  static Future<List<Map<String, dynamic>>> searchAnimales(String query) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tganado',
        where:
            "aretegdo LIKE ? OR nombregdo LIKE ? OR sexogdo LIKE ? OR razagdo LIKE ? OR nacimientogdo LIKE ? OR corralgdo LIKE ? OR alimentogdo LIKE ? OR prodgdo LIKE ? OR estatusgdo LIKE ? OR observaciongdo LIKE ?",
        whereArgs: List.filled(10, '%$query%'),
        orderBy: "idgdo DESC",
      );
      print("Búsqueda animales: ${result.length} resultados para '$query'");
      return result;
    } catch (e) {
      print("Error buscando animales: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchBecerros(String query) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'becerros',
        where: "nombre LIKE ? OR observaciones LIKE ?",
        whereArgs: ['%$query%', '%$query%'],
        orderBy: "id DESC",
      );
      print("Búsqueda becerros: ${result.length} resultados para '$query'");
      return result;
    } catch (e) {
      print("Error buscando becerros: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchPropietarios(
    String query,
  ) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'propietarios',
        where:
            "nombre LIKE ? OR apellido LIKE ? OR telefono LIKE ? OR email LIKE ?",
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: "id DESC",
      );
      print("Búsqueda propietarios: ${result.length} resultados para '$query'");
      return result;
    } catch (e) {
      print("Error buscando propietarios: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchCorrales(String query) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'corrales',
        where: "nombre LIKE ? OR ubicacion LIKE ? OR observaciones LIKE ?",
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: "id DESC",
      );
      print("Búsqueda corrales: ${result.length} resultados para '$query'");
      return result;
    } catch (e) {
      print("Error buscando corrales: $e");
      return [];
    }
  }

  // ========== MÉTODOS DE ESTADÍSTICAS/INFORMES ==========
  static Future<int> getTotalAnimales() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as total FROM tganado');
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      print("Error obteniendo total de animales: $e");
      return 0;
    }
  }

  static Future<int> getTotalBecerros() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM becerros',
      );
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      print("Error obteniendo total de becerros: $e");
      return 0;
    }
  }

  static Future<int> getTotalPropietarios() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM propietarios',
      );
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      print("Error obteniendo total de propietarios: $e");
      return 0;
    }
  }

  static Future<int> getTotalCorrales() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM corrales',
      );
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      print("Error obteniendo total de corrales: $e");
      return 0;
    }
  }

  // ========== MÉTODOS DE ANÁLISIS ADICIONALES ==========
  static Future<List<Map<String, dynamic>>> getAnimalesPorSexo() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery('''
        SELECT sexogdo, COUNT(*) as cantidad 
        FROM tganado 
        WHERE sexogdo IS NOT NULL AND sexogdo != '' 
        GROUP BY sexogdo
      ''');
      return result;
    } catch (e) {
      print("Error obteniendo animales por sexo: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAnimalesPorRaza() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery('''
        SELECT razagdo, COUNT(*) as cantidad 
        FROM tganado 
        WHERE razagdo IS NOT NULL AND razagdo != '' 
        GROUP BY razagdo
        ORDER BY cantidad DESC
      ''');
      return result;
    } catch (e) {
      print("Error obteniendo animales por raza: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAnimalesPorEstatus() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery('''
        SELECT estatusgdo, COUNT(*) as cantidad 
        FROM tganado 
        WHERE estatusgdo IS NOT NULL AND estatusgdo != '' 
        GROUP BY estatusgdo
      ''');
      return result;
    } catch (e) {
      print("Error obteniendo animales por estatus: $e");
      return [];
    }
  }

  // ========== MÉTODOS DE LIMPIEZA ==========
  static Future<void> closeDatabase() async {
    try {
      // Sqflite maneja el cierre automáticamente en la mayoría de los casos
      print("Manejador de base de datos cerrado");
    } catch (e) {
      print("Error cerrando base de datos: $e");
    }
  }

  // ========== MÉTODO PARA VERIFICAR CONEXIÓN ==========
  static Future<bool> testConnection() async {
    try {
      final db = await SQLHelper.db();
      final result = await db.rawQuery('SELECT 1 as test');
      await db.close();
      return result.isNotEmpty;
    } catch (e) {
      print("Error en test de conexión: $e");
      return false;
    }
  }
}

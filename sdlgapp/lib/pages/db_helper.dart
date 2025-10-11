import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static bool _tablesCreated = false;

  // Método para inicializar todas las tablas
  static Future<void> createAllTables(sql.Database database) async {
    try {
      print("Creando tablas...");

      // Tabla de tganado
      await database.execute("""CREATE TABLE IF NOT EXISTS tganado(
        idgdo INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        aretegdo NUMERIC,
        nombregdo TEXT,
        sexogdo TEXT,
        razagdo TEXT,
        nacimientogdo NUMERIC,
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
        fechaNacimiento NUMERIC,
        pesoNacimiento NUMERIC,
        observaciones TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");
      print("Tabla 'propietarios' creada/verificada");

      // Tabla de Corrales
      await database.execute("""CREATE TABLE IF NOT EXISTS corrales(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nombre TEXT,
        capacidad INTEGER,
        ubicacion TEXT,
        observaciones TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )""");
      print("Tabla 'corrales' creada/verificada");

      _tablesCreated = true;
      print("Todas las tablas creadas exitosamente");
    } catch (e) {
      print("Error creando tablas: $e");
      rethrow;
    }
  }

  static Future<sql.Database> db() async {
    try {
      final database = await sql.openDatabase(
        'SDLGAPP.db',
        version: 1,
        onCreate: (sql.Database database, int version) async {
          print("Base de datos creada por primera vez");
          await createAllTables(database);
        },
      );

      // Si las tablas no están creadas, forzar creación
      if (!_tablesCreated) {
        await createAllTables(database);
      }

      return database;
    } catch (e) {
      print("Error crítico abriendo base de datos: $e");
      rethrow;
    }
  }

  // Método para resetear la base de datos
  static Future<void> resetDatabase() async {
    try {
      final database = await db();
      await database.close();
      await sql.deleteDatabase('SDLGAPP.db');
      print("Base de datos reiniciada exitosamente");
      _tablesCreated = false; // Resetear el flag
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

  // ========== MÉTODOS PARA ANIMALES ========== **** NOMBRE DE LA TABLA: tganado****
  static Future<int> createAnimal(Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      // Asegurar que los campos opcionales tengan valores por defecto
      final animalData = {
        'aretegdo': data['aretegdo'] ?? '',
        'nombregdo': data['nombregdo'] ?? '',
        'sexogdo': data['sexogdo'] ?? '',
        'razagdo': data['razagdo'] ?? '',
        'nacimientogdo': data['nacimientogdo'] ?? '',
        'corralgdo': data['corralgdo'],
        'alimentogdo': data['alimentogdo'] ?? '',
        'prodgdo': data['prodgdo'],
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
      // Debug adicional
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
      // Debug adicional
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
      print("Datos recibidos: $data");

      // Verificar que la tabla existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='tganado'",
      );

      if (tables.isEmpty) {
        throw Exception("La tabla 'tganado' no existe");
      }

      // Verificar que el animal existe
      final animalExistente = await db.query(
        'tganado',
        where: "idgdo = ?",
        whereArgs: [idgdo],
      );

      if (animalExistente.isEmpty) {
        throw Exception("Animal con ID $idgdo no encontrado");
      }

      print("Animal encontrado: ${animalExistente.first}");

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
      print("Stack trace: ${e.toString()}");
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
        whereArgs: [
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
        ],
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
        orderBy: "idbece DESC",
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
        where: "nombre LIKE ? OR apellido LIKE ? OR telefono LIKE ?",
        whereArgs: ['%$query%', '%$query%', '%$query%'],
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
        where: "nombre LIKE ? OR ubicacion LIKE ?",
        whereArgs: ['%$query%', '%$query%'],
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
      return result.first['total'] as int;
    } catch (e) {
      print("Error obteniendo total de tganado: $e");
      return 0;
    }
  }

  static Future<int> getTotalBecerros() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM becerros',
      );
      return result.first['total'] as int;
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
      return result.first['total'] as int;
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
      return result.first['total'] as int;
    } catch (e) {
      print("Error obteniendo total de corrales: $e");
      return 0;
    }
  }

  // ========== MÉTODOS DE LIMPIEZA ==========
  static Future<void> closeDatabase() async {
    try {
      final database = await db();
      await database.close();
      print("Base de datos cerrada");
    } catch (e) {
      print("Error cerrando base de datos: $e");
    }
  }
}

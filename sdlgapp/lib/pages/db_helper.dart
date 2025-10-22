// db_helper.dart - Versión completa y corregida
import 'package:path_provider/path_provider.dart';
import 'package:sdlgapp/pages/PagAnimales.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class SQLHelper {
  static Future<void> debugDatabaseLocation() async {
    try {
      final databasePath = await sql.getDatabasesPath();
      final String dbPath = path.join(databasePath, 'SDLGAPP.db');
      // estas partes nomás es como para verlo desde la terminal y checar que todo esté bien con la bdd
      print("=== INFORMACIÓN DETALLADA DE LA BD ===");
      print("📁 Directorio de bases de datos: $databasePath");
      print("🗂️ Ruta completa de la BD: $dbPath");

      // Verificar si el archivo existe
      final dbFile = File(dbPath);
      final exists = await dbFile.exists();
      print("✅ ¿Archivo de BD existe?: $exists");

      if (exists) {
        final stat = await dbFile.stat();
        print("📊 Tamaño del archivo: ${stat.size} bytes");
        print("🕐 Última modificación: ${stat.modified}");
      } else {
        print("❌ El archivo de BD NO existe aún");
      }

      // aqui se verifica el directorio y q es lo q contiene
      final dir = Directory(databasePath);
      final dirExists = await dir.exists();
      print("📂 ¿Directorio existe?: $dirExists");

      if (dirExists) {
        final files = await dir.list().toList();
        print("📄 Archivos en el directorio:");
        for (var file in files) {
          if (file is File) {
            final fileStat = await file.stat();
            print("   - ${file.path} (${fileStat.size} bytes)");
          }
        }
      } //este nomás es el cierre xd tiene un marco para ver donde termina
      print("======================================");
    } catch (e) {
      //este es un catch por si hay algun error que diga en donde está
      print("❌ Error en debugDatabaseLocation: $e");
    }
  }

  static Future<void> exportRealDatabase() async {
    try {
      // Aquí se obtiene la ruta "real" de la base de datos, en donde se está guardando en el telefono
      final databasePath = await sql.getDatabasesPath();
      final dbFile = File('$databasePath/SDLGAPP.db');

      if (!await dbFile.exists()) {
        print("❌ El archivo de base de datos no existe");
        return;
      }

      // Verificar que es un archivo SQLite válido basado en el tamaño
      final stat = await dbFile.stat();
      print("📊 Tamaño real de la BD: ${stat.size} bytes");

      if (stat.size < 8192) {
        // SQLite mínimo suele ser >8KB
        print("❌ Archivo de BD demasiado pequeño, quizás esté corrupto");
        return;
      }

      // esto es para obtener el directorio de descargas del telefono
      final downloadsDirectory = await getDownloadsDirectory();
      final exportFile = File('${downloadsDirectory?.path}/SDLGAPP_export.db');

      // Este copia el archivo de la base de datos
      await dbFile.copy(exportFile.path);

      print("✅ Base de datos exportada correctamente");
      print("📁 Ruta: ${exportFile.path}");
      print("📊 Tamaño: ${stat.size} bytes");

      // También crear un reporte de texto con los datos
      await _createDataReport();

      // Compartir el archivo de la base de datos, este da la opción de mandarlo por los medios q te permita el celular
      //el emulador deja mandarlo por correo, en un telefono real te deja mandarlo en otras opciones xD ya cuando lo mandas
      //lo puedes decargar desde la compu y checar la bdd si es necesario, iwal despues podemos trabajar con esto para ver
      //lo de pasar los datos entre telefono y computadora
      await Share.shareXFiles(
        [XFile(exportFile.path)],
        subject: 'Base de Datos SDLGAPP - Archivo Real',
        text:
            'Archivo real de la base de datos SDLGAPP\n'
            'Fecha: ${DateTime.now()}\n'
            'Tamaño: ${stat.size} bytes\n'
            'Puedes abrirlo con DB Browser for SQLite',
      );
    } catch (e) {
      print("❌ Error exportando base de datos real: $e");

      // esto es para exportar los datos como texto en caso de que falle lo de la bdd real
      await exportDataAsText();
    }
  }

  // este método es para crear un reporte de texto con los datos de la bdd
  static Future<void> _createDataReport() async {
    try {
      final db = await SQLHelper.db();
      final directory = await getDownloadsDirectory();
      final reportFile = File('${directory?.path}/database_report.txt');

      final animales = await db.query('tganado');
      final salud = await db.query('tsalud');

      final report = StringBuffer();
      report.writeln('REPORTE DE BASE DE DATOS - SDLGAPP');
      report.writeln('Generado: ${DateTime.now()}');
      report.writeln('');
      report.writeln('ANIMALES REGISTRADOS: ${animales.length}');
      report.writeln('=' * 50);

      for (var animal in animales) {
        report.writeln('ID: ${animal['idgdo']}');
        report.writeln('  Nombre: ${animal['nombregdo']}');
        report.writeln('  Arete: ${animal['aretegdo']}');
        report.writeln('  Sexo: ${animal['sexogdo']}');
        report.writeln('  Raza: ${animal['razagdo']}');
        report.writeln('  Fecha Nac: ${animal['nacimientogdo']}');
        report.writeln('  Corral: ${animal['corralgdo']}');
        report.writeln('  Estatus: ${animal['estatusgdo']}');
        if (animal['fotogdo'] != null &&
            animal['fotogdo'].toString().isNotEmpty) {
          report.writeln('  ✅ Tiene foto');
        }
        report.writeln('---');
      }

      report.writeln('');
      report.writeln('REGISTROS DE SALUD: ${salud.length}');
      report.writeln('=' * 50);

      for (var registro in salud) {
        report.writeln('ID: ${registro['idsalud']}');
        report.writeln('  Arete Animal: ${registro['areteanimal']}');
        report.writeln('  Veterinario: ${registro['nomvet']}');
        report.writeln('  Procedimiento: ${registro['procedimiento']}');
        report.writeln('  Fecha: ${registro['fecharev']}');
        report.writeln('---');
      }

      await reportFile.writeAsString(report.toString());
      print("📄 Reporte de datos creado: ${reportFile.path}");
    } catch (e) {
      print("❌ Error creando reporte: $e");
    }
  }

  // este método es para exportar los datos como texto en caso de que falle lo de la bdd real
  static Future<void> exportDataAsText() async {
    try {
      final db = await SQLHelper.db();
      final directory = await getDownloadsDirectory();
      final file = File('${directory?.path}/datos_completos.txt');

      final animales = await db.query('tganado');
      final salud = await db.query('tsalud');
      final becerros = await db.query('tbecerros');

      final content = StringBuffer();
      content.writeln('=== DATOS COMPLETOS SDLGAPP ===');
      content.writeln('Fecha: ${DateTime.now()}');
      content.writeln('');

      content.writeln('🐮 ANIMALES (${animales.length}):');
      for (var animal in animales) {
        content.writeln('  ID: ${animal['idgdo']}');
        content.writeln('  Nombre: ${animal['nombregdo']}');
        content.writeln('  Arete: ${animal['aretegdo']}');
        content.writeln('  Sexo: ${animal['sexogdo']}');
        content.writeln('  Raza: ${animal['razagdo']}');
        content.writeln('  -----------------');
      }

      content.writeln('');
      content.writeln('🏥 SALUD (${salud.length}):');
      for (var reg in salud) {
        content.writeln('  ID: ${reg['idsalud']}');
        content.writeln('  Arete: ${reg['areteanimal']}');
        content.writeln('  Procedimiento: ${reg['procedimiento']}');
        content.writeln('  -----------------');
      }

      await file.writeAsString(content.toString());

      // Compartir el reporte de texto
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Datos SDLGAPP - Reporte',
        text: 'Reporte completo de datos de la aplicación SDLGAPP',
      );

      print("✅ Datos exportados como texto: ${file.path}");
    } catch (e) {
      print("❌ Error exportando datos como texto: $e");
    }
  }

  // este método es para ver lo de las imágenes de los animales y ver si existen o no
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

  //aca empieza todo lo de la creación de las tablas de las base de datos y los metodos de editar y eliminar ***************************
  static Future<void> createAllTables(sql.Database database) async {
    try {
      print("Creando tablas...");

      // ************* Tabla de tganado ************* esta ya está completa
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

      // ************* Tabla de tsalud ************* este ya está completo, es el de los registros de salud de los ANIMALES, no de los becerros
      await database.execute("""CREATE TABLE IF NOT EXISTS tsalud(
      idsalud INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      areteanimal TEXT NOT NULL,
      nomvet TEXT,
      procedimiento TEXT,
      condicionsalud TEXT,
      fecharev TEXT,
      observacionsalud TEXT,
      archivo TEXT
    )""");
      print("Tabla 'tsalud' creada/verificada");

      // ************* Tabla de tbecerros *************
      await database.execute("""CREATE TABLE IF NOT EXISTS tbecerros(
        idbece INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        aretebece TEXT,
        nombrebece TEXT,
        pesobece TEXT,
        sexobece TEXT,
        razabece TEXT,
        nacimientobece TEXT,
        corralbece TEXT,
        estatusbece TEXT,
        aretemadre TEXT,
        observacionbece TEXT,
        fotobece TEXT
      )""");
      print("Tabla 'tbecerros' creada/verificada");

      // ************* Tabla de tpropietarios *************
      await database.execute("""CREATE TABLE IF NOT EXISTS tpropietarios(
        idprop INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nombreprop TEXT,
        telprop TEXT,
        correoprop TEXT,
        dirprop TEXT,
        rfcprop TEXT,
        psgprop TEXT,
        uppprop TEXT,
        observacionprop TEXT,
        fotoprop TEXT
      )""");
      print("Tabla 'tpropietarios' creada/verificada");

      // ************* Tabla de tcorral ************* identcorral es el numero identificador del corral pq segun con eso los idntifican
      //pero igual puse nombre por si acaso
      await database.execute("""CREATE TABLE IF NOT EXISTS tcorral(
        idcorral INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        identcorral TEXT, 
        nomcorral TEXT,
        ubicorral TEXT,
        capmax TEXT,
        capactual TEXT,
        fechamant TEXT,
        condicion TEXT,
        observacioncorral TEXT
      )""");
      print("Tabla 'tcorral' creada/verificada");

      // ************* Tabla de treprod  ************* REPRODUCCION SOLO DE HEMBRAS
      //ESTA TABLA es solo para llevar control de reproducción de las hembras
      await database.execute("""CREATE TABLE IF NOT EXISTS treprod(
        idreprod INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        cargada TEXT, 
        cantpartos TEXT,
        fcargadoactual TEXT,
        tecnica TEXT,
        areteanimal TEXT
      )""");
      print("Tabla 'treprod' creada/verificada");

      // ************* Tabla de usuarios ************* este es para el log in, no se crearán desde aquí
      //los datos se jalarán desde la PC y se mandaran al telefono para q los valide
      await database.execute("""CREATE TABLE IF NOT EXISTS tusuarios(
        idusuario INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        nombre TEXT,
        telefono TEXT,
        usuario TEXT,
        pass TEXT,
        rol TEXT
      )""");
      print("Tabla 'tusuarios' creada/verificada");

      //Si todas las tablas se crearon en la terminal mostrara este mensaje
      print("Todas las tablas creadas exitosamente");
    } catch (e) {
      //Si hubo algun error mandara este mensaje con el nombre de la tabla junto con el error que paso
      print("Error creando tablas: $e");
      rethrow;
    }
  }

  // Este es el método para resetear la base de datos, este sirve para estar haciendo pruebas cuando cambias datos o así de q necesites
  // estar borrando la bdd y volver a crearla de 0, pero si ya no lo ocupas lo quitas en el main.dart
  // (es en la linea 57 mas o menos xD dice algo como await SQLHelper.resetDatabase(); , a ese nomás lo comentas y
  // ya no se reiniciará la bdd)
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

  // Método para debugear xD o verificar el estado de la base de datos, este nomás se muestra en la terminal y es para ir checando si
  //se esta creando bien o q esta pasando si hay errores
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

  // =========== Métodos de salud para animales ===========

  //Este es para crear un registro de salud para un animal
  static Future<int> createRegistroSalud(Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final saludData = {
        'areteanimal': data['areteanimal'] ?? '',
        'nomvet': data['nomvet'] ?? '',
        'procedimiento': data['procedimiento'] ?? '',
        'condicionsalud': data['condicionsalud'] ?? '',
        'fecharev': data['fecharev'] ?? '',
        'observacionsalud': data['observacionsalud'] ?? '',
        'archivo': data['archivo'] ?? '',
      };

      final id = await db.insert(
        'tsalud',
        saludData,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      print("Registro de salud creado con ID: $id");
      return id;
    } catch (e) {
      print("Error creando registro de salud: $e");
      rethrow;
    }
  }

  // Obtener registros por arete del animal (búsqueda flexible)
  static Future<List<Map<String, dynamic>>> getRegistrosSaludPorArete(
    String areteanimal,
  ) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tsalud',
        where: "areteanimal LIKE ?",
        whereArgs: ['%$areteanimal%'],
        orderBy: "fecharev DESC",
      );
      print(
        "Registros de salud obtenidos: ${result.length} para arete $areteanimal",
      );
      return result;
    } catch (e) {
      print("Error obteniendo registros de salud: $e");
      return [];
    }
  }

  // Búsqueda general en registros de salud
  static Future<List<Map<String, dynamic>>> searchRegistrosSalud(
    String query,
  ) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tsalud',
        where: "areteanimal LIKE ? OR nomvet LIKE ? OR procedimiento LIKE ?",
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: "fecharev DESC",
      );
      print("Búsqueda salud: ${result.length} resultados para '$query'");
      return result;
    } catch (e) {
      print("Error buscando registros de salud: $e");
      return [];
    }
  }

  // Los métodos updateRegistroSalud y deleteRegistroSalud se mantienen igual
  static Future<int> updateRegistroSalud(
    int idsalud,
    Map<String, dynamic> data,
  ) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.update(
        'tsalud',
        data,
        where: "idsalud = ?",
        whereArgs: [idsalud],
      );
      print("Registro de salud actualizado: $result filas afectadas");
      return result;
    } catch (e) {
      print("Error actualizando registro de salud: $e");
      rethrow;
    }
  }

  static Future<void> deleteRegistroSalud(int idsalud) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("tsalud", where: "idsalud = ?", whereArgs: [idsalud]);
      print("Registro de salud eliminado con ID: $idsalud");
    } catch (e) {
      print("Error eliminando registro de salud: $e");
      rethrow;
    }
  }

  // ************* Métodos para animales xd *************

  //este es para crear un animal
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

  //este es para saber cuantos datos hay en la tabla de animales
  //nomas se ve en la terminal y sirve tbn para q muestre o no un mensaje en la interfaz
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

  //obtener los datos de un animal en especifico, sirve para
  //cuando se va a editar o eliminar
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

      // este es para filtrar los campos que se van a actualizar
      // para evitar errores si se manda algun campo que no existe en la tabla
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

  //eliminar animal
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

  // ************* Métodos para becerros *************

  //Este es para crear un becerro
  static Future<int> createBecerro(Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final becerroData = {
        'aretebece': data['aretebece'] ?? '',
        'nombrebece': data['nombrebece'] ?? '',
        'pesobece': data['pesobece'] ?? '',
        'sexobece': data['sexobece'] ?? '',
        'razabece': data['razabece'] ?? '',
        'nacimientobece': data['nacimientobece'] ?? '',
        'corralbece': data['corralbece'] ?? '',
        'estatusbece': data['estatusbece'] ?? '',
        'aretemadre': data['aretemadre'] ?? '',
        'observacionbece': data['observacionbece'] ?? '',
        'fotobece': data['fotobece'] ?? '',
      };

      final idbece = await db.insert(
        'tbecerros',
        becerroData,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      print("Becerro creado con ID: $idbece");
      return idbece;
    } catch (e) {
      print("Error creando becerro: $e");
      rethrow;
    }
  }

  //este es para saber cuantos datos hay en esta tabla xD
  //nomás se muestra en la terminal y ayuda a poner el mensaje de "no hay becerros" en la interfaz
  static Future<List<Map<String, dynamic>>> getAllBecerros() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query('tbecerros', orderBy: "idbece DESC");
      print("Becerros obtenidos: ${result.length} registros");
      return result;
    } catch (e) {
      print("Error obteniendo becerros: $e");
      return [];
    }
  }

  //este sirve para obtener los datos por ejemplo cuando hay q editar o eliminar
  static Future<List<Map<String, dynamic>>> getBecerro(int idbece) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tbecerros',
        where: "idbece = ?",
        whereArgs: [idbece],
        limit: 1,
      );
      return result;
    } catch (e) {
      print("Error obteniendo becerro: $e");
      return [];
    }
  }

  //este es el de actualizar
  static Future<int> updateBecerro(
    int idbece,
    Map<String, dynamic> data,
  ) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.update(
        'tbecerros',
        data,
        where: "idbece = ?",
        whereArgs: [idbece],
      );
      print("Becerro actualizado: $result filas afectadas");
      return result;
    } catch (e) {
      print("Error actualizando becerro: $e");
      rethrow;
    }
  }

  //este es el de eliminar
  static Future<void> deleteBecerro(int idbece) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("tbecerros", where: "idbece = ?", whereArgs: [idbece]);
      print("Becerro eliminado con ID: $idbece");
    } catch (e) {
      print("Error eliminando becerro: $e");
      rethrow;
    }
  }

  // ************* Métodos para propietarios *************

  //este es para crear un nuevo propietario
  static Future<int> createPropietario(Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final propietarioData = {
        'nombreprop': data['nombreprop'] ?? '',
        'telprop': data['telprop'] ?? '',
        'correoprop': data['correoprop'] ?? '',
        'dirprop': data['dirprop'] ?? '',
        'rfcprop': data['rfcprop'] ?? '',
        'psgprop': data['psgprop'] ?? '',
        'uppprop': data['uppprop'] ?? '',
        'observacionprop': data['observacionprop'] ?? '',
        'fotoprop': data['fotoprop'] ?? '',
      };

      final idprop = await db.insert(
        'tpropietarios',
        propietarioData,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      print("Propietario creado con ID: $idprop");
      return idprop;
    } catch (e) {
      print("Error creando propietario: $e");
      rethrow;
    }
  }

  //este es para obtener todos los propietarios
  //sirve para mostrar cuantos hay y poner el mensaje de "no hay propietarios" en la interfaz
  static Future<List<Map<String, dynamic>>> getAllPropietarios() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query('tpropietarios', orderBy: "idprop DESC");
      print("Propietarios obtenidos: ${result.length} registros");
      return result;
    } catch (e) {
      print("Error obteniendo propietarios: $e");
      return [];
    }
  }

  //este es para obtener los datos del propietario seleccionado
  static Future<List<Map<String, dynamic>>> getPropietario(int idprop) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tpropietarios',
        where: "idprop = ?",
        whereArgs: [idprop],
        limit: 1,
      );
      return result;
    } catch (e) {
      print("Error obteniendo propietario: $e");
      return [];
    }
  }

  //este es para actualizar un propietario
  static Future<int> updatePropietario(
    int idprop,
    Map<String, dynamic> data,
  ) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.update(
        'tpropietarios',
        data,
        where: "idprop = ?",
        whereArgs: [idprop],
      );
      print("Propietario actualizado: $result filas afectadas");
      return result;
    } catch (e) {
      print("Error actualizando propietario: $e");
      rethrow;
    }
  }

  //este es para eliminar un propietario
  static Future<void> deletePropietario(int idprop) async {
    final db = await SQLHelper.db();
    try {
      await db.delete(
        "tpropietarios",
        where: "idprop = ?",
        whereArgs: [idprop],
      );
      print("Propietario eliminado con ID: $idprop");
    } catch (e) {
      print("Error eliminando propietario: $e");
      rethrow;
    }
  }

  // ************* Métodos para corrales *************
  //este es para crear un nuevo corral
  static Future<int> createCorral(Map<String, dynamic> data) async {
    final db = await SQLHelper.db();
    try {
      final corralData = {
        'identcorral': data['identcorral'] ?? '',
        'nomcorral': data['nomcorral'] ?? '',
        'ubicorral': data['ubicorral'] ?? '',
        'capmax': data['capmax'] ?? '',
        'capactual': data['capactual'] ?? '',
        'fechamant': data['fechamant'] ?? '',
        'condicion': data['condicion'] ?? '',
        'observacioncorral': data['observacioncorral'] ?? '',
      };

      final idcorral = await db.insert(
        'tcorral',
        corralData,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      print("Corral creado con ID: $idcorral");
      return idcorral;
    } catch (e) {
      print("Error creando corral: $e");
      rethrow;
    }
  }

  //este es para obtener todos los corrales
  //sirve para mostrar cuantos hay y poner el mensaje de "no hay corrales" en la interfaz
  static Future<List<Map<String, dynamic>>> getAllCorrales() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query('tcorral', orderBy: "idcorral DESC");
      print("Corrales obtenidos: ${result.length} registros");
      return result;
    } catch (e) {
      print("Error obteniendo corrales: $e");
      return [];
    }
  }

  //este es para obtener los datos del corral seleccionado
  static Future<List<Map<String, dynamic>>> getCorral(int idcorral) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tcorral',
        where: "idcorral = ?",
        whereArgs: [idcorral],
        limit: 1,
      );
      return result;
    } catch (e) {
      print("Error obteniendo corral: $e");
      return [];
    }
  }

  //este es para actualizar un corral en especifico
  static Future<int> updateCorral(
    int idcorral,
    Map<String, dynamic> data,
  ) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.update(
        'tcorral',
        data,
        where: "idcorral = ?",
        whereArgs: [idcorral],
      );
      print("Corral actualizado: $result filas afectadas");
      return result;
    } catch (e) {
      print("Error actualizando corral: $e");
      rethrow;
    }
  }

  //este es para eliminar el corral seleccionado
  static Future<void> deleteCorral(int idcorral) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("tcorral", where: "idcorral = ?", whereArgs: [idcorral]);
      print("Corral eliminado con ID: $idcorral");
    } catch (e) {
      print("Error eliminando corral: $e");
      rethrow;
    }
  }

  // ************* Métodos de búsqueda *************

  //búsqueda general en animales
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

  //búsqueda general en becerros
  static Future<List<Map<String, dynamic>>> searchBecerros(String query) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tbecerros',
        where:
            "aretebece LIKE ? OR nombrebece LIKE ? OR sexobece LIKE ? OR observacionbece LIKE ?",
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: "idbece DESC",
      );
      print("Búsqueda becerros: ${result.length} resultados para '$query'");
      return result;
    } catch (e) {
      print("Error buscando becerros: $e");
      return [];
    }
  }

  //búsqueda general en propietarios
  static Future<List<Map<String, dynamic>>> searchPropietarios(
    String query,
  ) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tpropietarios',
        where:
            "nombreprop LIKE ? OR telprop LIKE ? OR correoprop LIKE ? OR dirprop LIKE ? OR LIKE rfcprop LIKE ? OR psgprop LIKE ? OR uppprop LIKE ? OR observacionprop LIKE ?",
        whereArgs: [
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
        ],
        orderBy: "idprop DESC",
      );
      print("Búsqueda propietarios: ${result.length} resultados para '$query'");
      return result;
    } catch (e) {
      print("Error buscando propietarios: $e");
      return [];
    }
  }

  //búsqueda general en corrales
  static Future<List<Map<String, dynamic>>> searchCorrales(String query) async {
    final db = await SQLHelper.db();
    try {
      final result = await db.query(
        'tcorral',
        where:
            "identcorral LIKE ? OR nomcorral LIKE ? OR ubicorral LIKE ? OR condicion LIKE ? OR observacioncorral LIKE ? OR capmax LIKE ? OR capactual LIKE ?",
        whereArgs: [
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
          '%$query%',
        ],
        orderBy: "idcorral DESC",
      );
      print("Búsqueda corrales: ${result.length} resultados para '$query'");
      return result;
    } catch (e) {
      print("Error buscando corrales: $e");
      return [];
    }
  }

  // ************* Métodos de estadísticas/informes ************* ESTE ES para las estadisticas del inicio xd

  //este es para obtener el total de animales en la tabla de tganado
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

  //este es para obtener el total de becerros en la tabla de tbecerros
  static Future<int> getTotalBecerros() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM tbecerros',
      );
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      print("Error obteniendo total de becerros: $e");
      return 0;
    }
  }

  //este es para obtener el total de propietarios en la tabla de tpropietarios
  static Future<int> getTotalPropietarios() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM tpropietarios',
      );
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      print("Error obteniendo total de tpropietarios: $e");
      return 0;
    }
  }

  //este es para obtener el total de corrales en la tabla de tcorrales
  static Future<int> getTotalCorrales() async {
    final db = await SQLHelper.db();
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as total FROM tcorral');
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      print("Error obteniendo total de corrales: $e");
      return 0;
    }
  }

  // ************* Métodos de análisis adicionales *************
  //este es para obtener los datos y agruparlos por cantidad de animales por sexo
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

  //este es para obtener los datos y agruparlos por cantidad de animales por raza
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

  //este es para obtener los datos y agruparlos por cantidad de animales por estatus
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

  // ************* Métodos de limpieza *************
  static Future<void> closeDatabase() async {
    try {
      // Sqflite maneja el cierre automáticamente en la mayoría de los casos
      print("Manejador de base de datos cerrado");
    } catch (e) {
      print("Error cerrando base de datos: $e");
    }
  }

  // ************* Método para verificar conexión *************
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

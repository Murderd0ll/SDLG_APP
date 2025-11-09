import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

//Importación de las páginas del bottom navigation bar
import 'package:sdlgapp/pages/PagAnimales.dart';
import 'package:sdlgapp/pages/PagBecerros.dart';
import 'package:sdlgapp/pages/PagCorrales.dart';
import 'package:sdlgapp/pages/PagInicio.dart';
import 'package:sdlgapp/pages/PagPropietarios.dart';
import 'package:sdlgapp/pages/db_helper.dart';
import 'package:sdlgapp/pages/login_page.dart';
import 'package:sdlgapp/pages/splash_screen.dart';

void main() {
  runApp(SDLGAPP());
}

class SDLGAPP extends StatelessWidget {
  const SDLGAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      title: "SDLG",
      home: SplashScreen(),
    );
  }
}

class Inicio extends StatefulWidget {
  final Map<String, dynamic>? user;
  const Inicio({super.key, this.user});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  // Datos para cada página
  List<Map<String, dynamic>> _animalesData = [];
  List<Map<String, dynamic>> _becerrosData = [];
  List<Map<String, dynamic>> _propietariosData = [];
  List<Map<String, dynamic>> _corralesData = [];

  Map<String, dynamic>? _currentUser;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    print("=== INICIANDO APLICACIÓN PRINCIPAL ===");
    print("Usuario: ${_currentUser?['nombre']}");
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      print("=== CARGANDO DATOS EN INICIO ===");

      // Cargar datos iniciales de manera asíncrona
      await _cargarDatosIniciales();

      setState(() {
        _isLoading = false;
      });

      print("=== DATOS CARGADOS EXITOSAMENTE ===");
    } catch (e) {
      print("❌ Error en _initializeApp: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método separado para cargar datos iniciales
  Future<void> _cargarDatosIniciales() async {
    try {
      // Cargar todos los datos necesarios para la página actual
      switch (_pagActual) {
        case 1: // Becerros
          await _refreshBecerros();
          break;
        case 2: // Animales
          await _refreshAnimales();
          break;
        case 3: // Propietarios
          await _refreshPropietarios();
          break;
        case 4: // Corrales
          await _refreshCorrales();
          break;
        default: // Inicio
          // Para la página de inicio, no necesitamos cargar datos pesados
          await Future.delayed(Duration(milliseconds: 100));
          break;
      }
    } catch (e) {
      print("❌ Error cargando datos iniciales: $e");
      rethrow;
    }
  }

  // Métodos para cargar datos específicos
  Future<void> _refreshAnimales() async {
    try {
      print("Cargando animales...");
      final data = await SQLHelper.getAllAnimales();
      setState(() {
        _animalesData = data;
      });
      print("Animales cargados: ${data.length} registros");
    } catch (e) {
      print("❌ Error en _refreshAnimales: $e");
      rethrow;
    }
  }

  Future<void> _refreshBecerros() async {
    try {
      print("Cargando becerros...");
      final data = await SQLHelper.getAllBecerros();
      setState(() {
        _becerrosData = data;
      });
      print("Becerros cargados: ${data.length} registros");
    } catch (e) {
      print("❌ Error en _refreshBecerros: $e");
      rethrow;
    }
  }

  Future<void> _refreshPropietarios() async {
    try {
      print("Cargando propietarios...");
      final data = await SQLHelper.getAllPropietarios();
      setState(() {
        _propietariosData = data;
      });
      print("Propietarios cargados: ${data.length} registros");
    } catch (e) {
      print("❌ Error en _refreshPropietarios: $e");
      rethrow;
    }
  }

  Future<void> _refreshCorrales() async {
    try {
      print("Cargando corrales...");
      final data = await SQLHelper.getAllCorrales();
      setState(() {
        _corralesData = data;
      });
      print("Corrales cargados: ${data.length} registros");
    } catch (e) {
      print("❌ Error en _refreshCorrales: $e");
      rethrow;
    }
  }

  // Cargar datos cuando cambia la página
  void _cargarDatosPagina(int pagina) async {
    print("Cambiando a página: $pagina");

    setState(() {
      _isLoading = true;
      _pagActual = pagina;
      if (pagina < 3) {
        _bottomNavIndex = pagina;
      }
    });

    try {
      switch (pagina) {
        case 1: // Becerros
          await _refreshBecerros();
          break;
        case 2: // Animales
          await _refreshAnimales();
          break;
        case 3: // Propietarios
          await _refreshPropietarios();
          break;
        case 4: // Corrales
          await _refreshCorrales();
          break;
        default: // Inicio
          // No necesita carga de datos
          break;
      }
    } catch (e) {
      print("❌ Error cargando datos de página $pagina: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para mostrar diálogo de confirmación de salida
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cerrar aplicación'),
          content: Text('¿Estás seguro de que quieres salir de la aplicación?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                SystemNavigator.pop(); // Cierra la aplicación
              },
              child: Text('Salir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  //lógica del drawer y del bottom navigation bar
  int _pagActual = 0;
  int _bottomNavIndex = 0;

  // Lista de páginas con datos pasados como parámetros
  List<Widget> get _paginas => [
    PagInicio(),
    PagBecerros(
      data: _becerrosData,
      onRefresh: _refreshBecerros,
      isLoading: _isLoading,
    ),
    PagAnimales(
      data: _animalesData,
      onRefresh: _refreshAnimales,
      isLoading: _isLoading,
    ),
    PagPropietarios(
      data: _propietariosData,
      onRefresh: _refreshPropietarios,
      isLoading: _isLoading,
    ),
    PagCorrales(
      data: _corralesData,
      onRefresh: _refreshCorrales,
      isLoading: _isLoading,
    ),
  ];

  //Función para cambiar de página desde el drawer
  void _cambiarPaginaDesdeDrawer(int nuevaPagina) {
    _cargarDatosPagina(nuevaPagina);
    Navigator.pop(context);
  }

  //función para cambiar de página desde el bottom navigation bar
  void _cambiarPaginaDesdeBottomNav(int index) {
    _cargarDatosPagina(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 9, 12, 14),
        child: ListView(
          children: [
            SizedBox(
              height: 160,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 27, 26, 34),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SDLG',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_currentUser != null) ...[
                      Text(
                        'Usuario: ${_currentUser!['nombre']}',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        'Rol: ${_currentUser!['rol']}',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ListTile(
              iconColor: Color.fromARGB(255, 255, 255, 255),
              textColor: Colors.white,
              leading: Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () => _cambiarPaginaDesdeDrawer(0),
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: Icon(Symbols.pediatrics, weight: 700),
              title: const Text('Becerros'),
              onTap: () => _cambiarPaginaDesdeDrawer(1),
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: FaIcon(FontAwesomeIcons.cow),
              title: const Text('Animales'),
              onTap: () => _cambiarPaginaDesdeDrawer(2),
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: Icon(Icons.person),
              title: const Text('Propietarios'),
              onTap: () => _cambiarPaginaDesdeDrawer(3),
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: Icon(Icons.fence),
              title: const Text('Corrales'),
              onTap: () => _cambiarPaginaDesdeDrawer(4),
            ),
            const Divider(color: Colors.white70),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: Icon(Icons.exit_to_app),
              title: const Text('Salir'),
              onTap: () {
                Navigator.pop(context);
                _showExitConfirmation(context);
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 27, 26, 34),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        toolbarHeight: 60,
        title: Text(
          _getAppBarTitle(_pagActual),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: _paginas[_pagActual],

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color.fromARGB(255, 182, 128, 128),
        unselectedItemColor: Colors.grey,
        onTap: _cambiarPaginaDesdeBottomNav,
        currentIndex: _bottomNavIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(
            icon: Icon(Symbols.pediatrics),
            label: "Becerros",
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.cow),
            label: "Animales",
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(int pagActual) {
    switch (pagActual) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Becerros';
      case 2:
        return 'Animales';
      case 3:
        return 'Propietarios';
      case 4:
        return 'Corrales';
      default:
        return 'SDLG';
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cerrar sesión'),
          content: Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

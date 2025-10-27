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
      home: Inicio(),
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  // Datos para cada página
  List<Map<String, dynamic>> _animalesData = [];
  List<Map<String, dynamic>> _becerrosData = [];
  List<Map<String, dynamic>> _propietariosData = [];
  List<Map<String, dynamic>> _corralesData = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    // ***********SOLO EJECUTAR ESTO UNA VEZ - LUEGO COMENTAR********** es para reiniciar la base de datos cada vez q hayan cambios
    //o se vaya a iniciar la app por primera vez
    print("=== INICIALIZANDO BASE DE DATOS ===");

    await SQLHelper.debugDatabaseLocation();
    //await SQLHelper.resetDatabase(); // ****************COMENTAR ESTA LÍNEA DESPUÉS DE LA PRIMERA EJECUCIÓN*********************************
    print("=== BASE DE DATOS REINICIADA ===");

    // este es para verificar el estado de la base de datos
    await SQLHelper.debugDatabaseStatus();

    // este es para cargar datos de la página actual
    _cargarDatosPagina(_pagActual);
  }

  // Métodos para cargar datos específicos
  void _refreshAnimales() async {
    final data = await SQLHelper.getAllAnimales();
    setState(() {
      _animalesData = data;
      _isLoading = false;
    });
  }

  void _refreshBecerros() async {
    final data = await SQLHelper.getAllBecerros();
    setState(() {
      _becerrosData = data;
      _isLoading = false;
    });
  }

  void _refreshPropietarios() async {
    final data = await SQLHelper.getAllPropietarios();
    setState(() {
      _propietariosData = data;
      _isLoading = false;
    });
  }

  void _refreshCorrales() async {
    final data = await SQLHelper.getAllCorrales();
    setState(() {
      _corralesData = data;
      _isLoading = false;
    });
  }

  // Cargar datos cuando cambia la página
  void _cargarDatosPagina(int pagina) {
    switch (pagina) {
      case 1: // Becerros
        _refreshBecerros();
        break;
      case 2: // Animales
        _refreshAnimales();
        break;
      case 3: // Propietarios
        _refreshPropietarios();
        break;
      case 4: // Corrales
        _refreshCorrales();
        break;
      default:
        setState(() {
          _isLoading = false;
        });
        break;
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
    setState(() {
      _pagActual = nuevaPagina;
      if (nuevaPagina < 3) {
        _bottomNavIndex = nuevaPagina;
      } else {}
    });
    _cargarDatosPagina(nuevaPagina);
    Navigator.pop(context);
  }

  //función para cambiar de página desde el bottom navigation bar
  void _cambiarPaginaDesdeBottomNav(int index) {
    setState(() {
      _pagActual = index;
      _bottomNavIndex = index;
    });
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
              height: 70,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 27, 26, 34),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
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
}

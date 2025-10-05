import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

//Importación de las páginas del bottom navigation bar
import 'package:sdlgapp/pages/PagAnimales.dart';
import 'package:sdlgapp/pages/PagBecerros.dart';
import 'package:sdlgapp/pages/PagCorrales.dart';
import 'package:sdlgapp/pages/PagInicio.dart';
import 'package:sdlgapp/pages/PagPropietarios.dart';
import 'package:sdlgapp/pages/db_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
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
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;

  //obtener los datos de la base de datos
  void _refreshData() async {
    final data = await SQLHelper.getAllData();
    setState(() {
      _allData = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshData(); // Carga los datos cuando la aplicación inicia
  }

  //agregar datos
  Future<void> _addData() async {
    await SQLHelper.createData(
      _titleController.text,
      _descriptionController.text,
    );
    _refreshData();
  }

  //editar datos
  Future<void> _updateData(int id) async {
    await SQLHelper.updateData(
      id,
      _titleController.text,
      _descriptionController.text,
    );
    _refreshData();
  }

  //borrar datos
  void _deleteData(int id) async {
    await SQLHelper.deleteData(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color.fromARGB(255, 237, 218, 183),
        content: Text('Se eliminó el registro'),
      ),
    );
    _refreshData();
  }

  //controladores para los text fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  //lógica del drawer y del bottom navigation bar
  int _pagActual = 0;
  int _bottomNavIndex = 0; // Índice separado para el BottomNavigationBar

  List<Widget> _paginas = [
    PagInicio(),
    PagBecerros(),
    PagAnimales(),
    PagPropietarios(),
    PagCorrales(),
  ];

  //Función para cambiar de página desde el drawer
  void _cambiarPaginaDesdeDrawer(int nuevaPagina) {
    setState(() {
      _pagActual = nuevaPagina;
      // Solo actualiza el bottom nav index si la página está en el bottom nav
      if (nuevaPagina < 3) {
        _bottomNavIndex = nuevaPagina;
      }
    });
    Navigator.pop(context);
  }

  //función para cambiar de página desde el bottom navigation bar
  void _cambiarPaginaDesdeBottomNav(int index) {
    setState(() {
      _pagActual = index;
      _bottomNavIndex = index;
    });
  }

  //estructura del scaffold (toda la app xd)
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
              onTap: () => SystemNavigator.pop(),
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
        selectedItemColor: const Color.fromARGB(255, 60, 51, 223),
        unselectedItemColor: Colors.grey,
        onTap: _cambiarPaginaDesdeBottomNav,
        currentIndex: _bottomNavIndex, // Usa el índice separado
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

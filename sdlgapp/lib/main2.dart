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

void main() => runApp(SDLGAPP());

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
  int _pagActual = 0;
  int _bottomNavIndex = 0; // Índice separado para el BottomNavigationBar

  List<Widget> _paginas = [
    PagInicio(),
    PagBecerros(),
    PagAnimales(),
    PagPropietarios(),
    PagCorrales(),
  ];

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

  void _cambiarPaginaDesdeBottomNav(int index) {
    setState(() {
      _pagActual = index;
      _bottomNavIndex = index;
    });
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
              onTap: () => SystemNavigator.pop(),
            ),
          ],
        ),
      ),

      appBar: AppBar(title: const Text("SDLG")),

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
}

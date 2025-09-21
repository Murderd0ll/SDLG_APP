import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

//Importación de las páginas del bottom navigation bar
import 'package:sdlgapp/pages/PagAnimales.dart';
import 'package:sdlgapp/pages/PagBecerros.dart';
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

  List<Widget> _paginas = [
    PagInicio(),
    PagBecerros(),
    Paganimales(),
    Pagpropietarios(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: const Color.fromARGB(255, 9, 12, 14),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(top: 20, bottom: 20),
                child: Image.network(
                  "https://img.freepik.com/vector-gratis/vector-diseno-degradado-colorido-pajaro_343694-2506.jpg?semt=ais_incoming&w=740&q=80",
                ),
              ),
              Text(
                "SDLG",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(20),
                color: const Color.fromARGB(255, 41, 66, 87),
                width: double.infinity,
                child: const Text(
                  "Inicio",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(20),
                color: const Color.fromARGB(255, 41, 66, 87),
                width: double.infinity,
                child: const Text(
                  "Becerros",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(20),
                color: const Color.fromARGB(255, 41, 66, 87),
                width: double.infinity,
                child: const Text(
                  "Animales",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(20),
                color: const Color.fromARGB(255, 41, 66, 87),
                width: double.infinity,
                child: const Text(
                  "Corrales",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(20),
                color: const Color.fromARGB(255, 41, 66, 87),
                width: double.infinity,
                child: const Text(
                  "Propietarios",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Expanded(child: Container()),
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color.fromARGB(255, 13, 14, 15),
                width: double.infinity,
                alignment: Alignment.center,
                child: const Text(
                  "Cerrar sesión",
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(title: const Text("SDLG")),

      body:
          _paginas[_pagActual], //se llama la pagina segun a cual se le haga tap

      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          //Al hacer tap, se cambiará el color del index seleccionado
          setState(() {
            _pagActual = index;
          });
        },
        currentIndex: _pagActual,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(
            icon: Icon(
              Symbols.pediatrics,
              weight: 700,
            ), // el weight va desde 100 a 700 (delgado a ancho) en grosor del icono
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

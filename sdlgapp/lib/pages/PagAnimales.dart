import 'package:flutter/material.dart';

class Paganimales extends StatelessWidget {
  //clase para la página de animales
  const Paganimales({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Animales", style: TextStyle(fontSize: 30)),
    ); //Este solo es el texto pero despuésse debe agregar una tabla que muestre los datos de los animales
    // un cuadro de busqueda y un botón para agregar nuevos
  }
}

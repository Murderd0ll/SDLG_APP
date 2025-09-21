import 'package:flutter/material.dart';

class Pagpropietarios extends StatelessWidget {
  //clase para la página de propietarios
  const Pagpropietarios({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Propietarios", style: TextStyle(fontSize: 30)),
    ); //Este solo es el texto pero después se debe agregar una tabla que muestre los datos de los propietarios
    // un cuadro de busqueda y un botón para agregar nuevos
  }
}

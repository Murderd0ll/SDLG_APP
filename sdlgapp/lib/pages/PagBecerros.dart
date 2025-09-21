import 'package:flutter/material.dart';

class PagBecerros extends StatelessWidget {
  //clase para la página de becerros
  const PagBecerros({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Becerros", style: TextStyle(fontSize: 30)),
    ); //Este solo es el texto pero despuésse debe agregar una tabla que muestre los datos de los becerros
    // un cuadro de busqueda y un botón para agregar nuevos
  }
}

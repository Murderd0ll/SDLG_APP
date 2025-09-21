import 'package:flutter/material.dart';

class PagInicio extends StatelessWidget {
  //clase para la página de inicio
  const PagInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Inicio", style: TextStyle(fontSize: 30)),
    ); //Este solo es el texto pero después se debe agregar un panel de cantidad de animales
    // y un panel de acciones rapidas q redirijan a las opcione sde agregar de otras paginas (becerros y animales)
  }
}

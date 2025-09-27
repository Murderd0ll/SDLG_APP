import 'package:flutter/material.dart';

class PagAnimales extends StatelessWidget {
  //clase para la página de animales
  const PagAnimales({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(
            width: 1,
            color: const Color.fromARGB(255, 56, 56, 56),
          ),
        ),
        children: [
          TableRow(
            children: [Text(' Sexo'), Text(' Arete'), Text(' F. Nacimiento')],
          ),
          TableRow(
            children: [
              Text('Row 1, Col 1'),
              Text('Row 1, Col 2'),
              Text('Row 1, Col 3'),
            ],
          ),
          TableRow(
            children: [
              Text('Row 2, Col 1'),
              Text('Row 2, Col 2'),
              Text('Row 2, Col 3'),
            ],
          ),
        ],
      ),
    );
    // falta un cuadro de busqueda y un botón para agregar nuevos
  }
}

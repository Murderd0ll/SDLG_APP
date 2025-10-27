import 'package:flutter/material.dart';
import 'package:sdlgapp/pages/db_helper.dart';

class PagInicio extends StatelessWidget {
  //clase para la página de inicio
  const PagInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Inicio", style: TextStyle(fontSize: 30))),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              SQLHelper.exportRealDatabase();
            },
            tooltip: 'Exportar BD Real',
            child: Icon(Icons.verified_user),
          ),
        ],
      ),
    ); //Este solo es el texto pero después se debe agregar un panel de cantidad de animales
    // y un panel de acciones rapidas q redirijan a las opcione sde agregar de otras paginas (becerros y animales)
  }
}

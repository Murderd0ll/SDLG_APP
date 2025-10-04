import 'package:flutter/material.dart';

class PagInicio extends StatelessWidget {
  //clase para la página de inicio
  const PagInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 132, 177, 214),
        elevation: 0,
        actions: <Widget>[
          SearchAnchor.bar(
            suggestionsBuilder:
                (BuildContext context, SearchController controller) {
                  final String input = controller.value.text;
                  return [
                    ListTile(
                      title: Text("Sugerencia 1"),
                      onTap: () {
                        controller.value = TextEditingValue(
                          text: "Sugerencia 1",
                        );
                      },
                    ),
                    ListTile(
                      title: Text("Sugerencia 2"),
                      onTap: () {
                        controller.value = TextEditingValue(
                          text: "Sugerencia 2",
                        );
                      },
                    ),
                  ];
                },
          ),
        ],
      ),
      body: Center(child: Text("Inicio", style: TextStyle(fontSize: 30))),
    ); //Este solo es el texto pero después se debe agregar un panel de cantidad de animales
    // y un panel de acciones rapidas q redirijan a las opcione sde agregar de otras paginas (becerros y animales)
  }
}

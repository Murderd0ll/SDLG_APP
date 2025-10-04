import 'package:flutter/material.dart';

class PagAnimales extends StatelessWidget {
  //clase para la página de animales
  const PagAnimales({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 60,
        title: Row(
          children: [
            SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 40,

                child: SearchAnchor.bar(
                  barHintText: 'Buscar Animal', //este es el placeholder
                  barElevation: WidgetStateProperty.all(
                    0,
                  ), //este es para quitar la sombra del cuadro de busqueda
                  barSide: WidgetStateProperty.all(
                    BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ), //aca se le cambia el color del borde al cuadro de busqueda
                  ),
                  suggestionsBuilder:
                      (BuildContext context, SearchController controller) {
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
              ),
            ),
            SizedBox(width: 8), // Small spacing between search and button
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 137, 77, 77).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  // TODO: Add functionality to add new data
                },
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 182, 128, 128),
                ),
                tooltip: 'Agregar Animal',
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SizedBox(child: Container(child: Text("Página de Animalessss"))),
      ),
    );
  }
}

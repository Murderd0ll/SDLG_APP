import 'package:flutter/material.dart';
import 'package:sdlgapp/pages/db_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class PagInicio extends StatefulWidget {
  const PagInicio({super.key});

  @override
  State<PagInicio> createState() => _PagInicioState();
}

class _PagInicioState extends State<PagInicio> {
  // Variables para almacenar las estadísticas
  int _totalAnimales = 0;
  int _totalBecerros = 0;
  int _totalMachos = 0;
  int _totalHembras = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  // Método para cargar todas las estadísticas
  Future<void> _cargarEstadisticas() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Obtener totales
      final totalAnimales = await SQLHelper.getTotalAnimales();
      final totalBecerros = await SQLHelper.getTotalBecerros();

      // Obtener distribución por sexo
      final animalesPorSexo = await SQLHelper.getAnimalesPorSexo();

      int machos = 0;
      int hembras = 0;

      for (var item in animalesPorSexo) {
        if (item['sexogdo']?.toString().toLowerCase() == 'macho') {
          machos = item['cantidad'] as int;
        } else if (item['sexogdo']?.toString().toLowerCase() == 'hembra') {
          hembras = item['cantidad'] as int;
        }
      }

      setState(() {
        _totalAnimales = totalAnimales;
        _totalBecerros = totalBecerros;
        _totalMachos = machos;
        _totalHembras = hembras;
        _isLoading = false;
      });
    } catch (e) {
      print("Error cargando estadísticas: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Widget para mostrar una tarjeta de estadística
  Widget _buildStatCard(String titulo, int valor, IconData icono, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              valor.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar acciones rápidas
  Widget _buildAccionRapida(
    String titulo,
    IconData icono,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 30, color: color),
              const SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de arriba
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      "Software De Los Ganaderos\npara la Ganadería el Colibrí",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Estadísticas principales
                  const Text(
                    "Estadísticas del Ganado",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 137, 77, 77),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // "Grid" de estadísticas
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    children: [
                      _buildStatCard(
                        "Total de Ganado",
                        _totalAnimales,
                        FontAwesomeIcons.cow,
                        Colors.brown,
                      ),
                      _buildStatCard(
                        "Total Becerros",
                        _totalBecerros,
                        Symbols.pediatrics,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        "Machos",
                        _totalMachos,
                        Icons.male,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        "Hembras",
                        _totalHembras,
                        Icons.female,
                        Colors.pink,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Resumen en texto
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Resumen General",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 137, 77, 77),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildResumenItem(
                            "Total de ganado:",
                            _totalAnimales + _totalBecerros,
                          ),
                          _buildResumenItem(
                            "Animales adultos:",
                            _totalAnimales,
                          ),
                          _buildResumenItem("Becerros:", _totalBecerros),
                          _buildResumenItem("Machos adultos:", _totalMachos),
                          _buildResumenItem("Hembras adultas:", _totalHembras),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              SQLHelper.exportRealDatabase();
            },
            tooltip: 'Exportar BD Real',
            child: const Icon(Icons.verified_user),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _cargarEstadisticas,
            tooltip: 'Actualizar',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String texto, int valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(texto, style: const TextStyle(fontSize: 14)),
          Text(
            valor.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}

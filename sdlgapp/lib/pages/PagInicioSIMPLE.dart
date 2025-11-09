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
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    print("=== PAGINICIO INITSTATE ===");
    _cargarEstadisticas();
  }

  // Método para cargar todas las estadísticas - OPTIMIZADO
  Future<void> _cargarEstadisticas() async {
    try {
      if (!_isRefreshing) {
        setState(() {
          _isLoading = true;
        });
      }

      print("Cargando estadísticas...");

      // Usar Future.wait para cargar datos en paralelo
      final results = await Future.wait([
        SQLHelper.getTotalAnimales(),
        SQLHelper.getTotalBecerros(),
        SQLHelper.getAnimalesPorSexo(),
      ], eagerError: true);

      final totalAnimales = results[0] as int;
      final totalBecerros = results[1] as int;
      final animalesPorSexo = results[2] as List<Map<String, dynamic>>;

      int machos = 0;
      int hembras = 0;

      for (var item in animalesPorSexo) {
        final sexo = item['sexogdo']?.toString().toLowerCase() ?? '';
        final cantidad = item['cantidad'] as int? ?? 0;

        if (sexo == 'macho') {
          machos = cantidad;
        } else if (sexo == 'hembra') {
          hembras = cantidad;
        }
      }

      print(
        "Estadísticas cargadas: $totalAnimales animales, $totalBecerros becerros",
      );

      if (mounted) {
        setState(() {
          _totalAnimales = totalAnimales;
          _totalBecerros = totalBecerros;
          _totalMachos = machos;
          _totalHembras = hembras;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print("❌ Error cargando estadísticas: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // Método para refrescar datos
  Future<void> _refrescarDatos() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });
    await _cargarEstadisticas();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 80,
              color: const Color.fromARGB(255, 137, 77, 77),
            ),
            const SizedBox(height: 20),
            Text(
              'SDLG APP',
              style: TextStyle(
                color: const Color.fromARGB(255, 137, 77, 77),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Página de Inicio',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cargarEstadisticas,
              child: const Text('Cargar Estadísticas'),
            ),
          ],
        ),
      ),
    );
  }
}

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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    print("=== PAGINICIO INIT ===");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEstadisticasUltraSegura();
    });
  }

  // Método seguro para cargar estadísticas
  Future<void> _cargarEstadisticasUltraSegura() async {
    try {
      print("=== CARGA ULTRA SEGURA INICIADA ===");

      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Solo cargar datos básicos primero
      print("Cargando datos básicos...");
      final animales = await SQLHelper.getTotalAnimales().catchError((e) {
        print("Error en getTotalAnimales: $e");
        return 0;
      });

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));

      final becerros = await SQLHelper.getTotalBecerros().catchError((e) {
        print("Error en getTotalBecerros: $e");
        return 0;
      });

      if (!mounted) return;

      // Actualizar UI con datos básicos primero
      setState(() {
        _totalAnimales = animales;
        _totalBecerros = becerros;
      });

      // Luego cargar datos adicionales en segundo plano
      _cargarDatosAdicionalesEnBackground();
    } catch (e) {
      print("❌ Error crítico: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // Cargar datos adicionales sin bloquear la UI
  void _cargarDatosAdicionalesEnBackground() async {
    try {
      print("Cargando datos adicionales en background...");

      final porSexo = await SQLHelper.getAnimalesPorSexo().catchError((e) {
        print("Error en getAnimalesPorSexo: $e");
        return [];
      });

      if (!mounted) return;

      int machos = 0;
      int hembras = 0;

      for (var item in porSexo) {
        final sexo = item['sexogdo']?.toString().toLowerCase() ?? '';
        final cantidad = item['cantidad'] as int? ?? 0;

        if (sexo.contains('macho')) machos = cantidad;
        if (sexo.contains('hembra')) hembras = cantidad;
      }

      if (mounted) {
        setState(() {
          _totalMachos = machos;
          _totalHembras = hembras;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error en carga background: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Widget para mostrar una tarjeta de estadística
  Widget _buildStatCard(String titulo, int valor, IconData icono, Color color) {
    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 27, 26, 34),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              valor.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 9, 12, 14),
      body: _isLoading
          ? _buildLoadingScreen()
          : _hasError
          ? _buildErrorScreen()
          : _buildMainContent(),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 182, 128, 128),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Cargando estadísticas...",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            "Esto puede tomar unos segundos",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 20),
          Text(
            "Error al cargar datos",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "No se pudieron cargar las estadísticas. Verifica la conexión con la base de datos.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _cargarEstadisticasUltraSegura,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 182, 128, 128),
            ),
            child: const Text(
              "Reintentar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Grid de estadísticas
          _buildStatsGrid(),
          const SizedBox(height: 24),

          // Resumen
          _buildResumenCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Software De Los Ganaderos",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          "Ganadería el Colibrí",
          style: TextStyle(
            fontSize: 18,
            color: const Color.fromARGB(255, 182, 128, 128),
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.grey[700]),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Resumen del Inventario",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 182, 128, 128),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildStatCard(
              "Animales\nAdultos",
              _totalAnimales,
              FontAwesomeIcons.cow,
              Color.fromARGB(255, 182, 128, 128),
            ),
            _buildStatCard(
              "Becerros",
              _totalBecerros,
              Symbols.pediatrics,
              Colors.orange,
            ),
            _buildStatCard("Machos", _totalMachos, Icons.male, Colors.blue),
            _buildStatCard("Hembras", _totalHembras, Icons.female, Colors.pink),
          ],
        ),
      ],
    );
  }

  Widget _buildResumenCard() {
    return Card(
      elevation: 2,
      color: const Color.fromARGB(255, 27, 26, 34),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: Color.fromARGB(255, 182, 128, 128),
                ),
                const SizedBox(width: 8),
                Text(
                  "Resumen General",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 182, 128, 128),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildResumenItem(
              "Total de cabezas:",
              _totalAnimales + _totalBecerros,
            ),
            _buildResumenItem("Animales adultos:", _totalAnimales),
            _buildResumenItem("Becerros:", _totalBecerros),
            _buildResumenItem("Machos adultos:", _totalMachos),
            _buildResumenItem("Hembras adultas:", _totalHembras),
            _buildResumenItem(
              "Relación M:H:",
              _totalHembras > 0
                  ? (_totalMachos / _totalHembras).toStringAsFixed(1)
                  : "0.0",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenItem(String texto, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
          Text(
            valor.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 182, 128, 128),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () => _exportarBaseDatos(),
          tooltip: 'Exportar BD',
          backgroundColor: const Color.fromARGB(255, 182, 128, 128),
          mini: true,
          child: const Icon(Icons.save_alt, size: 20),
        ),
        const SizedBox(width: 10),
        FloatingActionButton(
          onPressed: _cargarEstadisticasUltraSegura,
          tooltip: 'Actualizar',
          backgroundColor: const Color.fromARGB(255, 182, 128, 128),
          mini: true,
          child: const Icon(Icons.refresh, size: 20),
        ),
      ],
    );
  }

  Future<void> _exportarBaseDatos() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Exportando base de datos...'),
          backgroundColor: const Color.fromARGB(255, 182, 128, 128),
        ),
      );

      await SQLHelper.exportRealDatabase();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Base de datos exportada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    print("=== PAGINICIO DISPOSE ===");
    super.dispose();
  }
}

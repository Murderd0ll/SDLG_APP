// /lib/pages/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:sdlgapp/pages/db_helper.dart';
import 'package:sdlgapp/pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print("=== INICIALIZANDO BASE DE DATOS DESDE SPLASH ===");

      await SQLHelper.debugDatabaseLocation();

      // ***********SOLO EJECUTAR ESTO UNA VEZ - LUEGO COMENTAR**********
      //await SQLHelper.resetDatabase();
      // ****************COMENTAR ESTA LÍNEA DESPUÉS DE LA PRIMERA EJECUCIÓN*********************************

      print("=== BASE DE DATOS REINICIADA ===");

      // Insertar usuarios por defecto
      await SQLHelper.insertDefaultUsers();

      await Future.delayed(Duration(milliseconds: 500));

      // Verificar el estado de la base de datos
      await SQLHelper.debugDatabaseStatus();

      print("=== INICIALIZACIÓN COMPLETADA ===");

      // Navegar al login después de la inicialización
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print("❌ Error en inicialización: $e");
      // Aún así navegar al login, pero mostrar error si es necesario
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 26, 34),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'SDLG APP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromARGB(255, 182, 128, 128),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Inicializando aplicación...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

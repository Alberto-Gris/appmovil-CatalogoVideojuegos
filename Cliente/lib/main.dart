import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/providers/game_providers.dart';
import 'package:videogame_catalog/screens/game_store_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Asegurar que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Cargar las variables de entorno desde el archivo .env
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Manejar error si el archivo .env no existe o tiene problemas
    debugPrint('❌ Error cargando .env: $e');
    debugPrint(
      'Asegúrate de que el archivo .env existe en la raíz del proyecto',
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => GameProviders(),
      child: MaterialApp(
        title: 'Tienda de videojuegos',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            color: Colors.blue,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        home: const GameStoreScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
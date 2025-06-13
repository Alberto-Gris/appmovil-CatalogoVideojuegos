import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/providers/game_providers.dart';
import 'package:videogame_catalog/screens/game_store_screen.dart';

void main() {
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
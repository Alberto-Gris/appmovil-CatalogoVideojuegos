import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/models/game_model.dart';
import 'package:videogame_catalog/providers/game_providers.dart';

class AddGameScreen extends StatefulWidget {
  const AddGameScreen({Key? key}) : super(key: key);

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _developerController = TextEditingController();
  final TextEditingController _imageLinkController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _platformsController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _developerController.dispose();
    _imageLinkController.dispose();
    _descriptionController.dispose();
    _platformsController.dispose();
    _releaseDateController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _saveGame() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Crear un ID único basado en la hora actual
      final id = DateTime.now().millisecondsSinceEpoch;
      
      // Convertir el texto de plataformas a una lista (separadas por comas)
      final platforms = _platformsController.text.split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      // Crear un nuevo modelo de juego
      final game = GameModel(
        id: id,
        name: _nameController.text,
        developer: _developerController.text,
        imageLink: _imageLinkController.text,
        description: _descriptionController.text,
        platforms: platforms,
        releaseDate: _releaseDateController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        quantity: 0,
      );
      
      // Guardarlo usando el provider
      final success = await Provider.of<GameProviders>(context, listen: false).saveGame(game);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Juego guardado correctamente')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el juego')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar nuevo juego'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del juego',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre del juego';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _developerController,
                      decoration: const InputDecoration(
                        labelText: 'Desarrollador',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el desarrollador';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageLinkController,
                      decoration: const InputDecoration(
                        labelText: 'URL de la imagen',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la URL de la imagen';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _platformsController,
                      decoration: const InputDecoration(
                        labelText: 'Plataformas (separadas por comas)',
                        border: OutlineInputBorder(),
                        hintText: 'PS5, Xbox, PC',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa al menos una plataforma';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _releaseDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de lanzamiento',
                        border: OutlineInputBorder(),
                        hintText: 'YYYY-MM-DD',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la fecha de lanzamiento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el precio';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor ingresa un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveGame,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'GUARDAR JUEGO',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
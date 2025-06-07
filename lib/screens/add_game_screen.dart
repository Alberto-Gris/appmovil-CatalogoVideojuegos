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
  final TextEditingController _stockController = TextEditingController();
  
  // Para manejo de media carousel
  final List<MediaCarouselItem> _mediaItems = [];
  final TextEditingController _mediaUrlController = TextEditingController();
  final TextEditingController _mediaAltController = TextEditingController();
  String _selectedMediaType = 'image';
  
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
    _stockController.dispose();
    _mediaUrlController.dispose();
    _mediaAltController.dispose();
    super.dispose();
  }

  void _addMediaItem() {
    if (_mediaUrlController.text.isNotEmpty && _mediaAltController.text.isNotEmpty) {
      setState(() {
        _mediaItems.add(MediaCarouselItem(
          type: _selectedMediaType,
          url: _mediaUrlController.text,
          alt: _mediaAltController.text,
        ));
        _mediaUrlController.clear();
        _mediaAltController.clear();
      });
    }
  }

  void _removeMediaItem(int index) {
    setState(() {
      _mediaItems.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      _releaseDateController.text = picked.toIso8601String().split('T')[0];
    }
  }

  void _saveGame() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Generar ID único
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Procesar plataformas
      final platforms = _platformsController.text.split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      // Si no se agregaron media items, crear uno con la imagen principal
      List<MediaCarouselItem> mediaCarousel = List.from(_mediaItems);
      if (mediaCarousel.isEmpty && _imageLinkController.text.isNotEmpty) {
        mediaCarousel.add(MediaCarouselItem(
          type: 'image',
          url: _imageLinkController.text,
          alt: 'Portada del juego',
        ));
      }
      
      // Crear el modelo de juego
      final game = GameModel(
        id: id,
        name: _nameController.text.trim(),
        developer: _developerController.text.trim(),
        imageLink: _imageLinkController.text.trim(),
        description: _descriptionController.text.trim(),
        platforms: platforms,
        releaseDate: _releaseDateController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        unitsInStock: int.tryParse(_stockController.text) ?? 0,
        quantity: 0,
        mediaCarousel: mediaCarousel,
      );
      
      // Guardar usando el provider
      final gameProvider = Provider.of<GameProviders>(context, listen: false);
      final success = await gameProvider.saveGame(game);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Juego guardado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      } else if (mounted) {
        final errorMessage = gameProvider.errorMessage ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Agregar Nuevo Juego'),
        elevation: 0,
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
                    // Información básica
                    _buildSectionTitle('Información Básica'),
                    _buildTextFormField(
                      controller: _nameController,
                      label: 'Nombre del juego',
                      validator: (value) => value?.isEmpty == true 
                          ? 'Ingresa el nombre del juego' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _developerController,
                      label: 'Desarrollador',
                      validator: (value) => value?.isEmpty == true 
                          ? 'Ingresa el desarrollador' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _descriptionController,
                      label: 'Descripción',
                      maxLines: 3,
                      validator: (value) => value?.isEmpty == true 
                          ? 'Ingresa una descripción' : null,
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle('Detalles del Producto'),
                    _buildTextFormField(
                      controller: _platformsController,
                      label: 'Plataformas (separadas por comas)',
                      hintText: 'Nintendo Switch, PS5, Xbox Series X',
                      validator: (value) => value?.isEmpty == true 
                          ? 'Ingresa al menos una plataforma' : null,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: _buildTextFormField(
                          controller: _releaseDateController,
                          label: 'Fecha de lanzamiento',
                          hintText: 'Toca para seleccionar fecha',
                          suffixIcon: const Icon(Icons.calendar_today),
                          validator: (value) => value?.isEmpty == true 
                              ? 'Selecciona la fecha de lanzamiento' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _priceController,
                            label: 'Precio (\$)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Ingresa el precio';
                              if (double.tryParse(value!) == null) return 'Precio inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _stockController,
                            label: 'Stock disponible',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Ingresa el stock';
                              if (int.tryParse(value!) == null) return 'Stock inválido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle('Imagen Principal'),
                    _buildTextFormField(
                      controller: _imageLinkController,
                      label: 'URL de la imagen principal',
                      validator: (value) => value?.isEmpty == true 
                          ? 'Ingresa la URL de la imagen' : null,
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionTitle('Galería de Medios (Opcional)'),
                    _buildMediaSection(),
                    
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveGame,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'GUARDAR JUEGO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formulario para agregar media
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedMediaType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de media',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'image', child: Text('Imagen')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMediaType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mediaUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL del archivo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mediaAltController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción alternativa',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addMediaItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Media'),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Lista de media items agregados
        if (_mediaItems.isNotEmpty) ...[
          const Text(
            'Archivos agregados:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(_mediaItems.length, (index) {
            final item = _mediaItems[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  item.type == 'image' ? Icons.image : Icons.videocam,
                  color: item.type == 'image' ? Colors.blue : Colors.red,
                ),
                title: Text(item.alt),
                subtitle: Text(
                  item.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeMediaItem(index),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/models/game_model.dart';
import 'package:videogame_catalog/providers/game_providers.dart';
import 'package:videogame_catalog/services/cloudinary_services.dart';

class AddGameScreen extends StatefulWidget {
  final GameModel? gameToEdit;

  const AddGameScreen({Key? key, this.gameToEdit}) : super(key: key);

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
  final TextEditingController _mediaAltController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingMedia = false;
  bool get _isEditMode => widget.gameToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadGameData();
    }
  }

  void _loadGameData() {
    final game = widget.gameToEdit!;
    _nameController.text = game.name;
    _developerController.text = game.developer;
    _imageLinkController.text = game.imageLink;
    _descriptionController.text = game.description;
    _platformsController.text = game.platforms.join(', ');
    _releaseDateController.text = game.releaseDate;
    _priceController.text = game.price.toString();
    _stockController.text = (game.unitsInStock ?? 0).toString();
    _mediaItems.addAll(game.mediaCarousel);
  }

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
    _mediaAltController.dispose();
    super.dispose();
  }

  Future<void> _uploadMainImage() async {
    setState(() {
      _isUploadingMedia = true;
    });

    try {
      final url = await _showImagePickerDialog();
      if (url != null) {
        _imageLinkController.text = url;
        _showSuccessSnackBar('Imagen principal subida correctamente');
      }
    } catch (e) {
      _showErrorSnackBar('Error al subir imagen: $e');
    } finally {
      setState(() {
        _isUploadingMedia = false;
      });
    }
  }

  Future<String?> _showImagePickerDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seleccionar imagen'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPickerOption(
                icon: Icons.photo_library,
                title: 'Galería',
                subtitle: 'Seleccionar desde galería',
                onTap: () async {
                  try {
                    final url = await CloudinaryService.uploadImage(
                      fromCamera: false,
                    );

                    // Verificar que el widget principal sigue montado antes de cerrar
                    if (mounted) {
                      // Cerrar el diálogo y retornar la URL
                      Navigator.of(dialogContext).pop(url);
                    }
                  } catch (e) {
                    // En caso de error, cerrar y retornar null
                    if (mounted) {
                      Navigator.of(dialogContext).pop(null);
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildPickerOption(
                icon: Icons.photo_camera,
                title: 'Cámara',
                subtitle: 'Tomar nueva foto',
                onTap: () async {
                  try {
                    final url = await CloudinaryService.uploadImage(
                      fromCamera: true,
                    );

                    // Verificar que el widget principal sigue montado antes de cerrar
                    if (mounted) {
                      // Cerrar el diálogo y retornar la URL
                      Navigator.of(dialogContext).pop(url);
                    }
                  } catch (e) {
                    // En caso de error, cerrar y retornar null
                    if (mounted) {
                      Navigator.of(dialogContext).pop(null);
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMediaToCarousel() async {
    if (_mediaAltController.text.trim().isEmpty) {
      _showErrorSnackBar('Por favor, ingresa una descripción para el archivo');
      return;
    }

    setState(() {
      _isUploadingMedia = true;
    });

    try {
      final result = await _showMediaTypeDialog();
      if (result != null) {
        final mediaItem = MediaCarouselItem(
          type: result['type']!,
          url: result['url']!,
          thumbnail: result['thumbnail'],
          alt: _mediaAltController.text.trim(),
        );

        setState(() {
          _mediaItems.add(mediaItem);
          _mediaAltController.clear();
        });

        _showSuccessSnackBar(
          '${result['type'] == 'image' ? 'Imagen' : 'Video'} agregado correctamente',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error al subir archivo: $e');
    } finally {
      setState(() {
        _isUploadingMedia = false;
      });
    }
  }

  Future<Map<String, String>?> _showMediaTypeDialog() async {
    final Completer<Map<String, String>?> completer =
        Completer<Map<String, String>?>();

    showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seleccionar tipo de archivo'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMediaTypeOption(
                icon: Icons.image,
                iconColor: Colors.blue,
                title: 'Imagen',
                subtitle: 'Subir imagen desde galería o cámara',
                onTap: () async {
                  // Cerrar el diálogo inmediatamente
                  Navigator.of(dialogContext).pop();

                  try {
                    final url = await _showImagePickerDialog();
                    if (url != null && !completer.isCompleted) {
                      completer.complete({'type': 'image', 'url': url});
                    } else if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                  } catch (e) {
                    print('Error al seleccionar imagen: $e');
                    if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildMediaTypeOption(
                icon: Icons.video_library,
                iconColor: Colors.red,
                title: 'Video',
                subtitle: 'Subir video desde galería',
                onTap: () async {
                  // Cerrar el diálogo inmediatamente
                  Navigator.of(dialogContext).pop();

                  try {
                    final url = await CloudinaryService.uploadVideo();
                    if (url != null && !completer.isCompleted) {
                      final thumbnail = CloudinaryService.getVideoThumbnail(
                        url,
                      );
                      completer.complete({
                        'type': 'video',
                        'url': url,
                        'thumbnail': thumbnail,
                      });
                    } else if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                  } catch (e) {
                    print('Error al subir video: $e');
                    if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (!completer.isCompleted) {
                  completer.complete(null);
                }
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    return completer.future;
  }

  Widget _buildMediaTypeOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeMediaItem(int index) {
    setState(() {
      _mediaItems.removeAt(index);
    });
    _showSuccessSnackBar('Archivo eliminado');
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _releaseDateController.text.isNotEmpty
              ? DateTime.tryParse(_releaseDateController.text) ?? DateTime.now()
              : DateTime.now(),
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
      final gameProvider = Provider.of<GameProviders>(context, listen: false);

      // Procesar plataformas
      final platforms =
          _platformsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      // Si no se agregaron media items, crear uno con la imagen principal
      List<MediaCarouselItem> mediaCarousel = List.from(_mediaItems);
      if (mediaCarousel.isEmpty && _imageLinkController.text.isNotEmpty) {
        mediaCarousel.add(
          MediaCarouselItem(
            type: 'image',
            url: _imageLinkController.text,
            alt: 'Portada del juego',
          ),
        );
      }

      // Crear el modelo de juego
      final game = GameModel(
        id:
            _isEditMode
                ? widget.gameToEdit!.id
                : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        developer: _developerController.text.trim(),
        imageLink: _imageLinkController.text.trim(),
        description: _descriptionController.text.trim(),
        platforms: platforms,
        releaseDate: _releaseDateController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        unitsInStock: int.tryParse(_stockController.text) ?? 0,
        quantity: _isEditMode ? widget.gameToEdit!.quantity : 0,
        mediaCarousel: mediaCarousel,
      );

      // Guardar o actualizar usando el provider
      final success =
          _isEditMode
              ? await gameProvider.updateGame(game)
              : await gameProvider.saveGame(game);

      if (success && mounted) {
        _showSuccessSnackBar(
          _isEditMode
              ? 'Juego actualizado correctamente'
              : 'Juego guardado correctamente',
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        final errorMessage = gameProvider.errorMessage ?? 'Error desconocido';
        _showErrorSnackBar('Error: $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error inesperado: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Juego' : 'Agregar Nuevo Juego'),
        elevation: 0,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Guardando juego...'),
                  ],
                ),
              )
              : _buildForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildProductDetailsSection(),
            const SizedBox(height: 24),
            _buildMainImageSection(),
            const SizedBox(height: 24),
            _buildMediaGallerySection(),
            const SizedBox(height: 100), // Espacio para el botón flotante
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Información Básica',
      children: [
        _buildTextFormField(
          controller: _nameController,
          label: 'Nombre del juego',
          icon: Icons.videogame_asset,
          validator:
              (value) =>
                  value?.trim().isEmpty == true
                      ? 'Ingresa el nombre del juego'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _developerController,
          label: 'Desarrollador',
          icon: Icons.business,
          validator:
              (value) =>
                  value?.trim().isEmpty == true
                      ? 'Ingresa el desarrollador'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _descriptionController,
          label: 'Descripción',
          icon: Icons.description,
          maxLines: 4,
          validator:
              (value) =>
                  value?.trim().isEmpty == true
                      ? 'Ingresa una descripción'
                      : null,
        ),
      ],
    );
  }

  Widget _buildProductDetailsSection() {
    return _buildSection(
      title: 'Detalles del Producto',
      children: [
        _buildTextFormField(
          controller: _platformsController,
          label: 'Plataformas',
          icon: Icons.devices,
          hintText: 'Nintendo Switch, PS5, Xbox Series X',
          helperText: 'Separar con comas',
          validator:
              (value) =>
                  value?.trim().isEmpty == true
                      ? 'Ingresa al menos una plataforma'
                      : null,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: _buildTextFormField(
              controller: _releaseDateController,
              label: 'Fecha de lanzamiento',
              icon: Icons.calendar_today,
              hintText: 'Toca para seleccionar fecha',
              validator:
                  (value) =>
                      value?.trim().isEmpty == true
                          ? 'Selecciona la fecha de lanzamiento'
                          : null,
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
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty == true) return 'Ingresa el precio';
                  if (double.tryParse(value!) == null) return 'Precio inválido';
                  if (double.parse(value) < 0)
                    return 'El precio debe ser positivo';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextFormField(
                controller: _stockController,
                label: 'Stock disponible',
                icon: Icons.inventory,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty == true) return 'Ingresa el stock';
                  final stock = int.tryParse(value!);
                  if (stock == null) return 'Stock inválido';
                  if (stock < 0) return 'El stock debe ser positivo';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainImageSection() {
    return _buildSection(
      title: 'Imagen Principal',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextFormField(
                controller: _imageLinkController,
                label: 'URL de la imagen principal',
                icon: Icons.image,
                validator:
                    (value) =>
                        value?.trim().isEmpty == true
                            ? 'Ingresa la URL de la imagen'
                            : null,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isUploadingMedia ? null : _uploadMainImage,
              icon:
                  _isUploadingMedia
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.upload),
              label: const Text('Subir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        if (_imageLinkController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageLinkController.text,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, size: 64, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaGallerySection() {
    return _buildSection(
      title: 'Galería de Medios (Opcional)',
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextFormField(
                  controller: _mediaAltController,
                  label: 'Descripción del archivo',
                  icon: Icons.label,
                  hintText: 'Ej: Captura de pantalla del juego',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingMedia ? null : _addMediaToCarousel,
                    icon:
                        _isUploadingMedia
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.add_a_photo),
                    label: Text(
                      _isUploadingMedia ? 'Subiendo...' : 'Agregar Archivo',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_mediaItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archivos agregados (${_mediaItems.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_mediaItems.length, (index) {
                    final item = _mediaItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            item.type == 'video'
                                ? (item.thumbnail ?? item.url)
                                : item.url,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: Icon(
                                  item.type == 'image'
                                      ? Icons.image
                                      : Icons.videocam,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        title: Text(
                          item.alt,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              item.type == 'image'
                                  ? Icons.image
                                  : Icons.videocam,
                              size: 16,
                              color:
                                  item.type == 'image'
                                      ? Colors.blue
                                      : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.type == 'image' ? 'Imagen' : 'Video',
                              style: TextStyle(
                                color:
                                    item.type == 'image'
                                        ? Colors.blue
                                        : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeMediaItem(index),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hintText,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isUploadingMedia || _isLoading ? null : _saveGame,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _isEditMode ? 'ACTUALIZAR JUEGO' : 'GUARDAR JUEGO',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar juego'),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${widget.gameToEdit!.name}"?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteGame();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGame() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gameProvider = Provider.of<GameProviders>(context, listen: false);
      final success = await gameProvider.deleteGame(widget.gameToEdit!.id);

      if (success && mounted) {
        _showSuccessSnackBar('Juego eliminado correctamente');
        Navigator.of(context).pop(true);
      } else if (mounted) {
        final errorMessage = gameProvider.errorMessage ?? 'Error desconocido';
        _showErrorSnackBar('Error al eliminar: $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error inesperado: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

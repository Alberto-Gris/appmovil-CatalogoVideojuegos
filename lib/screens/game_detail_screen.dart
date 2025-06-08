import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videogame_catalog/models/game_model.dart';
import 'package:videogame_catalog/providers/game_providers.dart';
import 'package:video_player/video_player.dart';

class GameDetailScreen extends StatefulWidget {
  final GameModel game;

  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final PageController _pageController = PageController();
  int _currentMediaIndex = 0;
  final List<MediaItem> _allMediaItems = [];
  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _setupMediaItems();
  }

  void _setupMediaItems() {
    _allMediaItems.clear();

    // Agregar imagen principal primero
    if (widget.game.imageLink.isNotEmpty) {
      _allMediaItems.add(
        MediaItem(
          type: 'image',
          url: widget.game.imageLink,
          alt: 'Imagen principal de ${widget.game.name}',
          isMainImage: true,
        ),
      );
    }

    // Agregar items del mediaCarousel
    for (final item in widget.game.mediaCarousel) {
      _allMediaItems.add(
        MediaItem(
          type: item.type,
          url: item.url,
          alt: item.alt,
          thumbnail: item.thumbnail,
          isMainImage: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose de todos los video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  VideoPlayerController _getVideoController(int index, String videoUrl) {
    if (!_videoControllers.containsKey(index)) {
      _videoControllers[index] = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        )
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
    return _videoControllers[index]!;
  }

  // Función para mostrar imagen en pantalla completa
  void _showFullScreenImage(String imageUrl, String heroTag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (BuildContext context, _, __) {
          return FullScreenImageViewer(imageUrl: imageUrl, heroTag: heroTag);
        },
      ),
    );
  }

  // Función para mostrar video en pantalla completa
  void _showFullScreenVideo(
    String videoUrl,
    String? thumbnailUrl,
    String heroTag,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FullScreenVideoPlayer(
              videoUrl: videoUrl,
              thumbnailUrl: thumbnailUrl,
              heroTag: heroTag,
              gameName: widget.game.name,
            ),
      ),
    );
  }

  // Función para mostrar galería completa en pantalla completa
  void _showFullScreenGallery(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FullScreenGallery(
              mediaItems: _allMediaItems,
              initialIndex: initialIndex,
              gameName: widget.game.name,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProviders>(context);
    final inCart = gameProvider.isInCart(widget.game);
    final quantity = gameProvider.getQuantityInCart(widget.game);
    final isOutOfStock =
        widget.game.unitsInStock != null && widget.game.unitsInStock! <= 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar con carrusel de medios
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(background: _buildMediaCarousel()),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agregado a favoritos')),
                  );
                },
              ),
              // Botón para ver galería completa
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () => _showFullScreenGallery(_currentMediaIndex),
              ),
            ],
          ),

          // Contenido del detalle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGameHeader(),
                  const SizedBox(height: 16),
                  _buildPriceSection(isOutOfStock),
                  const SizedBox(height: 20),
                  _buildGameInfo(),
                  const SizedBox(height: 20),
                  _buildDescription(),
                  const SizedBox(height: 20),
                  if (_allMediaItems.length > 1) _buildMediaGallery(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: _buildCartButton(
        gameProvider,
        inCart,
        quantity,
        isOutOfStock,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMediaCarousel() {
    if (_allMediaItems.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.gamepad, size: 64, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentMediaIndex = index;
            });

            // Pausar videos anteriores
            for (final entry in _videoControllers.entries) {
              if (entry.key != index && entry.value.value.isInitialized) {
                entry.value.pause();
              }
            }
          },
          itemCount: _allMediaItems.length,
          itemBuilder: (context, index) {
            final mediaItem = _allMediaItems[index];

            return Hero(
              tag: 'game-media-${widget.game.id}-$index',
              child: GestureDetector(
                onTap: () {
                  if (mediaItem.type == 'image') {
                    _showFullScreenImage(
                      mediaItem.url,
                      'game-media-${widget.game.id}-$index',
                    );
                  } else if (mediaItem.type == 'video') {
                    _showFullScreenVideo(
                      mediaItem.url,
                      mediaItem.thumbnail,
                      'game-media-${widget.game.id}-$index',
                    );
                  } else {
                    _showFullScreenGallery(index);
                  }
                },
                child: _buildMediaWidget(mediaItem, index),
              ),
            );
          },
        ),

        // Indicadores de página
        if (_allMediaItems.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _allMediaItems.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentMediaIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

        // Indicador de tipo de media
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _allMediaItems[_currentMediaIndex].type == 'video'
                      ? Icons.videocam
                      : Icons.image,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _allMediaItems[_currentMediaIndex].type == 'video'
                      ? 'Video'
                      : 'Imagen',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Indicador visual para tap
        Positioned(
          bottom: 50,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _allMediaItems[_currentMediaIndex].type == 'video'
                      ? 'Toca para ver video'
                      : 'Toca para ampliar',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaWidget(MediaItem mediaItem, int index) {
    if (mediaItem.type == 'video') {
      final controller = _getVideoController(index, mediaItem.url);

      return Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail o video
          if (controller.value.isInitialized)
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            )
          else if (mediaItem.thumbnail != null)
            Image.network(
              mediaItem.thumbnail!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
            )
          else
            _buildVideoPlaceholder(),

          // Controles de video (solo para pausar/reproducir)
          if (controller.value.isInitialized)
            Positioned.fill(
              child: _buildVideoControls(controller, allowTap: false),
            )
          else if (mediaItem.thumbnail != null)
            const Center(
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 64,
              ),
            ),

          // Botón para pantalla completa
          if (controller.value.isInitialized)
            Positioned(
              bottom: 8,
              left: 8,
              child: GestureDetector(
                onTap:
                    () => _showFullScreenVideo(
                      mediaItem.url,
                      mediaItem.thumbnail,
                      'game-media-${widget.game.id}-$index',
                    ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      // Es una imagen
      return Image.network(
        mediaItem.url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
      );
    }
  }

  Widget _buildVideoControls(
    VideoPlayerController controller, {
    bool allowTap = true,
  }) {
    return GestureDetector(
      onTap:
          allowTap
              ? () {
                setState(() {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                });
              }
              : null,
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity: controller.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('Cargando video...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.error, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.game.name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Desarrollado por ${widget.game.developer}',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPriceSection(bool isOutOfStock) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${widget.game.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (widget.game.unitsInStock != null)
              Text(
                isOutOfStock
                    ? 'Agotado'
                    : '${widget.game.unitsInStock} en stock',
                style: TextStyle(
                  fontSize: 14,
                  color: isOutOfStock ? Colors.red : Colors.grey[600],
                  fontWeight:
                      isOutOfStock ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),

        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < 4 ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
            const SizedBox(width: 8),
            Text(
              '4.0',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del juego',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildInfoRow('Fecha de lanzamiento', widget.game.releaseDate),
            const SizedBox(height: 8),

            _buildInfoRow('Plataformas', widget.game.platforms.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          widget.game.description,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildMediaGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Galería',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _allMediaItems.length,
            itemBuilder: (context, index) {
              final item = _allMediaItems[index];
              final isSelected = index == _currentMediaIndex;

              return GestureDetector(
                onTap: () {
                  // Navegar al elemento en el carrusel principal
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                onLongPress: () {
                  // Long press para ver en pantalla completa
                  if (item.type == 'image') {
                    _showFullScreenImage(
                      item.url,
                      'gallery-thumb-${widget.game.id}-$index',
                    );
                  } else if (item.type == 'video') {
                    _showFullScreenVideo(
                      item.url,
                      item.thumbnail,
                      'gallery-thumb-${widget.game.id}-$index',
                    );
                  } else {
                    _showFullScreenGallery(index);
                  }
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'gallery-thumb-${widget.game.id}-$index',
                          child: _buildThumbnail(item),
                        ),
                        if (item.type == 'video')
                          const Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        if (item.isMainImage)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Principal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(MediaItem item) {
    String imageUrl;

    if (item.type == 'video' && item.thumbnail != null) {
      imageUrl = item.thumbnail!;
    } else if (item.type == 'image') {
      imageUrl = item.url;
    } else {
      return Container(
        color: Colors.grey[300],
        child: Icon(Icons.videocam, color: Colors.grey[600]),
      );
    }

    return Image.network(
      imageUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Icon(
            item.type == 'image' ? Icons.image : Icons.videocam,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  Widget _buildCartButton(
    GameProviders gameProvider,
    bool inCart,
    int quantity,
    bool isOutOfStock,
  ) {
    if (isOutOfStock) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.grey,
        icon: const Icon(Icons.block),
        label: const Text('Agotado'),
      );
    }

    if (inCart) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.green,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: () => gameProvider.removeFromCart(widget.game),
            ),
            Text(
              quantity.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => gameProvider.addToCart(widget.game),
            ),
          ],
        ),
        label: const Text('En carrito'),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () {
        gameProvider.addToCart(widget.game);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.game.name} agregado al carrito'),
            action: SnackBarAction(
              label: 'Ver carrito',
              onPressed: () {
                // Navegar al carrito
              },
            ),
          ),
        );
      },
      backgroundColor: Theme.of(context).primaryColor,
      icon: const Icon(Icons.shopping_cart),
      label: const Text('Agregar al carrito'),
    );
  }
}

// Widget para mostrar imagen individual en pantalla completa
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Hero(
            tag: heroTag,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 64),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Compartir imagen')));
            },
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar video individual en pantalla completa
class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final String heroTag;
  final String gameName;

  const FullScreenVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.heroTag,
    required this.gameName,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
        _controller.play();
      });

    // Auto-hide controls after 3 seconds
    _startControlsTimer();
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child:
                  _isLoading
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.thumbnailUrl != null)
                            Hero(
                              tag: widget.heroTag,
                              child: Image.network(
                                widget.thumbnailUrl!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          const SizedBox(height: 20),
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            'Cargando video...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                      : AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
            ),

            // Controls overlay
            if (_showControls && !_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Column(
                    children: [
                      // Top bar
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        title: Text(
                          widget.gameName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Compartir video'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Play/Pause button
                      Center(
                        child: IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 64,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_controller.value.isPlaying) {
                                _controller.pause();
                              } else {
                                _controller.play();
                              }
                            });
                            _startControlsTimer();
                          },
                        ),
                      ),

                      const Spacer(),

                      // Bottom controls
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Progress bar
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.white,
                                bufferedColor: Colors.grey,
                                backgroundColor: Colors.black26,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Time and controls
                            Row(
                              children: [
                                Text(
                                  _formatDuration(_controller.value.position),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDuration(_controller.value.duration),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Widget para mostrar galería completa en pantalla completa
class FullScreenGallery extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;
  final String gameName;

  const FullScreenGallery({
    super.key,
    required this.mediaItems,
    required this.initialIndex,
    required this.gameName,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  VideoPlayerController _getVideoController(int index, String videoUrl) {
    if (!_videoControllers.containsKey(index)) {
      _videoControllers[index] = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        )
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
    return _videoControllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });

              // Pausar videos anteriores
              for (final entry in _videoControllers.entries) {
                if (entry.key != index && entry.value.value.isInitialized) {
                  entry.value.pause();
                }
              }
            },
            itemCount: widget.mediaItems.length,
            itemBuilder: (context, index) {
              final mediaItem = widget.mediaItems[index];

              if (mediaItem.type == 'video') {
                final controller = _getVideoController(index, mediaItem.url);

                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (controller.value.isInitialized)
                        AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        )
                      else if (mediaItem.thumbnail != null)
                        Image.network(mediaItem.thumbnail!, fit: BoxFit.contain)
                      else
                        const CircularProgressIndicator(color: Colors.white),

                      if (controller.value.isInitialized)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (controller.value.isPlaying) {
                                controller.pause();
                              } else {
                                controller.play();
                              }
                            });
                          },
                          child: AnimatedOpacity(
                            opacity: controller.value.isPlaying ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      mediaItem.url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 64,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.7),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                widget.gameName,
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compartir media')),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom indicator
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} de ${widget.mediaItems.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          // Page indicators
          if (widget.mediaItems.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.mediaItems.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Modelo para los elementos de media
class MediaItem {
  final String type; // 'image' o 'video'
  final String url;
  final String alt;
  final String? thumbnail;
  final bool isMainImage;

  MediaItem({
    required this.type,
    required this.url,
    required this.alt,
    this.thumbnail,
    this.isMainImage = false,
  });
}

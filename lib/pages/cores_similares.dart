import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/story.dart';
import '../services/stories_service.dart';
import '../services/auth_service.dart';
import 'story_detalhes_page.dart';

class SimilarPaletteMapPage extends StatefulWidget {
  final StoryModel baseStory;

  const SimilarPaletteMapPage({super.key, required this.baseStory});

  @override
  State<SimilarPaletteMapPage> createState() => _SimilarPaletteMapPageState();
}

class _SimilarPaletteMapPageState extends State<SimilarPaletteMapPage> {
  final _storiesService = StoriesService();
  final _authService = AuthService();

  // Converte "#RRGGBB" em Color (ou null se der problema)
  Color? _parseHexToColor(String hex) {
    var s = hex.trim().toUpperCase();
    if (s.isEmpty) return null;
    if (!s.startsWith('#')) s = '#$s';
    if (s.length != 7) return null; // # + 6 caracteres

    try {
      final value = int.parse('FF${s.substring(1)}', radix: 16);
      return Color(value);
    } catch (_) {
      return null;
    }
  }

  // Distância ao quadrado entre duas cores RGB
  int _colorDistanceSquared(Color a, Color b) {
    final dr = a.red - b.red;
    final dg = a.green - b.green;
    final db = a.blue - b.blue;
    return dr * dr + dg * dg + db * db;
  }

  /// Pega a "cor predominante" de uma paleta:
  /// a primeira cor válida na lista de hex.
  Color? _getDominantColor(List<String> paletteHex) {
    for (final hex in paletteHex) {
      final c = _parseHexToColor(hex);
      if (c != null) return c;
    }
    return null;
  }

  /// Paletas são consideradas "parecidas" se a cor predominante
  /// de cada imagem for próxima no espaço RGB.
  bool _palettesAreSimilar(List<String> a, List<String> b) {
    final ca = _getDominantColor(a);
    final cb = _getDominantColor(b);

    if (ca == null || cb == null) return false;

    // Limiar de similaridade:
    // ~30 níveis de diferença em cada canal RGB -> 30^2 = 900.
    const maxDistanceSquared = 900;

    final dist2 = _colorDistanceSquared(ca, cb);
    return dist2 <= maxDistanceSquared;
  }

  void _openStoryDetail(StoryModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryDetailPage(story: story),
      ),
    );
  }

  void _openStoriesAtLocation(
      StoryModel tapped,
      List<StoryModel> allStories,
      ) {
    const eps = 0.0001;

    final sameLocationStories = allStories.where((s) {
      final sameLat = (s.latitude - tapped.latitude).abs() < eps;
      final sameLng = (s.longitude - tapped.longitude).abs() < eps;
      return sameLat && sameLng;
    }).toList();

    if (sameLocationStories.length <= 1) {
      _openStoryDetail(tapped);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Stories com paleta parecida\nneste local',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sameLocationStories.length,
                  itemBuilder: (context, index) {
                    final story = sameLocationStories[index];
                    final hasImage = story.imageUrl.isNotEmpty &&
                        story.imageUrl != 'web-placeholder-image';

                    return ListTile(
                      leading: hasImage
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          story.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      )
                          : const Icon(Icons.image_outlined),
                      title: Text(
                        story.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _openStoryDetail(story);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final base = widget.baseStory;

    final center = LatLng(base.latitude, base.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa – paleta parecida'),
      ),
      body: StreamBuilder<List<StoryModel>>(
        stream: _storiesService.getStoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allStories = snapshot.data ?? [];

          final filteredStories = allStories.where((s) {
            if (s.id == base.id) return true; // sempre inclui o próprio
            return _palettesAreSimilar(base.palette, s.palette);
          }).toList();

          if (filteredStories.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum outro story com paleta parecida encontrado.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final markers = filteredStories.map((story) {
            final point = LatLng(story.latitude, story.longitude);
            final hasImage = story.imageUrl.isNotEmpty &&
                story.imageUrl != 'web-placeholder-image';

            return Marker(
              point: point,
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () => _openStoriesAtLocation(story, filteredStories),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: hasImage
                            ? Image.network(
                          story.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(Icons.broken_image);
                          },
                        )
                            : Container(
                          color: Colors.deepPurple,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();

          return Column(
            children: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Text(
                          (user.email ?? 'U')[0].toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Stories com paleta parecida\nà imagem selecionada',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                          'https://tile.jawg.io/jawg-streets/{z}/{x}/{y}{r}.png?access-token=XTQqQtuYpd4tZq5UvMJxekHYVt2N6n8YlADK6hdRB0HgBtkUt41gRXv4vAekT4Qs',
                          userAgentPackageName:
                          'com.example.cores_historias_app',
                        ),
                        MarkerLayer(
                          markers: markers,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

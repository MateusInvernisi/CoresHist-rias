import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/story.dart';
import '../services/stories_service.dart';
import '../services/auth_service.dart';
import 'story_formulario_page.dart';
import 'story_lista_page.dart';
import 'story_detalhes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storiesService = StoriesService();
  final _authService = AuthService();

  void _openNewStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StoryFormPage(),
      ),
    );
  }

  void _openStoryList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StoryListPage(),
      ),
    );
  }

  void _openStoryDetail(StoryModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryDetailPage(story: story),
      ),
    );
  }

  void _logout() async {
    await _authService.signOut();
  }

  /// Abre bottom sheet com todos os stories próximos desse ponto.
  void _openStoriesAtLocation(
      StoryModel tapped,
      List<StoryModel> allStories,
      ) {
    const eps = 0.0001; // margem pra considerar "mesmo local"

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
                'Stories neste local',
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
                        Navigator.pop(context); // fecha o bottom sheet
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
    final center = const LatLng(-28.2600, -52.4100); // ajusta se quiser

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cores & Histórias'),
        actions: [
          IconButton(
            tooltip: 'Lista de stories',
            icon: const Icon(Icons.list_alt),
            onPressed: _openStoryList,
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<List<StoryModel>>(
        stream: _storiesService.getStoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stories = snapshot.data ?? [];

          final markers = stories.map((story) {
            final point = LatLng(story.latitude, story.longitude);
            final hasImage = story.imageUrl.isNotEmpty &&
                story.imageUrl != 'web-placeholder-image';

            return Marker(
              point: point,
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () => _openStoriesAtLocation(story, stories),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // bolinha com a imagem
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bem-vindo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              user.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                        // 🔹 Jawg Maps – estilo streets
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewStory,
        icon: const Icon(Icons.add),
        label: const Text('Novo story'),
      ),
    );
  }
}

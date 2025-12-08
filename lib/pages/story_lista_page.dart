import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/story.dart';
import '../services/stories_service.dart';
import '../services/auth_service.dart';
import 'story_detalhes_page.dart';
import 'story_formulario_page.dart';

class StoryListPage extends StatefulWidget {
  const StoryListPage({super.key});

  @override
  State<StoryListPage> createState() => _StoryListPageState();
}

class _StoryListPageState extends State<StoryListPage> {
  final _storiesService = StoriesService();
  final _authService = AuthService();

  void _openDetail(StoryModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryDetailPage(story: story),
      ),
    );
  }

  void _editStory(StoryModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryFormPage(story: story),
      ),
    );
  }

  Widget _buildImageThumb(StoryModel story) {
    final hasImage = story.imageUrl.isNotEmpty &&
        story.imageUrl != 'web-placeholder-image';

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          story.imageUrl,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.broken_image, size: 28),
            );
          },
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, size: 28),
    );
  }

  Widget _buildPaletteDots(StoryModel story) {
    if (story.palette.isEmpty) return const SizedBox.shrink();

    return Row(
      children: story.palette.take(4).map((hex) {
        Color color;
        try {
          color = Color(int.parse('0xFF${hex.replaceFirst('#', '')}'));
        } catch (_) {
          color = Colors.grey;
        }
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Faça login para ver seus stories.'),
        ),
      );
    }

    final currentEmail = currentUser.email ?? '';
    final currentName = currentUser.displayName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus stories'),
      ),
      body: StreamBuilder<List<StoryModel>>(
        // 🔹 pegamos TODOS e filtramos no app
        stream: _storiesService.getStoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allStories = snapshot.data ?? [];

          // 🔹 “Meus” stories = mesmo uid OU mesmo nome/email
          final stories = allStories.where((story) {
            final sameUid = story.userId == currentUser.uid;
            final sameAuthorEmail =
                story.authorName.isNotEmpty && story.authorName == currentEmail;
            final sameAuthorName =
                story.authorName.isNotEmpty && story.authorName == currentName;
            return sameUid || sameAuthorEmail || sameAuthorName;
          }).toList();

          if (stories.isEmpty) {
            return const Center(
              child: Text('Você ainda não criou nenhum story.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final story = stories[index];
              final dateStr =
              DateFormat('dd/MM/yy HH:mm').format(story.createdAt);

              return InkWell(
                onTap: () => _openDetail(story),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageThumb(story),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${story.latitude.toStringAsFixed(5)}, '
                                  '${story.longitude.toStringAsFixed(5)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildPaletteDots(story),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editStory(story),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

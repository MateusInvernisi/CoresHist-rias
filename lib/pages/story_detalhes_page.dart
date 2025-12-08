import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/story.dart';
import 'cores_similares.dart';

class StoryDetailPage extends StatelessWidget {
  final StoryModel story;

  const StoryDetailPage({super.key, required this.story});

  Widget _buildImage() {
    final hasImage =
        story.imageUrl.isNotEmpty && story.imageUrl != 'web-placeholder-image';

    if (!hasImage) {
      return Container(
        height: 220,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Imagem do story'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        story.imageUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 220,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Não foi possível carregar a imagem'),
          );
        },
      ),
    );
  }

  Widget _buildPalette() {
    if (story.palette.isEmpty) {
      return const Text(
        'Sem paleta registrada.',
        style: TextStyle(fontSize: 13),
      );
    }

    return Wrap(
      spacing: 8,
      children: story.palette.map((hex) {
        Color color;
        try {
          color = Color(int.parse('0xFF${hex.replaceFirst('#', '')}'));
        } catch (_) {
          color = Colors.grey;
        }
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
        );
      }).toList(),
    );
  }

  void _openSimilarPaletteMap(BuildContext context) {
    if (story.palette.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Este story não tem paleta registrada para comparação.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimilarPaletteMapPage(baseStory: story),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc =
        'Localização: ${story.latitude.toStringAsFixed(5)}, ${story.longitude.toStringAsFixed(5)}';
    final dateStr = DateFormat('dd/MM/yy HH:mm').format(story.createdAt);
    final author = story.authorName.isNotEmpty
        ? story.authorName
        : 'Autor desconhecido';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do story'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    author,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),

                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paleta de cores:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildPalette(),
            const SizedBox(height: 16),

            // 🔹 Botão para ver no mapa apenas stories com paleta parecida
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openSimilarPaletteMap(context),
                icon: const Icon(Icons.palette),
                label: const Text('Ver stories com paleta parecida no mapa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/story.dart';
import 'cores_similares_page.dart';

class StoryDetalhesPage extends StatelessWidget {
  final StoryModel story;

  const StoryDetalhesPage({super.key, required this.story});

  /// Monta o widget da imagem principal do story.
  Widget _montarImage() {
    final temImage =
        story.imageUrl.isNotEmpty && story.imageUrl != 'web-placeholder-image';

    if (!temImage) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text(
            'Nenhuma imagem disponível',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.network(
          story.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Text('Não foi possível carregar a imagem'),
            );
          },
        ),
      ),
    );
  }

  /// Paleta de cores do story.
  Widget _montarPaleta() {
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

  /// Abre mapa com stories que possuem paleta de cores semelhante a este story.
  void _abrirMapaPaletaSimilar(BuildContext context) {
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
        builder: (_) => PaletaSimilarPage(historiaBase: story),
      ),
    );
  }

  /// Interface da página de detalhes do story.
  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yy HH:mm').format(story.criadoEm);
    final autor = story.autor.isNotEmpty
        ? story.autor
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
            _montarImage(),
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
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 20,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      autor,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.black45,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dataFormatada,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
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
                  const Text(
                    'História',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story.text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
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
                  const Text(
                    'Paleta de cores',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _montarPaleta(),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _abrirMapaPaletaSimilar(context),
                      icon: const Icon(Icons.palette),
                      label: const Text('Ver stories com paleta parecida no mapa'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/story.dart';
import '../services/stories_service.dart';
import '../services/auth_service.dart';
import 'story_detalhes_page.dart';
import 'story_formulario_page.dart';

class StoryListaPage extends StatefulWidget {
  const StoryListaPage({super.key});

  @override
  State<StoryListaPage> createState() => _StoryListaPageState();
}

/// Carrega os stories com ações de visualização e edição.
class _StoryListaPageState extends State<StoryListaPage> {
  final _storiesService = StoriesService();
  final _authService = AuthService();

  /// Abre os detalhes do stories selecionado.
  void _openDetail(StoryModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryDetalhesPage(story: story),
      ),
    );
  }

  /// Abre o formulário para editar a história selecionada.
  void _editarStory(StoryModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryFormularioPage(story: story),
      ),
    );
  }

  /// Constrói a miniatura da imagem da história para ser exibida na lista.
  Widget _construirMiniaturaImagem(StoryModel story) {
    final temImage = story.imageUrl.isNotEmpty &&
        story.imageUrl != 'web-placeholder-image';

    if (temImage) {
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
              color: Colors.grey.shade300,
              alignment: Alignment.center,
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

  /// Constrói os pontos coloridos representando a paleta de cores do stories.
  Widget _construirPontosPaleta(StoryModel story) {
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

  /// Tela de stories do usuário.
  @override
  Widget build(BuildContext context) {
    final usuarioAtual = _authService.currentUser;

    if (usuarioAtual == null) {
      return const Scaffold(
        body: Center(
          child: Text('Faça login para ver seus stories.'),
        ),
      );
    }

    final emailAtual = usuarioAtual.email ?? '';
    final nomeAtual = usuarioAtual.displayName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas histórias'),
      ),
      body: StreamBuilder<List<StoryModel>>(
        stream: _storiesService.getStoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todasHistorias = snapshot.data ?? [];

          final stories = todasHistorias.where((story) {
            final mesmoUid = story.userId == usuarioAtual.uid;
            final mesmoEmailAutor =
                story.autor.isNotEmpty && story.autor == emailAtual;
            final sameAuthorName =
                story.autor.isNotEmpty && story.autor == nomeAtual;
            return mesmoUid || mesmoEmailAutor || sameAuthorName;
          }).toList();

          if (stories.isEmpty) {
            return const Center(
              child: Text(
                'Você ainda não publicou nenhuma história.\n'
                    'Crie uma nova história para vê-la aqui.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              final dataFormatada =
              DateFormat('dd/MM/yy HH:mm').format(story.criadoEm);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openDetail(story),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _construirMiniaturaImagem(story),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.black54,
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
                              const SizedBox(height: 8),
                              _construirPontosPaleta(story),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editarStory(story),
                            ),
                          ],
                        ),
                      ],
                    ),
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

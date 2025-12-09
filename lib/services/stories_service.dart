import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story.dart';

class StoriesService {
  final FirebaseFirestore _bancoDados = FirebaseFirestore.instance;
  final String _colecao = 'stories';

  /// Retorna lista de histórias, ordenando do mais recente para o mais antigo.
  Stream<List<StoryModel>> obterFluxoHistorias() {
    return _bancoDados
        .collection(_colecao)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => StoryModel.fromDoc(doc),
      )
          .toList(),
    );
  }

  // Mantém o nome antigo chamando o novo
  Stream<List<StoryModel>> getStoriesStream() {
    return obterFluxoHistorias();
  }

  /// Cria uma nova história.
  Future<void> criarHistoria(StoryModel historia) async {
    await _bancoDados.collection(_colecao).add(historia.toMap());
  }

  // Compatibilidade com nome antigo
  Future<void> createStory(StoryModel story) {
    return criarHistoria(story);
  }

  /// Atualiza uma história existente.
  Future<void> atualizarHistoria(StoryModel historia) async {
    await _bancoDados
        .collection(_colecao)
        .doc(historia.id)
        .update(historia.toMap());
  }

  Future<void> updateStory(StoryModel story) {
    return atualizarHistoria(story);
  }

  /// Exclui uma história pelo id.
  Future<void> excluirHistoria(String id) async {
    await _bancoDados.collection(_colecao).doc(id).delete();
  }

  Future<void> deleteStory(String id) {
    return excluirHistoria(id);
  }
}

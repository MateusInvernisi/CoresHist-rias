import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/story.dart';
import '../services/stories_service.dart';
import '../services/auth_service.dart';
import 'story_detalhes_page.dart';

class PaletaSimilarPage extends StatefulWidget {
  final StoryModel historiaBase;

  const PaletaSimilarPage({super.key, required this.historiaBase});

  @override
  State<PaletaSimilarPage> createState() => _MapaCoresSimilaresPageState();
}

class _MapaCoresSimilaresPageState extends State<PaletaSimilarPage> {
  final _servicoHistorias = StoriesService();
  final _servicoAutenticacao = AuthService();

  /// Converte uma cor hexadecimal em um objeto [Color].
  Color? _converterHexParaCor(String hex) {
    var s = hex.trim().toUpperCase();
    if (s.isEmpty) return null;
    if (!s.startsWith('#')) s = '#$s';
    if (s.length != 7) return null;

    try {
      final value = int.parse('FF${s.substring(1)}', radix: 16);
      return Color(value);
    } catch (_) {
      return null;
    }
  }

  /// Mede quão semelhantes duas cores são.
  int _distanciaQuadradaCores(Color a, Color b) {
    final dr = a.red - b.red;
    final dg = a.green - b.green;
    final db = a.blue - b.blue;
    return dr * dr + dg * dg + db * db;
  }

  /// Identifica a cor predominante da paleta.
  Color? _obterCorPredominante(List<String> paletaHex) {
    for (final hex in paletaHex) {
      final c = _converterHexParaCor(hex);
      if (c != null) return c;
    }
    return null;
  }

  /// Compara as cores predominantes usando a distância de cor e um limiar máximo.
  bool _paletasSemelhantes(List<String> a, List<String> b) {
    final ca = _obterCorPredominante(a);
    final cb = _obterCorPredominante(b);

    if (ca == null || cb == null) return false;

    const distanciaMaximaQuadrada = 900;

    final dist2 = _distanciaQuadradaCores(ca, cb);
    return dist2 <= distanciaMaximaQuadrada;
  }

  /// Abre a página de detalhes para a história informada usando navegação por [Navigator.push].
  void _abrirDetalheHistoria(StoryModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryDetalhesPage(story: story),
      ),
    );
  }

  /// Exibe todas os stories que estão no mesmo ponto do mapa que a história tocada.
  void _abrirHistoriasNoLocal(
      StoryModel historiaTocada,
      List<StoryModel> todasHistorias,
      ) {
    const precisao = 0.0001;

    final historiasMesmoLocal = todasHistorias.where((s) {
      final mesmaLat = (s.latitude - historiaTocada.latitude).abs() < precisao;
      final mesmaLng = (s.longitude - historiaTocada.longitude).abs() < precisao;
      return mesmaLat && mesmaLng;
    }).toList();

    if (historiasMesmoLocal.length <= 1) {
      _abrirDetalheHistoria(historiaTocada);
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
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Histórias neste local',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: historiasMesmoLocal.length,
                  itemBuilder: (context, index) {
                    final story = historiasMesmoLocal[index];

                    final temImagem = story.imageUrl.isNotEmpty &&
                        story.imageUrl != 'web-placeholder-image';

                    return ListTile(
                      leading: temImagem
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
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 20,
                                color: Colors.black45,
                              ),
                            );
                          },
                        ),
                      )
                          : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.black38,
                        ),
                      ),
                      title: Text(
                        story.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _abrirDetalheHistoria(story);
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

  /// Constrói a interface do mapa com as histórias filtradas semelhantes
  @override
  Widget build(BuildContext context) {
    final user = _servicoAutenticacao.currentUser;
    final historiaBase = widget.historiaBase;

    final center = LatLng(historiaBase.latitude, historiaBase.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa – paleta parecida'),
      ),
      body: StreamBuilder<List<StoryModel>>(
        stream: _servicoHistorias.getStoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar stories: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final todasHistorias = snapshot.data ?? [];

          final historiasFiltradas = todasHistorias.where((historia) {
            if (historia.id == historiaBase.id) return false;
            return _paletasSemelhantes(
              historiaBase.palette,
              historia.palette,
            );
          }).toList();

          final marcadores = <Marker>[
            Marker(
              point: center,
              width: 60,
              height: 60,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selecionada',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.push_pin,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ...historiasFiltradas.map((historia) {
              final point = LatLng(historia.latitude, historia.longitude);

              return Marker(
                point: point,
                width: 52,
                height: 52,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    _abrirHistoriasNoLocal(historia, todasHistorias);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ];

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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15.5,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: marcadores,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

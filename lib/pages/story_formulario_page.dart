import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/story.dart';
import '../services/auth_service.dart';
import '../services/stories_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

class StoryFormularioPage extends StatefulWidget {
  final StoryModel? story;

  const StoryFormularioPage({super.key, this.story});

  /// Cria página de formulário de story.
  @override
  State<StoryFormularioPage> createState() => _StoryFormularioPageState();
}

/// Estado da página de formulário.
class _StoryFormularioPageState extends State<StoryFormularioPage> {
  final _textController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();

  bool _carregando = false;
  bool _obterLocalizacao  = false;
  bool _gerarPaleta  = false;

  final _storiesService = StoriesService();
  final _authService = AuthService();
  final _locationService = LocationService();
  final _storageService = StorageService();
  final _seletorImagem = ImagePicker();

  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _urlImagemExistente;
  List<String> _paletteHex = [];

  /// Inicializa o estado preenchendo os campos ao editar um story ou obtendo a localização atual ao criar um novo.
  @override
  void initState() {
    super.initState();
    if (widget.story != null) {
      final story = widget.story!;
      _textController.text = story.text;
      _latController.text = story.latitude.toString();
      _longController.text = story.longitude.toString();
      _urlImagemExistente = story.imageUrl;
      _paletteHex = List<String>.from(story.palette);
    } else {
      _latController.text = '0.0';
      _longController.text = '0.0';
      _preencherLocalizacaoAtual();
    }
  }

  /// Obtém a localização atual do dispositivo e preenche os campos de latitude e longitude.
  Future<void> _preencherLocalizacaoAtual() async {
    setState(() => _obterLocalizacao  = true);
    try {
      final posicao  = await _locationService.getCurrentPosition();
      _latController.text = posicao.latitude.toString();
      _longController.text = posicao.longitude.toString();
    } catch (e) {
      debugPrint('[StoryForm] Erro ao pegar localização inicial: $e');
    } finally {
      if (mounted) {
        setState(() => _obterLocalizacao  = false);
      }
    }
  }

  /// Descarta os controladores ao cancelar.
  @override
  void dispose() {
    _textController.dispose();
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  /// Abre o seletor de imagens da galeria.
  Future<void> __selecionarImagem() async {
    final imagemSelecionada  = await _seletorImagem.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );

    if (imagemSelecionada  == null) return;

    final bytes = await imagemSelecionada.readAsBytes();

    setState(() {
      _imageFile = imagemSelecionada ;
      _imageBytes = bytes;
      _urlImagemExistente = null;
      _paletteHex = [];
    });

    await _gerarPaletaAPartirDosBytes(bytes);
  }

  /// Gera automaticamente a paleta de cores a partir dos bytes da imagem selecionada usando o PaletteGenerator.
  Future<void> _gerarPaletaAPartirDosBytes(Uint8List bytes) async {
    setState(() => _gerarPaleta  = true);

    try {
      final geradorPaleta  = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
        maximumColorCount: 6,
      );

      final cores = geradorPaleta .colors.toList();

      setState(() {
        _paletteHex = cores.map((color) {
          final value = color.value & 0xFFFFFF;
          return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar paleta: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _gerarPaleta  = false);
      }
    }
  }

  /// Valida os dados do formulário e realiza o processo de salvar ou atualizar o story no Firestore e no Storage.
  Future<void> _save() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado.')),
      );
      return;
    }

    final text = _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um texto para o story.')),
      );
      return;
    }

    final editando = widget.story != null;

    if (!editando && _imageBytes == null && (_urlImagemExistente == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem para o story.')),
      );
      return;
    }

    if ((_latController.text == '0.0' || _longController.text == '0.0') &&
        !_obterLocalizacao ) {
      await _preencherLocalizacaoAtual();
    }

    final lat = double.tryParse(_latController.text.trim()) ?? 0.0;
    final lng = double.tryParse(_longController.text.trim()) ?? 0.0;

    final displayName = user.displayName?.trim();
    final email = user.email ?? '';
    final fallbackName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'Usuário');

    setState(() => _carregando = true);
    debugPrint('[_save] Iniciando save. editing=$editando');

    try {
      String imageUrl;
      List<String> paletteToSave;

      if (_imageBytes != null) {
        debugPrint(
            '[_save] Temos _imageBytes. Tamanho: ${_imageBytes!.length} bytes');

        if (_paletteHex.isEmpty) {
          debugPrint('[_save] Paleta vazia, gerando...');
          await _gerarPaletaAPartirDosBytes(_imageBytes!);
        }
        paletteToSave = List<String>.from(_paletteHex);

        debugPrint('[_save] Subindo imagem pro Storage...');
        imageUrl = await _storageService.uploadStoryImage(
          _imageBytes!,
          user.uid,
        );
        debugPrint('[_save] Upload OK. URL: $imageUrl');
      } else {

        debugPrint('[_save] Usando imagem existente (edição).');
        imageUrl = widget.story!.imageUrl;
        paletteToSave = _paletteHex.isNotEmpty
            ? List<String>.from(_paletteHex)
            : List<String>.from(widget.story!.palette);
      }

      if (!editando) {
        debugPrint('[_save] Criando novo story...');

        final story = StoryModel(
          id: '',
          userId: user.uid,
          autor: fallbackName,
          imageUrl: imageUrl,
          text: text,
          latitude: lat,
          longitude: lng,
          palette: paletteToSave,
          criadoEm: DateTime.now(),
        );

        await _storiesService.createStory(story);
        debugPrint('[_save] Story criado com sucesso.');
      } else {
        debugPrint('[_save] Atualizando story existente...');
        final updated = widget.story!.copyWith(
          imageUrl: imageUrl,
          text: text,
          latitude: lat,
          longitude: lng,
          palette: paletteToSave,
        );
        await _storiesService.updateStory(updated);
        debugPrint('[_save] Story atualizado com sucesso.');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[_save] ERRO geral: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  /// Constrói a prévia visual da imagem selecionada, exibindo a foto, o placeholder existente ou um aviso caso não haja imagem.
  Widget _construirPreviaImagem() {
    Widget child;

    if (_imageBytes != null) {
      child = Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else if (_urlImagemExistente != null && _urlImagemExistente!.isNotEmpty) {
      child = Image.network(
        _urlImagemExistente!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) {
          return Center(
            child: Text(
              'Não foi possível carregar a imagem',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          );
        },
      );
    } else {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhuma imagem selecionada',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  /// Exibe a prévia da paleta de cores gerada ou uma mensagem orientando que ela será criada a partir da imagem.
  Widget _construirPreviaPaleta() {
    if (_paletteHex.isEmpty) {
      return const Text(
        'A paleta de cores será gerada automaticamente\n'
            'a partir da imagem selecionada.',
        textAlign: TextAlign.center,
      );
    }

    return Wrap(
      spacing: 8,
      children: _paletteHex.map((hex) {
        Color color;
        try {
          color = Color(int.parse('0xFF${hex.replaceFirst('#', '')}'));
        } catch (_) {
          color = Colors.grey;
        }
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
        );
      }).toList(),
    );
  }

  /// Constrói a interface da página com a imagem, paleta de cores, campo de texto e botão para salvar o story.
  @override
  Widget build(BuildContext context) {
    final editing = widget.story != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar story' : 'Novo story'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _construirPreviaImagem(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _carregando ? null : __selecionarImagem,
                icon: const Icon(Icons.photo_library),
                label: const Text('Selecionar imagem'),
              ),
            ),
            const SizedBox(height: 8),
            if (_gerarPaleta )
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Gerando paleta de cores...'),
                  ],
                ),
              )
            else
              _construirPreviaPaleta(),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Texto (frase, poema, trecho...)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _carregando ? null : _save,
                child: _carregando
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Salvar story'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

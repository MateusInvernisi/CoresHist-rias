import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/story.dart';
import '../services/auth_service.dart';
import '../services/stories_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

class StoryFormPage extends StatefulWidget {
  final StoryModel? story;

  const StoryFormPage({super.key, this.story});

  @override
  State<StoryFormPage> createState() => _StoryFormPageState();
}

class _StoryFormPageState extends State<StoryFormPage> {
  final _textController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _loading = false;
  bool _gettingLocation = false;
  bool _generatingPalette = false;

  final _storiesService = StoriesService();
  final _authService = AuthService();
  final _locationService = LocationService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  List<String> _paletteHex = [];

  @override
  void initState() {
    super.initState();
    if (widget.story != null) {
      final story = widget.story!;
      _textController.text = story.text;
      _latController.text = story.latitude.toString();
      _lngController.text = story.longitude.toString();
      _existingImageUrl = story.imageUrl;
      _paletteHex = List<String>.from(story.palette);
    } else {
      _latController.text = '0.0';
      _lngController.text = '0.0';
      _fillCurrentLocation(); // tenta pegar localização assim que abre
    }
  }

  Future<void> _fillCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      _latController.text = pos.latitude.toString();
      _lngController.text = pos.longitude.toString();
    } catch (e) {
      debugPrint('[StoryForm] Erro ao pegar localização inicial: $e');
    } finally {
      if (mounted) {
        setState(() => _gettingLocation = false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _imageFile = picked;
      _imageBytes = bytes;
      _existingImageUrl = null; // vamos usar a nova imagem
      _paletteHex = []; // resetar paleta para gerar de novo
    });

    await _generatePaletteFromBytes(bytes);
  }

  Future<void> _generatePaletteFromBytes(Uint8List bytes) async {
    setState(() => _generatingPalette = true);

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
        maximumColorCount: 6,
      );

      final colors = paletteGenerator.colors.toList();

      setState(() {
        _paletteHex = colors.map((color) {
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
        setState(() => _generatingPalette = false);
      }
    }
  }

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

    final editing = widget.story != null;

    if (!editing && _imageBytes == null && (_existingImageUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem para o story.')),
      );
      return;
    }

    // Se latitude/longitude ainda estiverem 0.0, tenta pegar localização agora
    if ((_latController.text == '0.0' || _lngController.text == '0.0') &&
        !_gettingLocation) {
      await _fillCurrentLocation();
    }

    final lat = double.tryParse(_latController.text.trim()) ?? 0.0;
    final lng = double.tryParse(_lngController.text.trim()) ?? 0.0;

    // Monta um nome amigável do autor
    final displayName = user.displayName?.trim();
    final email = user.email ?? '';
    final fallbackName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'Usuário');

    setState(() => _loading = true);
    debugPrint('[_save] Iniciando save. editing=$editing');

    try {
      String imageUrl;
      List<String> paletteToSave;

      // 1) Temos imagem nova em memória
      if (_imageBytes != null) {
        debugPrint(
            '[_save] Temos _imageBytes. Tamanho: ${_imageBytes!.length} bytes');

        // Garante que existe paleta
        if (_paletteHex.isEmpty) {
          debugPrint('[_save] Paleta vazia, gerando...');
          await _generatePaletteFromBytes(_imageBytes!);
        }
        paletteToSave = List<String>.from(_paletteHex);

        debugPrint('[_save] Subindo imagem pro Storage...');
        imageUrl = await _storageService.uploadStoryImage(
          _imageBytes!,
          user.uid,
        );
        debugPrint('[_save] Upload OK. URL: $imageUrl');
      } else {
        // 2) Sem nova imagem: usa a existente (edição)
        debugPrint('[_save] Usando imagem existente (edição).');
        imageUrl = widget.story!.imageUrl;
        paletteToSave = _paletteHex.isNotEmpty
            ? List<String>.from(_paletteHex)
            : List<String>.from(widget.story!.palette);
      }

      // 3) Criar ou atualizar story no Firestore
      if (!editing) {
        debugPrint('[_save] Criando novo story...');

        final story = StoryModel(
          id: '',
          userId: user.uid,
          authorName: fallbackName, // ✅ AGORA COM authorName
          imageUrl: imageUrl,
          text: text,
          latitude: lat,
          longitude: lng,
          palette: paletteToSave,
          createdAt: DateTime.now(),
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
          // authorName mantém o já salvo; se quisesse mudar, poderia passar aqui
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
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildImagePreview() {
    Widget child;

    if (_imageBytes != null) {
      child = Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      child = Image.network(
        _existingImageUrl!,
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

  Widget _buildPalettePreview() {
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
            _buildImagePreview(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loading ? null : _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Selecionar imagem'),
              ),
            ),
            const SizedBox(height: 8),
            if (_generatingPalette)
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
              _buildPalettePreview(),
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
                onPressed: _loading ? null : _save,
                child: _loading
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

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:provider/provider.dart';

enum _StoryComposeMode { text, media }

class SocialCreateStoryScreen extends StatefulWidget {
  const SocialCreateStoryScreen({super.key});

  @override
  State<SocialCreateStoryScreen> createState() =>
      _SocialCreateStoryScreenState();
}

class _SocialCreateStoryScreenState extends State<SocialCreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  final GlobalKey _textPreviewKey = GlobalKey();

  _StoryComposeMode _mode = _StoryComposeMode.media;
  bool _allowMultiple = true;
  bool _submitting = false;
  double _fontSize = 32;
  TextAlign _textAlign = TextAlign.center;
  int _selectedBackgroundIndex = 0;

  final List<_StoryMedia> _selectedMedia = <_StoryMedia>[];

  static const List<_StoryBackground> _backgrounds = <_StoryBackground>[
    _StoryBackground(
      gradient: LinearGradient(
        colors: [Color(0xFF515BD4), Color(0xFF8134AF), Color(0xFFF58529)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _StoryBackground(
      gradient: LinearGradient(
        colors: [Color(0xFF0093E9), Color(0xFF80D0C7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    _StoryBackground(
      gradient: LinearGradient(
        colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _StoryBackground(
      gradient: LinearGradient(
        colors: [Color(0xFFee9ca7), Color(0xFFffdde1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      textColor: Colors.black87,
    ),
    _StoryBackground(
      gradient: LinearGradient(
        colors: [Color(0xFF373B44), Color(0xFF4286f4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _StoryBackground(
      gradient: LinearGradient(
        colors: [Color(0xFFFFAFBD), Color(0xFFFFC3A0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.black87,
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  bool get _hasContent {
    if (_mode == _StoryComposeMode.text) {
      return _textController.text.trim().isNotEmpty;
    }
    return _selectedMedia.isNotEmpty;
  }

  bool get _supportsVideo => !kIsWeb;

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    if (!_hasContent) {
      showCustomSnackBar(
        getTranslated('story_content_required', context) ?? 'Content required',
        context,
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
    });

    try {
      final SocialController controller = context.read<SocialController>();

      if (_mode == _StoryComposeMode.text) {
        final File? image = await _renderTextStoryToImageFile();
        if (!mounted) return;
        if (image == null) {
          showCustomSnackBar(
            getTranslated('story_cannot_generate_image', context) ??
                'Cannot generate image',
            context,
            isError: true,
          );
          return;
        }
        await controller.createStory(
          fileType: 'image',
          filePath: image.path,
          storyDescription: _textController.text.trim(),
          coverPath: null,
          storyTitle: null,
          highlightHash: null,
        );
      } else {
        for (final _StoryMedia media in _selectedMedia) {
          await controller.createStory(
            fileType: media.isVideo ? 'video' : 'image',
            filePath: media.file.path,
            coverPath: media.coverPath,
            storyDescription: _captionController.text.trim().isNotEmpty
                ? _captionController.text.trim()
                : null,
            storyTitle: null,
            highlightHash: null,
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(e.toString(), context, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<File?> _renderTextStoryToImageFile() async {
    if (kIsWeb) return null;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final boundary = _textPreviewKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final double pixelRatio =
        MediaQuery.of(context).devicePixelRatio.clamp(2.0, 4.0).toDouble();
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final Uint8List bytes = byteData.buffer.asUint8List();
    final Directory dir = await getTemporaryDirectory();
    final File file = File(
      '${dir.path}/story_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _toggleMode(_StoryComposeMode mode) async {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _allowMultiple = _mode != _StoryComposeMode.text;
    });
  }

  Future<void> _pickFromGallery() async {
    if (_mode == _StoryComposeMode.text) {
      await _toggleMode(_StoryComposeMode.media);
    }

    if (_allowMultiple) {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 90);
      if (!mounted || images.isEmpty) return;
      setState(() {
        _selectedMedia.addAll(
          images.map((XFile image) => _StoryMedia(file: image)),
        );
      });
      return;
    }

    final bool? pickVideo = _supportsVideo
        ? await showModalBottomSheet<bool>(
            context: context,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (BuildContext ctx) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title:
                          Text(getTranslated('choose_photo', ctx) ?? 'Photo'),
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                    ListTile(
                      leading: const Icon(Icons.videocam_outlined),
                      title:
                          Text(getTranslated('choose_video', ctx) ?? 'Video'),
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ],
                ),
              );
            },
          )
        : false;

    if (!mounted) return;

    final bool isVideo = pickVideo ?? false;
    if (isVideo) {
      await _pickVideo(ImageSource.gallery);
    } else {
      await _pickSingleImage(ImageSource.gallery);
    }
  }

  Future<void> _pickSingleImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (!mounted || image == null) return;
    setState(() {
      if (!_allowMultiple) {
        _selectedMedia
          ..clear()
          ..add(_StoryMedia(file: image));
      } else {
        _selectedMedia.add(_StoryMedia(file: image));
      }
    });
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (!_supportsVideo) {
      showCustomSnackBar(
        getTranslated('device_not_support_video_picker', context) ??
            'Device does not support video picking',
        context,
        isError: true,
      );
      return;
    }
    final XFile? video = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30),
    );
    if (!mounted || video == null) return;

    final dynamic coverResult = await VideoThumbnail.thumbnailFile(
      video: video.path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 720,
      quality: 80,
    );
    String? cover;
    if (coverResult is String) {
      cover = coverResult;
    } else if (coverResult is XFile) {
      cover = coverResult.path;
    }

    setState(() {
      _selectedMedia
        ..clear()
        ..add(_StoryMedia(file: video, isVideo: true, coverPath: cover));
      _allowMultiple = false;
    });
  }

  void _removeMediaAt(int index) {
    if (_submitting) return;
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  void _toggleMultipleSelection() {
    if (_mode == _StoryComposeMode.text) return;
    if (_selectedMedia.any((media) => media.isVideo)) {
      showCustomSnackBar(
        getTranslated('remove_video_before_multi_select', context) ??
            'Remove video before selecting multiple',
        context,
        isError: true,
      );
      return;
    }
    setState(() {
      _allowMultiple = !_allowMultiple;
      if (!_allowMultiple && _selectedMedia.length > 1) {
        _selectedMedia..removeRange(1, _selectedMedia.length);
      }
    });
  }

  void _cycleTextAlign() {
    setState(() {
      switch (_textAlign) {
        case TextAlign.left:
          _textAlign = TextAlign.center;
          break;
        case TextAlign.center:
          _textAlign = TextAlign.right;
          break;
        default:
          _textAlign = TextAlign.left;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final social = context.watch<SocialController>();

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          getTranslated('create_story', context) ?? 'Create story',
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _handleSubmit,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(getTranslated('post_action', context) ?? 'Post'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _StoryFeatureBar(
                mode: _mode,
                onSelect: (mode) {
                  if (mode == _StoryComposeMode.media ||
                      mode == _StoryComposeMode.text) {
                    _toggleMode(mode);
                  } else {
                    showCustomSnackBar(
                      getTranslated('feature_in_development_short', context) ??
                          'Coming soon',
                      context,
                    );
                  }
                },
                onOpenCamera: () => _pickSingleImage(ImageSource.camera),
                onOpenVideoCamera: () => _pickVideo(ImageSource.camera),
                supportsVideo: _supportsVideo,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(getTranslated('photo_library', context) ??
                            'Photo library'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: Text(
                        getTranslated('select_multiple_files', context) ??
                            'Select multiple',
                      ),
                      selected:
                          _mode != _StoryComposeMode.text && _allowMultiple,
                      onSelected: (_) => _toggleMultipleSelection(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _mode == _StoryComposeMode.text
                      ? _buildTextComposer(context)
                      : _buildMediaComposer(context),
                ),
              ),
              if (_mode == _StoryComposeMode.media)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _captionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: getTranslated('story_caption_hint', context) ??
                          'Write a caption…',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
          if (_submitting || social.creatingStory)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTextComposer(BuildContext context) {
    final _StoryBackground background =
        _backgrounds[_selectedBackgroundIndex.clamp(
      0,
      _backgrounds.length - 1,
    )];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: RepaintBoundary(
                  key: _textPreviewKey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(gradient: background.gradient),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          _textController.text.trim().isEmpty
                              ? (getTranslated(
                                      'story_text_placeholder_long', context) ??
                                  'Write something…')
                              : _textController.text.trim(),
                          textAlign: _textAlign,
                          style: TextStyle(
                            color: background.textColor,
                            fontSize: _fontSize,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            focusNode: _textFocus,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText:
                  getTranslated('story_text_hint', context) ?? 'Add your text…',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildBackgroundSelector(background),
          const SizedBox(height: 12),
          _buildTextOptions(),
        ],
      ),
    );
  }

  Widget _buildBackgroundSelector(_StoryBackground selected) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _backgrounds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final bool isSelected = index == _selectedBackgroundIndex;
          final _StoryBackground background = _backgrounds[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedBackgroundIndex = index;
              });
            },
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: background.gradient,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextOptions() {
    return Column(
      children: [
        Row(
          children: [
            Text(getTranslated('story_text_align', context) ?? 'Text align'),
            const Spacer(),
            IconButton(
              onPressed: _cycleTextAlign,
              icon: Icon(
                _textAlign == TextAlign.left
                    ? Icons.format_align_left
                    : _textAlign == TextAlign.center
                        ? Icons.format_align_center
                        : Icons.format_align_right,
              ),
              tooltip:
                  getTranslated('story_change_alignment', context) ?? 'Align',
            ),
          ],
        ),
        Row(
          children: [
            Text(getTranslated('story_font_size', context) ?? 'Font size'),
            Expanded(
              child: Slider(
                value: _fontSize,
                min: 20,
                max: 48,
                onChanged: (double value) {
                  setState(() {
                    _fontSize = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaComposer(BuildContext context) {
    if (_selectedMedia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.photo_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(getTranslated('story_choose_media_prompt', context) ??
                'Choose photos or videos'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.builder(
        itemCount: _selectedMedia.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (BuildContext context, int index) {
          final _StoryMedia media = _selectedMedia[index];
          final String previewPath = media.coverPath ?? media.file.path;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(File(previewPath), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeMediaAt(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              if (media.isVideo)
                const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white70,
                    size: 40,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryMedia {
  final XFile file;
  final bool isVideo;
  final String? coverPath;
  const _StoryMedia({required this.file, this.isVideo = false, this.coverPath});
}

class _StoryBackground {
  final Gradient gradient;
  final Color textColor;
  const _StoryBackground({
    required this.gradient,
    this.textColor = Colors.white,
  });
}

class _StoryFeatureBar extends StatelessWidget {
  final _StoryComposeMode mode;
  final ValueChanged<_StoryComposeMode> onSelect;
  final VoidCallback onOpenCamera;
  final VoidCallback onOpenVideoCamera;
  final bool supportsVideo;

  const _StoryFeatureBar({
    required this.mode,
    required this.onSelect,
    required this.onOpenCamera,
    required this.onOpenVideoCamera,
    required this.supportsVideo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String t(String key) => getTranslated(key, context) ?? key;

    // FIX overflow: dùng scroll ngang thay vì Row cứng + Spacer
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StoryFeatureChip(
              icon: Icons.text_fields,
              label: t('story_feature_text'),
              selected: mode == _StoryComposeMode.text,
              onTap: () => onSelect(_StoryComposeMode.text),
            ),
            const SizedBox(width: 8),
            _StoryFeatureChip(
              icon: Icons.music_note,
              label: t('story_feature_music'),
              selected: false,
              onTap: () => showCustomSnackBar(
                t('story_music_coming_soon'),
                context,
              ),
            ),
            const SizedBox(width: 8),
            _StoryFeatureChip(
              icon: Icons.all_inclusive,
              label: t('story_feature_boomerang'),
              selected: false,
              onTap: () => showCustomSnackBar(
                t('story_boomerang_coming_soon'),
                context,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: t('capture_photo'),
              icon: const Icon(Icons.camera_alt_outlined),
              color: colorScheme.onSurface,
              onPressed: onOpenCamera,
            ),
            if (supportsVideo)
              IconButton(
                tooltip: t('record_video'),
                icon: const Icon(Icons.videocam_outlined),
                color: colorScheme.onSurface,
                onPressed: onOpenVideoCamera,
              ),
          ],
        ),
      ),
    );
  }
}

class _StoryFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StoryFeatureChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withOpacity(.1)
              : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

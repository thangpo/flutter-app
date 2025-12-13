import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/return_code.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:provider/provider.dart';

enum _StoryComposeMode { text, media }

enum _StoryTextPreset { classic, deco, bubble }

class SocialCreateStoryScreen extends StatefulWidget {
  const SocialCreateStoryScreen({super.key});

  @override
  State<SocialCreateStoryScreen> createState() =>
      _SocialCreateStoryScreenState();
}

class _SocialCreateStoryScreenState extends State<SocialCreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  static const Duration _maxVideoDuration = Duration(seconds: 30);

  final TextEditingController _captionController = TextEditingController();
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _textPreviewKey = GlobalKey();
  final List<_StoryCanvasElement> _canvasElements = <_StoryCanvasElement>[];
  final Map<String, VideoPlayerController> _canvasVideoControllers =
      <String, VideoPlayerController>{};
  String? _selectedElementId;
  String? _editingElementId;
  String? _scalingElementId;
  Size? _scalingInitialSize;
  double? _scalingInitialFontSize;
  Size _canvasSize = const Size(360, 640);
  bool _renderingCanvas = false;
  int _elementSeed = 0;
  _CanvasCaptureConfig _captureConfig = const _CanvasCaptureConfig();

  _StoryComposeMode _mode = _StoryComposeMode.text;
  bool _allowMultiple = false;
  bool _submitting = false;
  int _selectedBackgroundIndex = 0;

  final List<_StoryMedia> _selectedMedia = <_StoryMedia>[];
  final PageController _mediaPageController = PageController();
  int _currentMediaIndex = 0;

  static const List<_StoryBackground> _backgrounds = <_StoryBackground>[
    _StoryBackground(
      gradient: LinearGradient(
        colors: [Color(0xFF0093E9), Color(0xFF80D0C7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    _StoryBackground(
      gradient: LinearGradient(
        colors: [Color(0xFF515BD4), Color(0xFF8134AF), Color(0xFFF58529)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
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

  static const Map<_StoryTextPreset, String> _presetLabels =
      <_StoryTextPreset, String>{
    _StoryTextPreset.classic: 'Classic',
    _StoryTextPreset.deco: 'Deco',
    _StoryTextPreset.bubble: 'Bubble',
  };

  static const List<Color> _textColors = <Color>[
    Colors.white,
    Colors.black,
    Color(0xFFFAD02C),
    Color(0xFFFF5E6C),
    Color(0xFF00C9A7),
    Color(0xFF6C63FF),
    Color(0xFFFFCFDF),
  ];

  @override
  void initState() {
    super.initState();
    if (_mode == _StoryComposeMode.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ensureTextElementExists();
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _mediaPageController.dispose();
    for (final _StoryCanvasElement element in _canvasElements) {
      if (element is _StoryCanvasTextElement) {
        element.controller.dispose();
        element.focusNode.dispose();
      }
    }
    for (final VideoPlayerController controller
        in _canvasVideoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _hasContent {
    if (_mode == _StoryComposeMode.text) {
      return _canvasElements.any((_StoryCanvasElement element) {
        if (element is _StoryCanvasTextElement) {
          return element.controller.text.trim().isNotEmpty;
        }
        return true;
      });
    }
    return _selectedMedia.isNotEmpty;
  }

  bool get _canvasHasVideo => _canvasElements.any(
        (element) => element is _StoryCanvasMediaElement && element.isVideo,
      );

  _StoryCanvasMediaElement? get _canvasVideoElement {
    try {
      return _canvasElements
          .whereType<_StoryCanvasMediaElement>()
          .firstWhere((element) => element.isVideo);
    } catch (_) {
      return null;
    }
  }

  _StoryCanvasMediaElement? get _canvasImageElement {
    try {
      return _canvasElements
          .whereType<_StoryCanvasMediaElement>()
          .firstWhere((element) => !element.isVideo);
    } catch (_) {
      return null;
    }
  }

  bool get _isEditingText => _editingElementId != null;

  bool get _supportsVideo => !kIsWeb;

  Future<XFile?> _processPickedVideo(XFile picked) async {
    final Duration? duration = await _videoDurationOf(picked.path);
    if (!mounted) return null;
    if (duration == null || duration <= _maxVideoDuration) {
      return picked;
    }

    final String? trimmedPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _VideoTrimScreen(
          videoPath: picked.path,
          maxDuration: _maxVideoDuration,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return null;
    if (trimmedPath == null) {
      return null;
    }
    return XFile(trimmedPath);
  }

  Future<Duration?> _videoDurationOf(String path) async {
    final VideoPlayerController controller =
        VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      return controller.value.duration;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<String?> _generateVideoThumbnail(String path) async {
    try {
      final dynamic result = await VideoThumbnail.thumbnailFile(
        video: path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 720,
        quality: 80,
      );
      if (result is String && result.isNotEmpty) return result;
      if (result is XFile) return result.path;
      return null;
    } catch (_) {
      return null;
    }
  }

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
        _stopEditingTextElement();
        if (_canvasHasVideo) {
          final _StoryCanvasMediaElement? videoElement = _canvasVideoElement;
          if (videoElement == null) return;
          final String? coverPath =
              await _generateVideoThumbnail(videoElement.file.path);
          final String? overlayMeta = _buildOverlayMeta();
          await controller.createStory(
            fileType: 'video',
            filePath: videoElement.file.path,
            coverPath: coverPath,
            storyDescription: _canvasStoryDescription(),
            storyTitle: null,
            highlightHash: null,
            overlayMeta: overlayMeta,
          );
        } else if (_canvasImageElement != null) {
          final _StoryCanvasMediaElement imageElement = _canvasImageElement!;
          final String? overlayMeta = _buildOverlayMeta();
          await controller.createStory(
            fileType: 'image',
            filePath: imageElement.file.path,
            coverPath: null,
            storyDescription: _canvasStoryDescription(),
            storyTitle: null,
            highlightHash: null,
            overlayMeta: overlayMeta,
          );
        } else {
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
            storyDescription: _canvasStoryDescription(),
            coverPath: null,
            storyTitle: null,
            highlightHash: null,
          );
        }
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
    final _CapturedCanvasImage? capture =
        await _captureCanvasImage(const _CanvasCaptureConfig());
    return capture?.file;
  }

  Future<_CapturedCanvasImage?> _captureCanvasImage(
    _CanvasCaptureConfig config,
  ) async {
    if (kIsWeb) return null;
    if (_renderingCanvas) return null;
    final String? previousSelection = _selectedElementId;
    final _CanvasCaptureConfig previousConfig = _captureConfig;
    setState(() {
      _renderingCanvas = true;
      _selectedElementId = null;
      _captureConfig = config;
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (!mounted) {
      return null;
    }
    final RenderRepaintBoundary? boundary = _textPreviewKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      if (mounted) {
        setState(() {
          _renderingCanvas = false;
          _captureConfig = previousConfig;
          _selectedElementId = previousSelection;
        });
      }
      return null;
    }
    final double pixelRatio =
        MediaQuery.of(context).devicePixelRatio.clamp(2.0, 4.0).toDouble();
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      if (mounted) {
        setState(() {
          _renderingCanvas = false;
          _captureConfig = previousConfig;
          _selectedElementId = previousSelection;
        });
      }
      return null;
    }

    final Uint8List bytes = byteData.buffer.asUint8List();
    final Directory dir = await getTemporaryDirectory();
    final File file = File(
      '${dir.path}/story_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    if (mounted) {
      setState(() {
        _renderingCanvas = false;
        _captureConfig = previousConfig;
        _selectedElementId = previousSelection;
      });
    }
    return _CapturedCanvasImage(
      file: file,
      width: image.width,
      height: image.height,
    );
  }

  Future<_CanvasVideoExportResult?> _renderCanvasVideoStory() async {
    final _StoryCanvasMediaElement? videoElement = _canvasVideoElement;
    if (videoElement == null) {
      return null;
    }
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) {
      return null;
    }

    final _CapturedCanvasImage? backgroundCapture =
        await _captureCanvasImage(const _CanvasCaptureConfig(
      showText: false,
      showImages: false,
      showVideos: false,
    ));
    if (backgroundCapture == null) {
      return null;
    }

    final bool hasTextOverlay = _canvasElements.any(
      (element) =>
          element is _StoryCanvasTextElement &&
          element.controller.text.trim().isNotEmpty,
    );
    _CapturedCanvasImage? textCapture;
    if (hasTextOverlay) {
      textCapture = await _captureCanvasImage(const _CanvasCaptureConfig(
        showText: true,
        showImages: false,
        showVideos: false,
        transparentBackground: true,
      ));
      if (textCapture == null) {
        try {
          await backgroundCapture.file.delete();
        } catch (_) {}
        return null;
      }
    }

    Future<void> cleanupCaptures() async {
      try {
        await backgroundCapture.file.delete();
      } catch (_) {}
      final _CapturedCanvasImage? overlayCapture = textCapture;
      if (overlayCapture != null) {
        try {
          await overlayCapture.file.delete();
        } catch (_) {}
      }
    }

    final double scaleX = _canvasSize.width == 0
        ? 1
        : backgroundCapture.width / _canvasSize.width;
    final double scaleY = _canvasSize.height == 0
        ? 1
        : backgroundCapture.height / _canvasSize.height;

    int clampPosition(double value, int canvasExtent, int size) {
      final int intValue = value.round();
      final int maxStart = max(0, canvasExtent - size);
      if (intValue < 0) return 0;
      if (intValue > maxStart) return maxStart;
      return intValue;
    }

    final int videoWidth = max(1, (videoElement.size.width * scaleX).round());
    final int videoHeight = max(1, (videoElement.size.height * scaleY).round());
    final double rawLeft =
        (videoElement.position.dx - videoElement.size.width / 2) * scaleX;
    final double rawTop =
        (videoElement.position.dy - videoElement.size.height / 2) * scaleY;
    final int videoLeft =
        clampPosition(rawLeft, backgroundCapture.width, videoWidth);
    final int videoTop =
        clampPosition(rawTop, backgroundCapture.height, videoHeight);

    final Directory dir = await getTemporaryDirectory();
    final String outputPath =
        '${dir.path}/story_video_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}.mp4';

    final List<String> ffmpegArgs = <String>[
      '-y',
      '-i',
      videoElement.file.path,
      '-loop',
      '1',
      '-i',
      backgroundCapture.file.path,
    ];
    if (textCapture != null) {
      ffmpegArgs.addAll(<String>['-loop', '1', '-i', textCapture.file.path]);
    }

    final String afterVideoLabel =
        textCapture != null ? '[tmp_after_vid]' : '[pre_scale]';
    final StringBuffer filter = StringBuffer()
      ..write(
          '[1:v]scale=${backgroundCapture.width}:${backgroundCapture.height}[bg];')
      ..write('[0:v]scale=$videoWidth:$videoHeight[vid];')
      ..write(
          '[bg][vid]overlay=$videoLeft:$videoTop:shortest=1$afterVideoLabel;');
    String lastLabel = afterVideoLabel;
    if (textCapture != null) {
      const String textOverlayLabel = '[after_text]';
      filter.write(
          '$afterVideoLabel[2:v]overlay=0:0:shortest=1$textOverlayLabel;');
      lastLabel = textOverlayLabel;
    }
    filter.write('$lastLabel scale=trunc(iw/2)*2:trunc(ih/2)*2[out];');

    ffmpegArgs.addAll(<String>[
      '-filter_complex',
      filter.toString(),
      '-map',
      '[out]',
      '-map',
      '0:a?',
      '-c:v',
      'libx264',
      '-crf',
      '20',
      '-preset',
      'veryfast',
      '-c:a',
      'aac',
      '-shortest',
      outputPath,
    ]);

    final session = await FFmpegKit.executeWithArguments(ffmpegArgs);
    final ReturnCode? returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      if (kDebugMode) {
        final String logs = (await session.getAllLogsAsString()) ?? '';
        final String? stack = await session.getFailStackTrace();
        debugPrint('FFmpeg render failed: $stack\n$logs');
      }
      await cleanupCaptures();
      return null;
    }

    await cleanupCaptures();
    final String? cover = await _generateVideoThumbnail(outputPath);
    return _CanvasVideoExportResult(
      videoPath: outputPath,
      coverPath: cover,
    );
  }

  Future<void> _toggleMode(_StoryComposeMode mode) async {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _allowMultiple = _mode != _StoryComposeMode.text;
      if (mode == _StoryComposeMode.media) {
        _canvasElements.clear();
        _selectedElementId = null;
        _editingElementId = null;
      }
    });
    if (mode == _StoryComposeMode.text) {
      _ensureTextElementExists();
    }
  }

  Future<void> _pickFromGallery() async {
    if (_mode == _StoryComposeMode.text) {
      await _addCanvasMediaFromGallery();
      return;
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
    final XFile? picked = await _picker.pickVideo(source: source);
    if (!mounted || picked == null) return;

    final XFile? processed = await _processPickedVideo(picked);
    if (!mounted || processed == null) return;

    final String? cover = await _generateVideoThumbnail(processed.path);

    setState(() {
      _selectedMedia
        ..clear()
        ..add(_StoryMedia(file: processed, isVideo: true, coverPath: cover));
      _allowMultiple = false;
    });
  }

  void _removeMediaAt(int index) {
    if (_submitting || _selectedMedia.isEmpty) return;
    if (index < 0 || index >= _selectedMedia.length) return;
    setState(() {
      _selectedMedia.removeAt(index);
      if (_selectedMedia.isEmpty) {
        _currentMediaIndex = 0;
      } else if (_currentMediaIndex >= _selectedMedia.length) {
        _currentMediaIndex = _selectedMedia.length - 1;
      }
    });
    if (_selectedMedia.isNotEmpty) {
      _mediaPageController.animateToPage(
        _currentMediaIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  String? _buildOverlayMeta() {
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) return null;
    final List<Map<String, dynamic>> overlays = <Map<String, dynamic>>[];
    for (final _StoryCanvasElement element in _canvasElements) {
      if (element is! _StoryCanvasTextElement) continue;
      final String text = element.controller.text.trim();
      if (text.isEmpty) continue;
      overlays.add({
        'type': 'text',
        'text': text,
        'x': element.position.dx / _canvasSize.width,
        'y': element.position.dy / _canvasSize.height,
        'w': element.size.width / _canvasSize.width,
        'h': element.size.height / _canvasSize.height,
        'font_scale': element.fontSize / _canvasSize.width,
        'align': element.textAlign.name,
        'rotation': element.rotation,
        'color': _colorToHex(element.color),
        'has_bg': element.hasBackground,
        'preset': element.preset.name,
      });
    }
    if (overlays.isEmpty) return null;
    return jsonEncode(overlays);
  }


  void _ensureTextElementExists() {
    if (_canvasElements.isNotEmpty) return;
    _addTextElement();
  }

  String _nextElementId(String prefix) {
    _elementSeed += 1;
    return '${prefix}_$_elementSeed';
  }

  void _addTextElement({_StoryCanvasTextElement? template}) {
    final String id = _nextElementId('text');
    final Size canvas = _canvasSize;
    final _StoryCanvasTextElement element = _StoryCanvasTextElement(
      id: id,
      position: Offset(canvas.width / 2, canvas.height / 2),
      size: template?.size ?? Size(canvas.width * .7, 160),
      rotation: 0,
      controller: TextEditingController(),
      focusNode: FocusNode(),
      fontSize: template?.fontSize ?? 32,
      textAlign: template?.textAlign ?? TextAlign.center,
      color:
          template?.color ?? _backgrounds[_selectedBackgroundIndex].textColor,
      preset: template?.preset ?? _StoryTextPreset.classic,
      hasBackground: template?.hasBackground ?? false,
    );
    element.focusNode.addListener(() {
      if (!element.focusNode.hasFocus && _editingElementId == id) {
        setState(() {
          _editingElementId = null;
        });
      }
    });
    element.controller.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    setState(() {
      _canvasElements.add(element);
      _selectedElementId = id;
      _editingElementId = id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        element.focusNode.requestFocus();
      }
    });
  }

  Size _initialMediaElementSize() {
    if (_mode == _StoryComposeMode.text) {
      return _canvasSize;
    }
    return Size(_canvasSize.width * .6, _canvasSize.height * .4);
  }

  Future<void> _initializeCanvasVideoController(
    _StoryCanvasMediaElement element,
  ) async {
    final VideoPlayerController controller =
        VideoPlayerController.file(File(element.file.path));
    try {
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _canvasVideoControllers[element.id] = controller;
      });
    } catch (_) {
      await controller.dispose();
    }
  }

  void _disposeCanvasVideoController(String id) {
    final VideoPlayerController? controller =
        _canvasVideoControllers.remove(id);
    controller?.dispose();
  }

  Future<void> _addCanvasImages(List<XFile> images) async {
    if (images.isEmpty) return;
    if (_canvasHasVideo) {
      showCustomSnackBar(
        getTranslated('story_remove_video_first', context) ??
            'Remove the current video before adding other media',
        context,
        isError: true,
      );
      return;
    }
    final Size targetSize = _initialMediaElementSize();
    setState(() {
      for (final XFile image in images) {
        final String id = _nextElementId('img');
        _canvasElements.add(
          _StoryCanvasMediaElement(
            id: id,
            position: Offset(_canvasSize.width / 2, _canvasSize.height / 2),
            size: targetSize,
            rotation: 0,
            file: image,
            isVideo: false,
            thumbnail: null,
          ),
        );
        _selectedElementId = id;
      }
    });
  }

  Future<void> _addCanvasVideo(XFile video) async {
    if (_canvasHasVideo) {
      showCustomSnackBar(
        getTranslated('story_only_one_video_allowed', context) ??
            'Remove the current video before adding another one',
        context,
        isError: true,
      );
      return;
    }
    final Uint8List? bytes = await _generateVideoThumbnailBytes(video.path);
    final Size targetSize = _initialMediaElementSize();
    final String id = _nextElementId('vid');
    final _StoryCanvasMediaElement element = _StoryCanvasMediaElement(
      id: id,
      position: Offset(_canvasSize.width / 2, _canvasSize.height / 2),
      size: targetSize,
      rotation: 0,
      file: video,
      isVideo: true,
      thumbnail: bytes,
    );
    setState(() {
      _canvasElements.add(element);
      _selectedElementId = id;
    });
    await _initializeCanvasVideoController(element);
  }

  Future<void> _addCanvasMediaFromGallery() async {
    final bool enableVideo = _supportsVideo && !_canvasHasVideo;
    bool pickVideo = false;

    if (_supportsVideo) {
      final bool? result = await showModalBottomSheet<bool>(
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
                  title: Text(getTranslated('choose_photo', ctx) ?? 'Photo'),
                  onTap: () => Navigator.of(ctx).pop(false),
                ),
                ListTile(
                  enabled: enableVideo,
                  leading: const Icon(Icons.videocam_outlined),
                  title: Text(getTranslated('choose_video', ctx) ?? 'Video'),
                  onTap: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          );
        },
      );
      if (!mounted) return;
      pickVideo = (result ?? false) && enableVideo;
    }

    if (pickVideo) {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (!mounted || video == null) return;
      final XFile? processed = await _processPickedVideo(video);
      if (!mounted || processed == null) return;
      await _addCanvasVideo(processed);
      return;
    }

    final bool allowMulti = _mode != _StoryComposeMode.text;
    final List<XFile> images = allowMulti
        ? await _picker.pickMultiImage(imageQuality: 90)
        : await _pickSingleCanvasImage();
    if (!mounted || images.isEmpty) return;
    await _addCanvasImages(images);
  }

  Future<List<XFile>> _pickSingleCanvasImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (!mounted || image == null) return const <XFile>[];
    return <XFile>[image];
  }

  void _handleCanvasTapOutside() {
    if (_editingElementId != null) {
      _stopEditingTextElement();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildCanvasToolbar(
    ThemeData theme,
    _StoryBackground background,
  ) {
    final bool hasSelection = _selectedElementId != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // _StoryCircleButton(
        //   tooltip: getTranslated('stickers', context) ?? 'Stickers',
        //   onTap: _showComingSoonSnack,
        //   child: const Icon(Icons.emoji_emotions_outlined,
        //       color: Colors.white, size: 20),
        // ),
        // const SizedBox(height: 14),
        _StoryCircleButton(
          tooltip: getTranslated('story_add_text', context) ?? 'Add text',
          onTap: _submitting ? null : _addNewTextBlock,
          child: const Text(
            'Aa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // _StoryCircleButton(
        //   tooltip: getTranslated('music', context) ?? 'Music',
        //   onTap: _showComingSoonSnack,
        //   child: const Icon(Icons.music_note, color: Colors.white, size: 20),
        // ),
        // const SizedBox(height: 14),
        _StoryCircleButton(
          tooltip: getTranslated('story_add_media', context) ?? 'Add media',
          onTap: _submitting ? null : _addCanvasMediaFromGallery,
          child: const Icon(Icons.collections_outlined,
              color: Colors.white, size: 20),
        ),
        const SizedBox(height: 14),
        // _StoryCircleButton(
        //   tooltip: '@',
        //   onTap: _showComingSoonSnack,
        //   child:
        //       const Icon(Icons.alternate_email, color: Colors.white, size: 20),
        // ),
        // const SizedBox(height: 14),
        _StoryCircleButton(
          tooltip: getTranslated('remove', context) ?? 'Remove',
          onTap: hasSelection && !_submitting ? _deleteSelectedElement : null,
          child:
              const Icon(Icons.delete_outline, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 20),
        _StoryCircleButton(
          tooltip: getTranslated('background_color', context) ?? 'Background',
          onTap: _submitting ? null : _openBackgroundSelectorSheet,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: background.gradient,
              border: Border.all(
                color: Colors.white.withValues(alpha: .4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoonSnack() {
    showCustomSnackBar(
      getTranslated('feature_in_development_short', context) ?? 'Coming soon',
      context,
    );
  }

  Future<void> _addNewTextBlock() async {
    if (_mode != _StoryComposeMode.text) {
      await _toggleMode(_StoryComposeMode.text);
    }
    if (_editingElementId != null) {
      _stopEditingTextElement();
    }
    final _StoryCanvasTextElement? template = _selectedTextElement;
    _addTextElement(template: template);
  }

  // Future<void> _selectAudience() async {
  //   final int? index = await showModalBottomSheet<int>(
  //     context: context,
  //     backgroundColor: Theme.of(context).colorScheme.surface,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //     ),
  //     builder: (BuildContext ctx) {
  //       return SafeArea(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: List<Widget>.generate(_audienceOptions.length, (int i) {
  //             final bool selected = i == _audienceIndex;
  //             return ListTile(
  //               leading: Icon(
  //                 selected
  //                     ? Icons.radio_button_checked
  //                     : Icons.radio_button_off,
  //               ),
  //               title: Text(_audienceOptions[i]),
  //               onTap: () => Navigator.of(ctx).pop(i),
  //             );
  //           }),
  //         ),
  //       );
  //     },
  //   );
  //   if (index == null) return;
  //   setState(() {
  //     _audienceIndex = index;
  //   });
  // }

  Widget _buildBottomActionBar(ThemeData theme, double keyboardInset) {
    final double safeBottom = MediaQuery.of(context).padding.bottom;
    final bool keyboardVisible = keyboardInset > 0;
    final double bottomPadding = safeBottom + 16;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        keyboardVisible ? 8 : 12,
        20,
        bottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54, Colors.black],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: GestureDetector(
          //     // onTap: _submitting ? null : _selectAudience,
          //     child: Container(
          //       padding:
          //           const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          //       decoration: BoxDecoration(
          //         color: Colors.black.withValues(alpha: .6),
          //         borderRadius: BorderRadius.circular(20),
          //         border: Border.all(color: Colors.white12),
          //       ),
          //       child: Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Text(
          //             _audienceOptions[_audienceIndex],
          //             style: theme.textTheme.labelLarge
          //                 ?.copyWith(color: Colors.white),
          //           ),
          //           const SizedBox(width: 6),
          //           const Icon(Icons.expand_more,
          //               color: Colors.white, size: 18),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          // if (isMediaMode) ...[
          //   const SizedBox(height: 12),
          //   TextField(
          //     controller: _captionController,
          //     style: const TextStyle(color: Colors.white),
          //     maxLines: 2,
          //     decoration: InputDecoration(
          //       hintText: getTranslated('story_caption_hint', context) ??
          //           'Viết chú thích...',
          //       hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
          //       filled: true,
          //       fillColor: Colors.white.withValues(alpha: .08),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(16),
          //         borderSide: BorderSide.none,
          //       ),
          //       contentPadding:
          //           const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          //     ),
          //   ),
          // ],
          // const SizedBox(height: 16),
          Row(
            children: [
              _BottomQuickButton(
                icon: Icons.settings_outlined,
                onTap: _showComingSoonSnack,
              ),
              const SizedBox(width: 12),
              _BottomQuickButton(
                icon: Icons.photo_camera_outlined,
                onTap: _submitting
                    ? null
                    : () {
                        if (_mode == _StoryComposeMode.text) {
                          _captureImageFromSource(ImageSource.camera);
                        } else {
                          _pickSingleImage(ImageSource.camera);
                        }
                      },
              ),
              const SizedBox(width: 12),
              _BottomQuickButton(
                icon: Icons.photo_library_outlined,
                onTap: _submitting
                    ? null
                    : () {
                        if (_mode == _StoryComposeMode.text) {
                          _addCanvasMediaFromGallery();
                        } else {
                          _pickFromGallery();
                        }
                      },
              ),
              const Spacer(),
              _buildShareButton(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(ThemeData theme) {
    final bool enabled = _hasContent && !_submitting;
    return ElevatedButton(
      onPressed: enabled ? _handleSubmit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(140, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: _submitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(getTranslated('share', context) ?? 'Chia sẻ'),
    );
  }

  Widget _buildInlineTextEditor(ThemeData theme, double keyboardInset) {
    final String? editingId = _editingElementId;
    if (editingId == null) return const SizedBox.shrink();
    final _StoryCanvasElement? element = _findCanvasElement(editingId);
    if (element is! _StoryCanvasTextElement) return const SizedBox.shrink();
    final double bottomPadding = keyboardInset + 16;
    final double topPadding = MediaQuery.of(context).padding.top;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // _StoryCircleButton(
                    //   onTap: _showComingSoonSnack,
                    //   child: const Icon(Icons.alternate_email,
                    //       color: Colors.white),
                    // ),
                    // const SizedBox(width: 12),
                    // _StoryCircleButton(
                    //   onTap: _showComingSoonSnack,
                    //   child: const Icon(Icons.tag, color: Colors.white),
                    // ),
                    const Spacer(),
                    TextButton(
                      onPressed: _stopEditingTextElement,
                      child: Text(
                        getTranslated('done', context) ?? 'Xong',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: bottomPadding + 36,
              child: SizedBox(
                height: 240,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbColor: Colors.white,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                    ),
                    child: Slider(
                      value: element.fontSize.clamp(18, 72),
                      min: 18,
                      max: 72,
                      onChanged: (double value) {
                        setState(() {
                          element.fontSize = value;
                        });
                        _refocusEditingText(element);
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: bottomPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextPresetSelector(element),
                  const SizedBox(height: 12),
                  _buildTextColorSelector(element),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPresetSelector(_StoryCanvasTextElement element) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _presetLabels.entries.map((entry) {
        final bool selected = element.preset == entry.key;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            selected: selected,
            label: Text(entry.value),
            selectedColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: .12),
            labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) {
              setState(() {
                element.preset = entry.key;
              });
              _refocusEditingText(element);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextColorSelector(_StoryCanvasTextElement element) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final Color color in _textColors)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    element.color = color;
                  });
                  _refocusEditingText(element);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: element.color == color
                          ? Colors.white
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          _StoryCircleButton(
            onTap: () {
              setState(() {
                element.hasBackground = !element.hasBackground;
              });
              _refocusEditingText(element);
            },
            child: Icon(
              element.hasBackground
                  ? Icons.format_color_fill
                  : Icons.format_color_text,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          _StoryCircleButton(
            onTap: () {
              setState(() {
                element.textAlign = _nextAlignment(element.textAlign);
              });
              _refocusEditingText(element);
            },
            child: Icon(_alignmentIcon(element.textAlign),
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  IconData _alignmentIcon(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return Icons.format_align_left;
      case TextAlign.center:
        return Icons.format_align_center;
      case TextAlign.right:
        return Icons.format_align_right;
      default:
        return Icons.format_align_center;
    }
  }

  TextAlign _nextAlignment(TextAlign align) {
    if (align == TextAlign.left) return TextAlign.center;
    if (align == TextAlign.center) return TextAlign.right;
    return TextAlign.left;
  }

  void _refocusEditingText(_StoryCanvasTextElement element) {
    if (_editingElementId != element.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      element.focusNode.requestFocus();
    });
  }

  Future<void> _openBackgroundSelectorSheet() async {
    final int? index = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated('background_color', context) ??
                    'Background color',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: List<Widget>.generate(_backgrounds.length, (int i) {
                  final _StoryBackground bg = _backgrounds[i];
                  final bool selected = i == _selectedBackgroundIndex;
                  return GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(i),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: bg.gradient,
                        borderRadius: BorderRadius.circular(18),
                        border: selected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || index == null) return;
    setState(() {
      _selectedBackgroundIndex = index;
    });
  }

  Future<void> _captureImageFromSource(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (!mounted || image == null) return;
    await _addCanvasImages(<XFile>[image]);
  }

  _StoryCanvasElement? _findCanvasElement(String id) {
    try {
      return _canvasElements.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _generateVideoThumbnailBytes(String path) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.PNG,
        quality: 75,
      );
    } catch (_) {
      return null;
    }
  }

  void _selectCanvasElement(String? id) {
    if (_selectedElementId == id) return;
    setState(() {
      _selectedElementId = id;
      if (id == null) {
        _editingElementId = null;
      }
    });
  }

  void _deleteSelectedElement() {
    if (_selectedElementId == null) return;
    final _StoryCanvasElement? element =
        _findCanvasElement(_selectedElementId!);
    if (element == null) return;
    setState(() {
      _canvasElements.remove(element);
      if (_editingElementId == element.id) {
        _editingElementId = null;
      }
      _selectedElementId = null;
      if (element is _StoryCanvasTextElement) {
        element.focusNode.unfocus();
        element.controller.dispose();
        element.focusNode.dispose();
      } else if (element is _StoryCanvasMediaElement && element.isVideo) {
        _disposeCanvasVideoController(element.id);
      }
    });
  }

  void _moveElement(String id, Offset delta, Size canvasSize) {
    final _StoryCanvasElement? element = _findCanvasElement(id);
    if (element == null) return;
    setState(() {
      element.position += delta;
      _clampElement(element, canvasSize);
    });
  }

  void _clampElement(_StoryCanvasElement element, Size canvasSize) {
    final double halfW = element.size.width / 2;
    final double halfH = element.size.height / 2;
    final double minX = halfW;
    final double maxX = canvasSize.width - halfW;
    final double minY = halfH;
    final double maxY = canvasSize.height - halfH;
    element.position = Offset(
      element.position.dx.clamp(minX, maxX),
      element.position.dy.clamp(minY, maxY),
    );
  }

  void _updateTextElementSize(
    _StoryCanvasTextElement element,
    Size reportedSize,
  ) {
    const double minSide = 24;
    if (reportedSize.width <= 1 || reportedSize.height <= 1) {
      return;
    }
    final Size clamped = Size(
      reportedSize.width.clamp(minSide, _canvasSize.width),
      reportedSize.height.clamp(minSide, _canvasSize.height),
    );
    final bool changed = (element.size.width - clamped.width).abs() > 0.5 ||
        (element.size.height - clamped.height).abs() > 0.5;
    if (!changed || !mounted) return;
    setState(() {
      element.size = clamped;
      _clampElement(element, _canvasSize);
    });
  }

  TextStyle _textStyleFor(_StoryCanvasTextElement element) {
    return TextStyle(
      color: element.color,
      fontSize: element.fontSize,
      fontWeight: element.preset == _StoryTextPreset.classic
          ? FontWeight.w600
          : element.preset == _StoryTextPreset.deco
              ? FontWeight.w700
              : FontWeight.w500,
      letterSpacing: element.preset == _StoryTextPreset.deco ? 1.2 : 0,
      height: element.preset == _StoryTextPreset.bubble ? 1.35 : 1.15,
    );
  }

  void _handleScaleStart(_StoryCanvasElement element) {
    _scalingElementId = element.id;
    _scalingInitialSize = element.size;
    if (element is _StoryCanvasTextElement) {
      _scalingInitialFontSize = element.fontSize;
    } else {
      _scalingInitialFontSize = null;
    }
  }

  void _handleScaleUpdate(
    _StoryCanvasElement element,
    ScaleUpdateDetails details,
  ) {
    if (_scalingElementId != element.id) return;
    if (details.pointerCount > 1) {
      if (element is _StoryCanvasTextElement) {
        final double baseFont = _scalingInitialFontSize ?? element.fontSize;
        final double targetFont = (baseFont * details.scale).clamp(16.0, 120.0);
        if ((targetFont - element.fontSize).abs() > .25) {
          setState(() {
            element.fontSize = targetFont;
          });
        }
      } else {
        final Size baseSize = _scalingInitialSize ?? element.size;
        final double newWidth =
            (baseSize.width * details.scale).clamp(60.0, _canvasSize.width);
        final double newHeight =
            (baseSize.height * details.scale).clamp(60.0, _canvasSize.height);
        if ((newWidth - element.size.width).abs() > .5 ||
            (newHeight - element.size.height).abs() > .5) {
          setState(() {
            element.size = Size(newWidth, newHeight);
            _clampElement(element, _canvasSize);
          });
        }
      }
    } else if (details.pointerCount == 1) {
      _moveElement(element.id, details.focalPointDelta, _canvasSize);
    }
  }

  void _handleScaleEnd(String elementId) {
    if (_scalingElementId == elementId) {
      _scalingElementId = null;
      _scalingInitialSize = null;
      _scalingInitialFontSize = null;
    }
  }

  _StoryCanvasTextElement? get _selectedTextElement {
    final String? id = _selectedElementId;
    if (id == null) return null;
    final _StoryCanvasElement? element = _findCanvasElement(id);
    return element is _StoryCanvasTextElement ? element : null;
  }

  void _startEditingTextElement(String id) {
    final _StoryCanvasElement? element = _findCanvasElement(id);
    if (element is! _StoryCanvasTextElement) return;
    setState(() {
      _editingElementId = id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        element.focusNode.requestFocus();
      }
    });
  }

  void _stopEditingTextElement() {
    if (_editingElementId == null) return;
    final _StoryCanvasElement? element = _findCanvasElement(_editingElementId!);
    if (element is _StoryCanvasTextElement) {
      element.focusNode.unfocus();
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _editingElementId = null;
    });
  }

  String? _canvasStoryDescription() {
    final String joined = _canvasElements
        .whereType<_StoryCanvasTextElement>()
        .map((element) => element.controller.text.trim())
        .where((text) => text.isNotEmpty)
        .join(' ');
    return joined.isEmpty ? null : joined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final social = context.watch<SocialController>();
    final mediaQuery = MediaQuery.of(context);
    final double keyboardInset = mediaQuery.viewInsets.bottom;
    final _StoryBackground background =
        _backgrounds[_selectedBackgroundIndex.clamp(
      0,
      _backgrounds.length - 1,
    )];

    final Widget content = SafeArea(
      top: true,
      bottom: false,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: _buildStoryViewport(context, background),
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 16,
            child: _buildBackButton(),
          ),
          Positioned(
            top: 80,
            right: 20,
            bottom: 220,
            child: _buildCanvasToolbar(theme, background),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(theme, keyboardInset),
          ),
          if (_isEditingText && keyboardInset > 0)
            _buildInlineTextEditor(theme, keyboardInset),
          if (_submitting || social.creatingStory)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: content,
      ),
    );
  }

  Widget _buildStoryViewport(
    BuildContext context,
    _StoryBackground background,
  ) {
    final ThemeData theme = Theme.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final bool isTextMode = _mode == _StoryComposeMode.text;
        final bool transparentBackground =
            isTextMode && _captureConfig.transparentBackground;
        return GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: _handleCanvasTapOutside,
          child: RepaintBoundary(
            key: _textPreviewKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Container(
                key: _canvasKey,
                decoration: BoxDecoration(
                  gradient: isTextMode && !transparentBackground
                      ? background.gradient
                      : null,
                  color: transparentBackground
                      ? Colors.transparent
                      : isTextMode
                          ? null
                          : Colors.black,
                ),
                child: Stack(
                  children: [
                    if (isTextMode) ...[
                      for (final _StoryCanvasElement element in _canvasElements)
                        if (_shouldRenderElement(element))
                          _buildCanvasElement(element, theme),
                      if (_canvasElements.isEmpty && _captureConfig.showText)
                        Center(
                          child: Text(
                            getTranslated(
                                    'story_text_placeholder_long', context) ??
                                'Viết gì đó...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  background.textColor.withValues(alpha: .75),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ] else
                      _buildMediaPreview(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return _StoryCircleButton(
      onTap: () => Navigator.of(context).maybePop(),
      child:
          const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
    );
  }

  bool _shouldRenderElement(_StoryCanvasElement element) {
    if (element is _StoryCanvasTextElement) {
      return _captureConfig.showText;
    }
    if (element is _StoryCanvasMediaElement) {
      return element.isVideo
          ? _captureConfig.showVideos
          : _captureConfig.showImages;
    }
    return true;
  }

  Widget _buildCanvasElement(
    _StoryCanvasElement element,
    ThemeData theme,
  ) {
    final bool editing = element.id == _editingElementId;
    final Offset topLeft = element.position -
        Offset(element.size.width / 2, element.size.height / 2);
    final bool enableGestures = _mode == _StoryComposeMode.text;
    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _selectCanvasElement(element.id),
        onDoubleTap: element is _StoryCanvasTextElement
            ? () => _startEditingTextElement(element.id)
            : null,
        onScaleStart:
            enableGestures ? (details) => _handleScaleStart(element) : null,
        onScaleUpdate: enableGestures
            ? (details) => _handleScaleUpdate(element, details)
            : null,
        onScaleEnd: enableGestures ? (_) => _handleScaleEnd(element.id) : null,
        child: _buildElementContent(element, editing),
      ),
    );
  }

  Widget _buildElementContent(
    _StoryCanvasElement element,
    bool editing,
  ) {
    if (element is _StoryCanvasTextElement) {
      final TextStyle textStyle = _textStyleFor(element);
      final Widget baseText = editing
          ? TextField(
              controller: element.controller,
              focusNode: element.focusNode,
              maxLines: null,
              minLines: 1,
              textAlign: element.textAlign,
              cursorColor: element.color,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: textStyle,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
          : Text(
              element.controller.text,
              textAlign: element.textAlign,
              style: textStyle,
            );
      final Widget display = element.hasBackground
          ? IntrinsicWidth(
              child: IntrinsicHeight(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: element.color.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: baseText,
                ),
              ),
            )
          : baseText;
      return _SizeReportingWidget(
        onSize: (Size reported) => _updateTextElementSize(element, reported),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _canvasSize.width - 24,
            maxHeight: _canvasSize.height - 24,
          ),
          child: display,
        ),
      );
    }
    if (element is _StoryCanvasMediaElement) {
      final BorderRadius radius = BorderRadius.circular(20);
      final Widget mediaWidget;
      if (element.isVideo) {
        final VideoPlayerController? controller =
            _canvasVideoControllers[element.id];
        if (controller != null && controller.value.isInitialized) {
          mediaWidget = FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          );
        } else if (element.thumbnail != null) {
          mediaWidget = Image.memory(
            element.thumbnail!,
            fit: BoxFit.cover,
          );
        } else {
          mediaWidget = Container(
            color: Colors.black12,
            child: const Icon(
              Icons.videocam,
              color: Colors.white70,
              size: 32,
            ),
          );
        }
      } else {
        mediaWidget = Image.file(
          File(element.file.path),
          fit: BoxFit.cover,
        );
      }
      return SizedBox.fromSize(
        size: element.size,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              mediaWidget,
              if (element.isVideo &&
                  (_canvasVideoControllers[element.id]?.value.isInitialized !=
                      true))
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMediaPreview() {
    if (_selectedMedia.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_outlined,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              getTranslated('story_choose_media_prompt', context) ??
                  'Chọn ảnh hoặc video',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _mediaPageController,
          onPageChanged: (int index) {
            setState(() {
              _currentMediaIndex = index;
            });
          },
          itemCount: _selectedMedia.length,
          itemBuilder: (BuildContext context, int index) {
            final _StoryMedia media = _selectedMedia[index];
            final String previewPath = media.coverPath ?? media.file.path;
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(previewPath),
                  fit: BoxFit.cover,
                ),
                if (media.isVideo)
                  const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white70,
                      size: 60,
                    ),
                  ),
              ],
            );
          },
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _StoryCircleButton(
            tooltip: getTranslated('remove', context) ?? 'Remove',
            onTap:
                _submitting ? null : () => _removeMediaAt(_currentMediaIndex),
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
        if (_selectedMedia.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(_selectedMedia.length, (int i) {
                final bool active = i == _currentMediaIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _BottomQuickButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _BottomQuickButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: .12)
              : Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _SizeReportingWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSize;

  const _SizeReportingWidget({
    required this.child,
    required this.onSize,
  });

  @override
  State<_SizeReportingWidget> createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<_SizeReportingWidget> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final Size? newSize = context.size;
      if (newSize == null) return;
      if (_oldSize == newSize) return;
      _oldSize = newSize;
      widget.onSize(newSize);
    });
    return widget.child;
  }
}

class _StoryCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  const _StoryCircleButton({
    required this.child,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 48;
    final Widget button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: .12)
              : Colors.black.withValues(alpha: .45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _StoryMedia {
  final XFile file;
  final bool isVideo;
  final String? coverPath;
  const _StoryMedia({required this.file, this.isVideo = false, this.coverPath});
}

class _CanvasCaptureConfig {
  final bool showText;
  final bool showImages;
  final bool showVideos;
  final bool transparentBackground;

  const _CanvasCaptureConfig({
    this.showText = true,
    this.showImages = true,
    this.showVideos = true,
    this.transparentBackground = false,
  });
}

class _CapturedCanvasImage {
  final File file;
  final int width;
  final int height;

  const _CapturedCanvasImage({
    required this.file,
    required this.width,
    required this.height,
  });
}

class _CanvasVideoExportResult {
  final String videoPath;
  final String? coverPath;

  const _CanvasVideoExportResult({
    required this.videoPath,
    this.coverPath,
  });
}

class _StoryBackground {
  final Gradient gradient;
  final Color textColor;
  const _StoryBackground({
    required this.gradient,
    this.textColor = Colors.white,
  });
}

enum _StoryCanvasElementType { text, media }

abstract class _StoryCanvasElement {
  _StoryCanvasElement({
    required this.id,
    required this.position,
    required this.size,
    required this.rotation,
  });

  final String id;
  Offset position;
  Size size;
  double rotation;

  _StoryCanvasElementType get type;
}

class _StoryCanvasTextElement extends _StoryCanvasElement {
  _StoryCanvasTextElement({
    required super.id,
    required super.position,
    required super.size,
    required super.rotation,
    required this.controller,
    required this.focusNode,
    required this.fontSize,
    required this.textAlign,
    required this.color,
    required this.preset,
    required this.hasBackground,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  double fontSize;
  TextAlign textAlign;
  Color color;
  _StoryTextPreset preset;
  bool hasBackground;

  @override
  _StoryCanvasElementType get type => _StoryCanvasElementType.text;
}

class _StoryCanvasMediaElement extends _StoryCanvasElement {
  _StoryCanvasMediaElement({
    required super.id,
    required super.position,
    required super.size,
    required super.rotation,
    required this.file,
    required this.isVideo,
    required this.thumbnail,
  });

  final XFile file;
  final bool isVideo;
  final Uint8List? thumbnail;

  @override
  _StoryCanvasElementType get type => _StoryCanvasElementType.media;
}

String _colorToHex(Color color) {
  final int value = color.value;
  return '#${value.toRadixString(16).padLeft(8, '0')}';
}

class _VideoTrimScreen extends StatefulWidget {
  final String videoPath;
  final Duration maxDuration;
  const _VideoTrimScreen({
    required this.videoPath,
    required this.maxDuration,
  });

  @override
  State<_VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<_VideoTrimScreen> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _saving = false;
  bool _progressVisible = false;

  @override
  void initState() {
    super.initState();
    _trimmer.loadVideo(videoFile: File(widget.videoPath));
  }

  Future<void> _togglePlayback() async {
    final bool playbackState = await _trimmer.videoPlaybackControl(
      startValue: _startValue,
      endValue: _endValue,
    );
    if (!mounted) return;
    setState(() => _isPlaying = playbackState);
  }

  Future<void> _saveTrimmedVideo() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _progressVisible = true;
    });

    final double maxLengthMs =
        widget.maxDuration.inMilliseconds.toDouble().clamp(0, double.infinity);
    final double totalMs =
        (_trimmer.videoPlayerController?.value.duration ?? Duration.zero)
            .inMilliseconds
            .toDouble();

    double start = _startValue;
    double end = _endValue;

    if (end <= start) {
      end = (start + maxLengthMs).clamp(0, totalMs);
    }
    if (end - start > maxLengthMs) {
      end = start + maxLengthMs;
    }
    if (end > totalMs && totalMs > 0) {
      end = totalMs;
      start = (end - maxLengthMs).clamp(0, end);
    }

    await _trimmer.saveTrimmedVideo(
      startValue: start,
      endValue: end,
      storageDir: StorageDir.temporaryDirectory,
      videoFolderName: 'story_trim',
      onSave: (String? outputPath) {
        if (!mounted) return;
        setState(() {
          _progressVisible = false;
          _saving = false;
        });
        if (outputPath == null || outputPath.isEmpty) {
          showCustomSnackBar(
            getTranslated('video_trim_failed', context) ??
                'Unable to trim video',
            context,
            isError: true,
          );
        } else {
          Navigator.of(context).pop(outputPath);
        }
      },
    );
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double maxSeconds = widget.maxDuration.inSeconds.toDouble();
    final double selectedMs = (_endValue - _startValue)
        .clamp(0, widget.maxDuration.inMilliseconds.toDouble());
    final Duration selectedDuration =
        Duration(milliseconds: selectedMs.round());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          getTranslated('trim_video', context) ?? 'Trim video',
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveTrimmedVideo,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    getTranslated('save', context) ?? 'Save',
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_progressVisible)
              const LinearProgressIndicator(
                minHeight: 2,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: VideoViewer(trimmer: _trimmer),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 60,
                      viewerWidth: MediaQuery.of(context).size.width,
                      maxVideoLength: widget.maxDuration,
                      durationStyle: DurationStyle.FORMAT_MM_SS,
                      onChangeStart: (value) => _startValue = value,
                      onChangeEnd: (value) => _endValue = value,
                      onChangePlaybackState: (value) =>
                          setState(() => _isPlaying = value),
                      editorProperties: TrimEditorProperties(
                        borderRadius: 6,
                        borderWidth: 3,
                        borderPaintColor: theme.colorScheme.primary,
                        circlePaintColor:
                            theme.colorScheme.primary.withValues(alpha: .85),
                      ),
                      areaProperties:
                          TrimAreaProperties.edgeBlur(thumbnailQuality: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${selectedDuration.inSeconds}s / ${maxSeconds.toInt()}s',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    IconButton(
                      iconSize: 48,
                      color: Colors.white,
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                      ),
                      onPressed: _saving ? null : _togglePlayback,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

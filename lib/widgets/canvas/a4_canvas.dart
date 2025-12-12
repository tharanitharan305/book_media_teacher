import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/page_model.dart';
import '../../models/widget_model.dart';

typedef MoveCallback = void Function(String id, double x, double y);
typedef ResizeCallback = void Function(String id, double width, double height);
typedef UpdatePropertiesCallback =
    void Function(String id, Map<String, dynamic> properties);
typedef ActionCallback = void Function(String id, String action);
typedef SelectionCallback = void Function(String? id);
Color _hexToColor(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.transparent;
  try {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  } catch (e) {
    return Colors.black;
  }
}

class A4Canvas extends StatefulWidget {
  final PageModel page;
  final String? selectedWidgetId;
  final MoveCallback? onMoveWidget;
  final ResizeCallback? onResizeWidget;
  final UpdatePropertiesCallback? onUpdateWidget;
  final ActionCallback? onWidgetAction;
  final SelectionCallback? onSelectionChanged;

  const A4Canvas({
    Key? key,
    required this.page,
    this.selectedWidgetId,
    this.onMoveWidget,
    this.onResizeWidget,
    this.onUpdateWidget,
    this.onWidgetAction,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<A4Canvas> createState() => _A4CanvasState();
}

class _A4CanvasState extends State<A4Canvas> {
  String? _editingWidgetId;
  final Map<String, VideoControllerHolder> _mediaControllers = {};

  @override
  void initState() {
    super.initState();
    _refreshMediaControllers();
  }

  @override
  void didUpdateWidget(covariant A4Canvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshMediaControllers();
    if (widget.selectedWidgetId != _editingWidgetId) {
      _editingWidgetId = null;
    }
  }

  @override
  void dispose() {
    for (final c in _mediaControllers.values) c.dispose();
    super.dispose();
  }

  void _refreshMediaControllers() {
    final mediaWidgets = widget.page.widgets.where((w) {
      final t = w.type.toLowerCase();
      return t == 'video' || t == 'audio';
    });
    final activeIds = mediaWidgets.map((w) => w.id).toSet();
    _mediaControllers.removeWhere((id, holder) {
      if (!activeIds.contains(id)) {
        holder.dispose();
        return true;
      }
      return false;
    });
    for (final w in mediaWidgets) {
      if (!_mediaControllers.containsKey(w.id)) {
        final src = w.properties['src'] as String?;
        if (src != null && src.isNotEmpty) {
          _mediaControllers[w.id] = VideoControllerHolder(src)
            ..initialize().then((_) {
              if (mounted) setState(() {});
            });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageW = widget.page.pageSizeX.toDouble();
    final pageH = widget.page.pageSizeY.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : pageW;
        final scale = availableWidth / pageW;
        final displayWidth = pageW * scale;
        final displayHeight = pageH * scale;

        return GestureDetector(
          onTap: () {
            widget.onSelectionChanged?.call(null);
            setState(() => _editingWidgetId = null);
            FocusScope.of(context).unfocus();
          },
          child: Container(
            width: displayWidth,
            height: displayHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ...widget.page.widgets.map(
                  (w) => _buildWidgetOnCanvas(w, scale),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWidgetOnCanvas(WidgetModel w, double scale) {
    final isSelected = widget.selectedWidgetId == w.id;
    final isEditing = _editingWidgetId == w.id;

    return Positioned(
      key: ValueKey(w.id),
      left: w.x * scale,
      top: w.y * scale,
      width: w.width * scale,
      height: w.height * scale,
      child: GestureDetector(
        onTap: () {
          widget.onSelectionChanged?.call(w.id);
          if (_editingWidgetId != w.id) {
            setState(() => _editingWidgetId = null);
            FocusScope.of(context).unfocus();
          }
        },
        onDoubleTap: () {
          if (w.type.toLowerCase() == 'text') {
            setState(() => _editingWidgetId = w.id);
            widget.onSelectionChanged?.call(w.id);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Content
            Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 1.5),
                    )
                  : null,
              child: _WidgetContent(
                widgetModel: w,
                controllerHolder: _mediaControllers[w.id],
                isEditing: isEditing,
                onTextChange: (val) {
                  widget.onUpdateWidget?.call(w.id, {'text': val});
                },
              ),
            ),
            if (isSelected) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (d) {
                    widget.onMoveWidget?.call(
                      w.id,
                      w.x + (d.delta.dx / scale),
                      w.y + (d.delta.dy / scale),
                    );
                  },
                ),
              ),
              Positioned(
                right: -6,
                bottom: -6,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    final newW = w.width + (d.delta.dx / scale);
                    final newH = w.height + (d.delta.dy / scale);
                    widget.onResizeWidget?.call(
                      w.id,
                      newW < 20 ? 20 : newW,
                      newH < 20 ? 20 : newH,
                    );
                  },
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blueAccent),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WidgetContent extends StatefulWidget {
  final WidgetModel widgetModel;
  final VideoControllerHolder? controllerHolder;
  final bool isEditing;
  final ValueChanged<String>? onTextChange;

  const _WidgetContent({
    Key? key,
    required this.widgetModel,
    this.controllerHolder,
    this.isEditing = false,
    this.onTextChange,
  }) : super(key: key);

  @override
  State<_WidgetContent> createState() => _WidgetContentState();
}

class _WidgetContentState extends State<_WidgetContent> {
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
      text: widget.widgetModel.properties['text'] ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _WidgetContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEditing &&
        widget.widgetModel.properties['text'] != _textCtrl.text) {
      _textCtrl.text = widget.widgetModel.properties['text'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.widgetModel.type.toLowerCase();
    final props = widget.widgetModel.properties;

    switch (type) {
      case 'text':
        return _buildText(props);
      case 'image':
        return _buildImage(props);
      case 'video':
        return _buildVideo();
      case 'audio':
        return _buildAudio();
      case '3d':
        return _build3D();
      default:
        return _buildPlaceholder(type);
    }
  }

  Widget _buildText(Map<String, dynamic> props) {
    final fontSize = (props['fontSize'] as num?)?.toDouble() ?? 16.0;
    final colorHex = props['color'] as String? ?? '#000000';
    final bgHex = props['backgroundColor'] as String?;
    final isBold = props['isBold'] == true;
    final isItalic = props['isItalic'] == true;
    final isUnderline = props['isUnderline'] == true;

    final textColor = _hexToColor(colorHex);
    final bgColor = _hexToColor(bgHex);

    final style = TextStyle(
      fontSize: fontSize,
      color: textColor,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
      fontFamily: 'Roboto',
    );

    if (widget.isEditing) {
      return Container(
        color: bgColor == Colors.transparent
            ? Colors.white.withOpacity(0.9)
            : bgColor,
        padding: EdgeInsets.all(4),
        child: TextField(
          controller: _textCtrl,
          autofocus: true,
          style: style,
          maxLines: null,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onTextChange,
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.all(4),
      child: Text(props['text'] ?? 'Text', style: style),
    );
  }

  Widget _buildImage(Map<String, dynamic> props) {
    final src = props['src'] as String?;
    if (src == null) return _buildPlaceholder('Image');
    return Image.network(
      src,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder('Error'),
    );
  }

  Widget _buildVideo() {
    final holder = widget.controllerHolder;
    if (holder != null && holder.hasError)
      return _buildPlaceholder('Video Error');
    if (holder == null || !holder.isInitialized)
      return Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: holder.controller!.value.size.width,
              height: holder.controller!.value.size.height,
              child: VideoPlayer(holder.controller!),
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                holder.controller!.value.isPlaying
                    ? holder.controller!.pause()
                    : holder.controller!.play();
              });
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: Icon(
                holder.controller!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudio() {
    final holder = widget.controllerHolder;

    if (holder != null && holder.hasError) {
      return Container(
        color: Colors.red[50],
        child: Center(child: Icon(Icons.error, color: Colors.red)),
      );
    }

    final isPlaying = holder?.controller?.value.isPlaying ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, color: Colors.blueAccent),
          const SizedBox(width: 8),
          if (holder == null || !holder.isInitialized)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
              ),
              color: Colors.blueAccent,
              iconSize: 32,
              onPressed: () {
                setState(() {
                  isPlaying
                      ? holder!.controller!.pause()
                      : holder!.controller!.play();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _build3D() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Icon(Icons.view_in_ar, size: 40, color: Colors.white),
      ),
    );
  }

  Widget _buildPlaceholder(String text) => Container(
    color: Colors.grey[300],
    child: Center(
      child: Text(text, style: TextStyle(color: Colors.grey)),
    ),
  );
}

class VideoControllerHolder {
  final String url;
  VideoPlayerController? controller;
  bool isInitialized = false;
  bool hasError = false;
  VideoControllerHolder(this.url);
  Future<void> initialize() async {
    try {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller!.initialize();
      isInitialized = true;
    } catch (_) {
      hasError = true;
    }
  }

  void dispose() {
    controller?.dispose();
  }
}

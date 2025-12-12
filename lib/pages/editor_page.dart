import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../blocs/editor/editor_bloc.dart';
import '../blocs/editor/editor_event.dart';
import '../blocs/editor/editor_state.dart';
import '../models/page_model.dart';
import '../models/widget_model.dart';
import '../widgets/canvas/a4_canvas.dart';
import 'preview_page.dart';

const String supabaseBucket = 'book-media';

class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  String? activePageId;
  String? selectedWidgetId;
  bool oneColumnLayout = true;
  final ItemScrollController mainScroll = ItemScrollController();

  @override
  void initState() {
    super.initState();
    _initBook();
  }

  void _initBook() {
    final page = PageModel(id: 'page-1', pageTitle: 'Page 1', widgets: []);
    context.read<EditorBloc>().add(LoadBook([page]));
    activePageId = page.id;
  }

  PageModel? _currentPage() {
    final state = context.read<EditorBloc>().state;
    if (state is EditorLoaded && activePageId != null) {
      try {
        return state.pages.firstWhere((p) => p.id == activePageId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  WidgetModel? _selectedWidget() {
    final page = _currentPage();
    if (page != null && selectedWidgetId != null) {
      try {
        return page.widgets.firstWhere((w) => w.id == selectedWidgetId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BlocConsumer<EditorBloc, EditorState>(
        listener: (context, state) {
          if (state is EditorLoaded && state.message != null) {
            _saveBookJsonToFile(state.message!);
          }
        },
        builder: (context, state) {
          if (state is! EditorLoaded)
            return Center(child: CircularProgressIndicator());

          return Row(
            children: [
              Container(
                width: 280,
                color: Colors.white,
                child: _leftBar(context, state),
              ),
              VerticalDivider(width: 1, color: Colors.grey[300]),
              Expanded(child: _centerCanvas(context, state)),
              VerticalDivider(width: 1, color: Colors.grey[300]),
              Container(
                width: 240,
                color: Colors.white,
                child: _rightPreview(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _leftBar(BuildContext context, EditorLoaded state) {
    final sel = _selectedWidget();

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text(
          "Editor Tools",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 24),
        Text(
          "Page Layout",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        _layoutToggle(),
        SizedBox(height: 24),

        if (sel != null) ...[
          if (sel.type.toLowerCase() == 'text') ...[
            Text(
              "Text tool",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            _textTools(sel),
            SizedBox(height: 24),
          ],
          Text(
            "Position",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          _positionTools(sel),
          SizedBox(height: 24),
          Text(
            "Actions",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          _actionButtons(sel),
        ] else ...[
          Text(
            "Select an element to edit properties.",
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
        ],

        Divider(),
        SizedBox(height: 16),
        Text(
          "Add Content",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12),
        _bigMenuButton(
          "Import Image",
          Icons.image_outlined,
          () => _addMedia(context, 'Image'),
        ),
        SizedBox(height: 12),
        _bigMenuButton(
          "Add Video",
          Icons.movie_outlined,
          () => _addMedia(context, 'Video'),
        ),
        SizedBox(height: 12),
        _bigMenuButton(
          "Add Audio",
          Icons.audiotrack_outlined,
          () => _addMedia(context, 'Audio'),
        ),
        SizedBox(height: 12),
        _bigMenuButton("Add Text", Icons.text_fields, () => _addText(context)),
        SizedBox(height: 24),
        Text(
          "Live data",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12),
        _bigMenuButton(
          "Weather",
          Icons.cloud_outlined,
          () => _addLive(context, 'Weather'),
        ),
        SizedBox(height: 12),
        _bigMenuButton(
          "Live location",
          Icons.location_on_outlined,
          () => _addLive(context, 'Location'),
        ),
      ],
    );
  }

  Widget _layoutToggle() {
    return Column(
      children: [
        _radioTile(
          "One column",
          oneColumnLayout,
          () => setState(() => oneColumnLayout = true),
        ),
        _radioTile(
          "Two columns",
          !oneColumnLayout,
          () => setState(() => oneColumnLayout = false),
        ),
      ],
    );
  }

  Widget _radioTile(String title, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.black : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.view_agenda : Icons.view_agenda_outlined,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _textTools(WidgetModel widget) {
    final props = widget.properties;
    final double fontSize = (props['fontSize'] as num?)?.toDouble() ?? 16.0;
    final bool isBold = props['isBold'] == true;
    final bool isItalic = props['isItalic'] == true;
    final bool isUnderline = props['isUnderline'] == true;
    final String colorHex = props['color'] as String? ?? '#000000';
    final String fontFamily = props['fontFamily'] as String? ?? 'Roboto';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _dropdown(
                getHeadingLabelFromSize(fontSize),
                ["Heading 1", "Heading 2", "Heading 3", "Paragraph"],
                (v) {
                  double newSize = 16.0;
                  if (v == "Heading 1") newSize = 32.0;
                  if (v == "Heading 2") newSize = 24.0;
                  if (v == "Heading 3") newSize = 20.0;
                  _updateWidgetProperty(widget, 'fontSize', newSize);
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _dropdown(
                fontFamily,
                ["Roboto", "Open Sans", "Lato", "Oswald", "Montserrat", "Lora"],
                (v) {
                  if (v != null) _updateWidgetProperty(widget, 'fontFamily', v);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _smallIconButton(
              Icons.remove,
              () => _updateWidgetProperty(widget, 'fontSize', fontSize - 1),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                "${fontSize.toInt()}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _smallIconButton(
              Icons.add,
              () => _updateWidgetProperty(widget, 'fontSize', fontSize + 1),
            ),
            Spacer(),
            _toggleIcon(Icons.format_align_left, true),
            _toggleIcon(Icons.format_align_center, false),
            _toggleIcon(Icons.format_align_right, false),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _toggleIcon(
              Icons.format_bold,
              isBold,
              onTap: () => _updateWidgetProperty(widget, 'isBold', !isBold),
            ),
            _toggleIcon(
              Icons.format_italic,
              isItalic,
              onTap: () => _updateWidgetProperty(widget, 'isItalic', !isItalic),
            ),
            _toggleIcon(
              Icons.format_underline,
              isUnderline,
              onTap: () =>
                  _updateWidgetProperty(widget, 'isUnderline', !isUnderline),
            ),
            Spacer(),
            GestureDetector(
              onTap: () => _showColorPicker(context, widget, 'color'),
              child: Container(
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: _hexToColor(colorHex),
                    ),
                    SizedBox(width: 4),
                    Text(
                      colorHex.replaceAll('#', '').substring(0, 3),
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Text("100%", style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _positionTools(WidgetModel widget) {
    return Row(
      children: [
        _smallIconButton(
          Icons.align_horizontal_left,
          () => _alignWidget(widget, 'left'),
        ),
        _smallIconButton(
          Icons.align_horizontal_center,
          () => _alignWidget(widget, 'center_h'),
        ),
        _smallIconButton(
          Icons.align_horizontal_right,
          () => _alignWidget(widget, 'right'),
        ),
        SizedBox(width: 8),
        _smallIconButton(
          Icons.vertical_align_top,
          () => _alignWidget(widget, 'top'),
        ),
        _smallIconButton(
          Icons.vertical_align_center,
          () => _alignWidget(widget, 'center_v'),
        ),
        _smallIconButton(
          Icons.vertical_align_bottom,
          () => _alignWidget(widget, 'bottom'),
        ),
      ],
    );
  }

  Widget _actionButtons(WidgetModel widget) {
    return Column(
      children: [
        Row(
          children: [
            _textAction(
              Icons.flip_to_front,
              "To Front",
              () => _widgetAction(widget.id, 'front'),
            ),
            _textAction(
              Icons.flip_to_back,
              "To Back",
              () => _widgetAction(widget.id, 'back'),
            ),
          ],
        ),
        _textAction(
          Icons.delete_outline,
          "Delete",
          () => _widgetAction(widget.id, 'delete'),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _centerCanvas(BuildContext context, EditorLoaded state) {
    if (state.pages.isEmpty)
      return Center(child: Text("No pages. Click 'Add Page' to start."));

    final double horizontal = oneColumnLayout ? 20.0 : 80.0;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: mainScroll.scrollController,
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: horizontal),
            itemCount: state.pages.length,
            separatorBuilder: (ctx, i) => SizedBox(height: 40),
            itemBuilder: (ctx, i) {
              final page = state.pages[i];
              return _editablePage(page, i, context);
            },
          ),
        ),
        _bottomBar(context),
      ],
    );
  }

  Widget _editablePage(PageModel page, int index, BuildContext context) {
    final isActive = activePageId == page.id;

    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => activePageId = page.id),
          child: Container(
            decoration: BoxDecoration(
              border: isActive
                  ? Border.all(color: Colors.blue.withOpacity(0.3), width: 2)
                  : null,
            ),
            child: A4Canvas(
              page: page,
              selectedWidgetId: isActive ? selectedWidgetId : null,
              onSelectionChanged: (wid) => setState(() {
                activePageId = page.id;
                selectedWidgetId = wid;
              }),
              onMoveWidget: (wid, x, y) => context.read<EditorBloc>().add(
                MoveWidgetEvent(page.id, wid, x, y),
              ),
              onResizeWidget: (wid, w, h) => context.read<EditorBloc>().add(
                UpdateWidgetEvent(page.id, wid, {'width': w, 'height': h}),
              ),
              onUpdateWidget: (wid, props) => context.read<EditorBloc>().add(
                UpdateWidgetEvent(page.id, wid, props),
              ),
              onWidgetAction: (wid, action) {
                if (action == 'delete') {
                  context.read<EditorBloc>().add(
                    DeleteWidgetEvent(page.id, wid),
                  );
                  setState(() => selectedWidgetId = null);
                } else {
                  context.read<EditorBloc>().add(
                    ChangeWidgetOrderEvent(page.id, wid, action),
                  );
                }
              },
            ),
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${index + 1}",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: FilledButton.icon(
        onPressed: () => context.read<EditorBloc>().add(AddPageEvent()),
        icon: Icon(Icons.add, size: 16),
        label: Text("Add Page"),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _rightPreview(BuildContext context, EditorLoaded state) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<EditorBloc>().add(const SaveBookEvent()),
                  icon: Icon(Icons.download, size: 16),
                  label: Text("Export"),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => PreviewPage(
                        pages: state.pages,
                        onExport: () => context.read<EditorBloc>().add(
                          const SaveBookEvent(),
                        ),
                      ),
                    ),
                  ),
                  icon: Icon(Icons.play_arrow, size: 16),
                  label: Text("Preview"),
                ),
              ),
            ],
          ),
        ),
        Divider(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: state.pages.length,
            itemBuilder: (ctx, i) => _pageThumb(state.pages[i], i),
          ),
        ),
      ],
    );
  }

  Widget _pageThumb(PageModel page, int index) {
    final isActive = activePageId == page.id;

    return GestureDetector(
      onTap: () => _scrollToPage(index, page.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.pageTitle,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? Colors.blue : Colors.grey[200]!,
                width: isActive ? 2 : 1,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: page.pageSizeX.toDouble(),
                height: page.pageSizeY.toDouble(),
                child: AbsorbPointer(child: A4Canvas(page: page)),
              ),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _dropdown(
    String current,
    List<String> options,
    Function(String?) onChanged,
  ) {
    final safe = options.contains(current) ? current : options.first;
    return Container(
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: safe,
        items: options
            .map(
              (o) => DropdownMenuItem(
                value: o,
                child: Text(o, style: TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
        onChanged: onChanged,
        underline: SizedBox(),
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _smallIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: Colors.black54),
      ),
    );
  }

  Widget _toggleIcon(IconData icon, bool active, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: active ? Colors.black12 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.black : Colors.black54,
        ),
      ),
    );
  }

  Widget _bigMenuButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black54),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.black54,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  void _scrollToPage(int index, String pageId) {
    setState(() => activePageId = pageId);
    if (mainScroll.scrollController.hasClients) {
      final position = index * 850.0;
      mainScroll.scrollController.animateTo(
        position,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateWidgetProperty(WidgetModel widget, String key, dynamic value) {
    if (activePageId == null) return;
    context.read<EditorBloc>().add(
      UpdateWidgetEvent(activePageId!, widget.id, {key: value}),
    );
  }

  void _widgetAction(String widgetId, String actionType) {
    if (activePageId == null) return;
    if (actionType == 'delete') {
      context.read<EditorBloc>().add(
        DeleteWidgetEvent(activePageId!, widgetId),
      );
      setState(() => selectedWidgetId = null);
    } else {
      context.read<EditorBloc>().add(
        ChangeWidgetOrderEvent(activePageId!, widgetId, actionType),
      );
    }
  }

  void _alignWidget(WidgetModel widget, String align) {
    final page = _currentPage();
    if (page == null) return;
    double pw = page.pageSizeX.toDouble();
    double ph = page.pageSizeY.toDouble();
    double nx = widget.x;
    double ny = widget.y;

    if (align == 'left') nx = 0;
    if (align == 'center_h') nx = (pw - widget.width) / 2;
    if (align == 'right') nx = pw - widget.width;
    if (align == 'top') ny = 0;
    if (align == 'center_v') ny = (ph - widget.height) / 2;
    if (align == 'bottom') ny = ph - widget.height;

    context.read<EditorBloc>().add(
      UpdateWidgetEvent(activePageId!, widget.id, {'x': nx, 'y': ny}),
    );
  }

  void _addText(BuildContext context) {
    if (activePageId == null) return;
    context.read<EditorBloc>().add(
      AddWidgetEvent(
        activePageId!,
        WidgetModel(
          type: 'Text',
          properties: {
            'text': 'Type something here...',
            'fontSize': 20,
            'color': '#000000',
          },
          xPosition: 50,
          yPosition: 50,
          width: 400,
          height: 60,
        ),
      ),
    );
  }

  Future<void> _addLive(BuildContext context, String type) async {
    if (activePageId == null) return;
    String text = 'Live Data';
    String icon = '';
    if (type == 'Weather') {
      text = ' 24°C Chennai';
      icon = '⛅';
    }
    if (type == 'Location') {
      text = ' New York, USA';
      icon = '📍';
    }

    context.read<EditorBloc>().add(
      AddWidgetEvent(
        activePageId!,
        WidgetModel(
          type: 'Text',
          properties: {
            'text': '$icon$text',
            'fontSize': 18,
            'color': '#000000',
            'backgroundColor': '#EEEEEE',
          },
          xPosition: 50,
          yPosition: 50,
          width: 200,
          height: 50,
        ),
      ),
    );
  }

  Future<void> _addMedia(BuildContext context, String type) async {
    if (activePageId == null) return;
    FileType picker = FileType.any;
    String folder = 'files';
    if (type == 'Image') {
      picker = FileType.image;
      folder = 'images';
    }
    if (type == 'Video') {
      picker = FileType.video;
      folder = 'videos';
    }
    if (type == 'Audio') {
      picker = FileType.audio;
      folder = 'audio';
    }

    final result = await FilePicker.platform.pickFiles(
      type: picker,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final newWidget = WidgetModel(
        type: type,
        properties: {},
        xPosition: 100,
        yPosition: 100,
        width: 300,
        height: 200,
      );
      context.read<EditorBloc>().add(AddWidgetEvent(activePageId!, newWidget));
      final ext = file.extension != null ? '.${file.extension}' : '';
      if (file.bytes != null) {
        context.read<EditorBloc>().add(
          UploadMediaEvent(
            pageId: activePageId!,
            widgetId: newWidget.id,
            bucket: supabaseBucket,
            path: '$folder/${newWidget.id}$ext',
            bytes: file.bytes!,
          ),
        );
      }
    }
  }

  void _showColorPicker(BuildContext context, WidgetModel widget, String key) {
    Color selected = _hexToColor(widget.properties[key]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selected,
            onColorChanged: (c) => selected = c,
            enableAlpha: false,
            paletteType: PaletteType.hsvWithHue,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final hex =
                  '#${selected.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              _updateWidgetProperty(widget, key, hex);
              Navigator.pop(ctx);
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(dynamic hexCode) {
    if (hexCode == null) return Colors.black;
    try {
      String s = (hexCode as String).replaceAll('#', '');
      if (s.length == 6) s = 'FF$s';
      return Color(int.parse(s, radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }

  String getHeadingLabelFromSize(double size) {
    if (size >= 32) return 'Heading 1';
    if (size >= 24) return 'Heading 2';
    if (size >= 20) return 'Heading 3';
    return 'Paragraph';
  }

  Future<void> _saveBookJsonToFile(String jsonContent) async {
    try {
      final outputFilePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Book JSON',
        fileName: 'my_book.json',
      );
      if (outputFilePath != null) {
        final f = File(outputFilePath);
        await f.writeAsString(jsonContent);
        if (mounted) _showSuccess(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  void _showSuccess(BuildContext context) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: MediaQuery.of(context).size.width * 0.3,
        right: MediaQuery.of(context).size.width * 0.3,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Color(0xFFE8FDF0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF22C55E)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 28),
                SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 18, color: Color(0xFF15803D)),
                    children: [
                      TextSpan(text: 'File exported successfully as '),
                      TextSpan(
                        text: 'JSON',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    Future.delayed(Duration(seconds: 3), () {
      entry?.remove();
    });
  }
}

class ItemScrollController {
  final ScrollController scrollController = ScrollController();
}

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/page_model.dart';
import '../../services/supabase_service.dart';
import 'editor_event.dart';
import 'editor_state.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final SupabaseService _supabaseService = SupabaseService();
  final _uuid = const Uuid();

  EditorBloc() : super(EditorInitial()) {
    on<LoadBook>(_onLoadBook);
    on<AddPageEvent>(_onAddPage);
    on<RemovePageEvent>(_onRemovePage);
    on<ReorderPageEvent>(_onReorderPage);
    on<AddWidgetEvent>(_onAddWidget);
    on<MoveWidgetEvent>(_onMoveWidget);
    on<UpdateWidgetEvent>(_onUpdateWidget);
    on<DeleteWidgetEvent>(_onDeleteWidget);
    on<ChangeWidgetOrderEvent>(_onChangeWidgetOrder);
    on<UploadMediaEvent>(_onUploadMedia);
    on<SaveBookEvent>(_onSaveBook);
  }

  void _onLoadBook(LoadBook event, Emitter<EditorState> emit) {
    emit(EditorLoaded(event.pages));
  }

  void _onAddPage(AddPageEvent event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final newPage = PageModel(
        id: _uuid.v4(),
        pageTitle: 'Page ${currentState.pages.length + 1}',
        widgets: [],
      );
      emit(EditorLoaded([...currentState.pages, newPage]));
    }
  }

  void _onRemovePage(RemovePageEvent event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final updatedList = currentState.pages
          .where((p) => p.id != event.pageId)
          .toList();
      emit(EditorLoaded(updatedList));
    }
  }

  void _onReorderPage(ReorderPageEvent event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final mutablePages = List<PageModel>.from(currentState.pages);
      final movedPage = mutablePages.removeAt(event.oldIndex);
      mutablePages.insert(event.newIndex, movedPage);
      emit(EditorLoaded(mutablePages));
    }
  }

  List<PageModel> _applyToPage(
    List<PageModel> pages,
    String pageId,
    PageModel Function(PageModel) modifier,
  ) {
    return pages
        .map((page) => page.id == pageId ? modifier(page) : page)
        .toList();
  }

  void _onAddWidget(AddWidgetEvent event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final updatedPages = _applyToPage(currentState.pages, event.pageId, (
        page,
      ) {
        return page.copyWith(widgets: [...page.widgets, event.widget]);
      });
      emit(EditorLoaded(updatedPages));
    }
  }

  void _onMoveWidget(MoveWidgetEvent event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final updatedPages = _applyToPage(currentState.pages, event.pageId, (
        page,
      ) {
        final updatedWidgets = page.widgets.map((widget) {
          if (widget.id == event.widgetId) {
            return widget.copyWith(x: event.x, y: event.y);
          }
          return widget;
        }).toList();
        return page.copyWith(widgets: updatedWidgets);
      });
      emit(EditorLoaded(updatedPages));
    }
  }

  void _onUpdateWidget(UpdateWidgetEvent event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final updatedPages = _applyToPage(currentState.pages, event.pageId, (
        page,
      ) {
        final updatedWidgets = page.widgets.map((widget) {
          if (widget.id == event.widgetId) {
            // Logic to merge properties carefully
            final newProps = Map<String, dynamic>.from(widget.properties);

            double? newWidth = widget.width;
            double? newHeight = widget.height;
            double? newX = widget.x;
            double? newY = widget.y;

            event.changes.forEach((key, value) {
              if (key == 'width')
                newWidth = (value as num).toDouble();
              else if (key == 'height')
                newHeight = (value as num).toDouble();
              else if (key == 'x')
                newX = (value as num).toDouble();
              else if (key == 'y')
                newY = (value as num).toDouble();
              else
                newProps[key] = value;
            });

            return widget.copyWith(
              width: newWidth,
              height: newHeight,
              x: newX,
              y: newY,
              properties: newProps,
            );
          }
          return widget;
        }).toList();
        return page.copyWith(widgets: updatedWidgets);
      });
      emit(EditorLoaded(updatedPages));
    }
  }

  void _onDeleteWidget(DeleteWidgetEvent event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final updatedPages = _applyToPage(currentState.pages, event.pageId, (
        page,
      ) {
        // Filter out the widget with the given ID
        final remainingWidgets = page.widgets
            .where((w) => w.id != event.widgetId)
            .toList();
        return page.copyWith(widgets: remainingWidgets);
      });
      emit(EditorLoaded(updatedPages));
    }
  }

  void _onChangeWidgetOrder(
    ChangeWidgetOrderEvent event,
    Emitter<EditorState> emit,
  ) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final updatedPages = _applyToPage(currentState.pages, event.pageId, (
        page,
      ) {
        final index = page.widgets.indexWhere((w) => w.id == event.widgetId);
        if (index == -1) return page;

        final targetWidget = page.widgets[index];
        final widgetList = List.of(page.widgets);
        widgetList.removeAt(index);
        if (event.action == 'front') {
          widgetList.add(targetWidget);
        } else if (event.action == 'back') {
          widgetList.insert(0, targetWidget);
        }

        return page.copyWith(widgets: widgetList);
      });
      emit(EditorLoaded(updatedPages));
    }
  }

  Future<void> _onUploadMedia(
    UploadMediaEvent event,
    Emitter<EditorState> emit,
  ) async {
    if (state is! EditorLoaded) return;
    try {
      final publicUrl = await _supabaseService.uploadBytes(
        bucket: event.bucket,
        path: event.path,
        bytes: event.bytes,
      );
      add(UpdateWidgetEvent(event.pageId, event.widgetId, {'src': publicUrl}));
    } catch (e) {
      emit(EditorError("Upload failed: $e"));
    }
  }

  void _onSaveBook(SaveBookEvent event, Emitter<EditorState> emit) {
    if (state is EditorLoaded) {
      final currentState = state as EditorLoaded;
      final jsonOutput = jsonEncode(
        currentState.pages.map((p) => p.toJson()).toList(),
      );
      emit(EditorLoaded(currentState.pages, message: jsonOutput));
    }
  }
}

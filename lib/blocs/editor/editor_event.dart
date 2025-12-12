import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../models/page_model.dart';
import '../../models/widget_model.dart';

abstract class EditorEvent extends Equatable {
  const EditorEvent();
  @override
  List<Object?> get props => [];
}

class LoadBook extends EditorEvent {
  final List<PageModel> pages;
  const LoadBook(this.pages);
}

class AddPageEvent extends EditorEvent {}

class RemovePageEvent extends EditorEvent {
  final String pageId;
  const RemovePageEvent(this.pageId);
}

class ReorderPageEvent extends EditorEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderPageEvent(this.oldIndex, this.newIndex);
}

class AddWidgetEvent extends EditorEvent {
  final String pageId;
  final WidgetModel widget;
  const AddWidgetEvent(this.pageId, this.widget);
}

class MoveWidgetEvent extends EditorEvent {
  final String pageId;
  final String widgetId;
  final double x;
  final double y;
  const MoveWidgetEvent(this.pageId, this.widgetId, this.x, this.y);
}

class UpdateWidgetEvent extends EditorEvent {
  final String pageId;
  final String widgetId;
  final Map<String, dynamic> changes;
  const UpdateWidgetEvent(this.pageId, this.widgetId, this.changes);
}

class DeleteWidgetEvent extends EditorEvent {
  final String pageId;
  final String widgetId;
  const DeleteWidgetEvent(this.pageId, this.widgetId);
}

class ChangeWidgetOrderEvent extends EditorEvent {
  final String pageId;
  final String widgetId;
  final String action; // 'front', 'back'
  const ChangeWidgetOrderEvent(this.pageId, this.widgetId, this.action);
}

class UploadMediaEvent extends EditorEvent {
  final String pageId;
  final String widgetId;
  final String bucket;
  final String path;
  final Uint8List bytes;

  const UploadMediaEvent({
    required this.pageId,
    required this.widgetId,
    required this.bucket,
    required this.path,
    required this.bytes,
  });
}

class SaveBookEvent extends EditorEvent {
  const SaveBookEvent();
}

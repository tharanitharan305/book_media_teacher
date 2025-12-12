import 'package:equatable/equatable.dart';
import '../../models/page_model.dart';

abstract class EditorState extends Equatable {
  const EditorState();

  @override
  List<Object?> get props => [];
}

class EditorInitial extends EditorState {}

class EditorLoading extends EditorState {}

class EditorLoaded extends EditorState {
  final List<PageModel> pages;
  final String? message;

  const EditorLoaded(this.pages, {this.message});

  @override
  List<Object?> get props => [pages, message];
}

class EditorError extends EditorState {
  final String error;

  const EditorError(this.error);

  @override
  List<Object?> get props => [error];
}

class UploadInProgress extends EditorState {
  final double progress;
  const UploadInProgress({this.progress = 0.0});
}

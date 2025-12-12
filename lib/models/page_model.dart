import 'package:equatable/equatable.dart';
import 'widget_model.dart';

class PageModel extends Equatable {
  final String id;
  final String pageTitle;
  final int pageSizeX;
  final int pageSizeY;
  final String orientation;
  final List<WidgetModel> widgets;

  PageModel({
    required this.id,
    required this.pageTitle,
    this.pageSizeX = 800,
    this.pageSizeY = 1000,
    this.orientation = 'portrait',
    required this.widgets,
  });

  PageModel copyWith({
    String? id,
    String? pageTitle,
    int? pageSizeX,
    int? pageSizeY,
    String? orientation,
    List<WidgetModel>? widgets,
  }) {
    return PageModel(
      id: id ?? this.id,
      pageTitle: pageTitle ?? this.pageTitle,
      pageSizeX: pageSizeX ?? this.pageSizeX,
      pageSizeY: pageSizeY ?? this.pageSizeY,
      orientation: orientation ?? this.orientation,
      widgets: widgets ?? this.widgets,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageTitle': pageTitle,
    'page_size_X': pageSizeX,
    'page_size_Y': pageSizeY,
    'orientation': orientation,
    'widgets': widgets.map((w) => w.toJson()).toList(),
  };

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'],
      pageTitle: json['pageTitle'],
      pageSizeX: json['page_size_X'] ?? 800,
      pageSizeY: json['page_size_Y'] ?? 1000,
      orientation: json['orientation'] ?? 'portrait',
      widgets: (json['widgets'] as List<dynamic>? ?? [])
          .map((w) => WidgetModel.fromJson(Map<String, dynamic>.from(w)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    pageTitle,
    pageSizeX,
    pageSizeY,
    orientation,
    widgets,
  ];
}

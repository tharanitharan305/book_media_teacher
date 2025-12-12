import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

final _uuidGenerator = Uuid();

class WidgetModel extends Equatable {
  final String id;
  final String type;
  final Map<String, dynamic> properties;
  final double xPosition;
  final double yPosition;
  final double width;
  final double height;

  WidgetModel({
    String? id,
    required this.type,
    required this.properties,
    this.xPosition = 0,
    this.yPosition = 0,
    this.width = 200,
    this.height = 100,
  }) : id = id ?? _uuidGenerator.v4();
  double get x => xPosition;
  double get y => yPosition;

  WidgetModel copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? properties,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return WidgetModel(
      id: id ?? this.id,
      type: type ?? this.type,
      properties: properties ?? this.properties,
      xPosition: x ?? this.xPosition,
      yPosition: y ?? this.yPosition,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'properties': properties,
    'x': xPosition,
    'y': yPosition,
    'width': width,
    'height': height,
  };

  factory WidgetModel.fromJson(Map<String, dynamic> json) {
    return WidgetModel(
      id: json['id'],
      type: json['type'],
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      xPosition: (json['x'] ?? 0).toDouble(),
      yPosition: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 200).toDouble(),
      height: (json['height'] ?? 100).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    properties,
    xPosition,
    yPosition,
    width,
    height,
  ];
}

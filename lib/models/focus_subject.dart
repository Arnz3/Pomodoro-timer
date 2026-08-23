import 'package:flutter/material.dart';

class FocusSubject {
  final String id;
  String name;
  Color color;

  FocusSubject({required this.id, required this.name, required this.color});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
  };

  factory FocusSubject.fromJson(Map<String, dynamic> json) => FocusSubject(
    id: json['id'] as String,
    name: json['name'] as String,
    color: Color(json['color'] as int),
  );
}

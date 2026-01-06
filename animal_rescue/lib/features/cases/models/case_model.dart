import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'case_model.g.dart';

@JsonSerializable()
class CaseUser {
  final String id;
  final String name;
  final String email;

  CaseUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory CaseUser.fromJson(Map<String, dynamic> json) =>
      _$CaseUserFromJson(json);
  Map<String, dynamic> toJson() => _$CaseUserToJson(this);
}

@JsonSerializable()
class AnimalCase {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? severity;
  final String status;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final DateTime createdAt;
  final CaseUser reportedBy;
  final CaseUser? assignedNgo;

  AnimalCase({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.createdAt,
    required this.reportedBy,
    this.assignedNgo,
  });

  factory AnimalCase.fromJson(Map<String, dynamic> json) =>
      _$AnimalCaseFromJson(json);
  Map<String, dynamic> toJson() => _$AnimalCaseToJson(this);

  AnimalCase copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? severity,
    String? status,
    double? latitude,
    double? longitude,
    String? imageUrl,
    DateTime? createdAt,
    CaseUser? reportedBy,
    CaseUser? assignedNgo,
  }) {
    return AnimalCase(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      reportedBy: reportedBy ?? this.reportedBy,
      assignedNgo: assignedNgo ?? this.assignedNgo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimalCase && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AnimalCase(id: $id, title: $title, type: $type, severity: $severity, status: $status)';
  }
}

enum CaseSeverity {
  critical('Critical', Colors.red),
  urgent('Urgent', Colors.orange),
  moderate('Moderate', Colors.yellow),
  low('Low', Colors.green);

  const CaseSeverity(this.label, this.color);
  final String label;
  final Color color;
}

enum CaseStatus {
  reported('Reported', Colors.blue),
  inProgress('In Progress', Colors.orange),
  resolved('Resolved', Colors.green),
  closed('Closed', Colors.grey);

  const CaseStatus(this.label, this.color);
  final String label;
  final Color color;
}

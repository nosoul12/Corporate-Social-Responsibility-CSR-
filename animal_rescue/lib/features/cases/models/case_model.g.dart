// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'case_model.dart';

// ************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaseUser _$CaseUserFromJson(Map<String, dynamic> json) => CaseUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$CaseUserToJson(CaseUser instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };

AnimalCase _$AnimalCaseFromJson(Map<String, dynamic> json) => AnimalCase(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      severity: json['severity'] as String?,
      status: json['status'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reportedBy: CaseUser.fromJson(json['reportedBy'] as Map<String, dynamic>),
      assignedNgo: json['assignedNgo'] == null
          ? null
          : CaseUser.fromJson(json['assignedNgo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AnimalCaseToJson(AnimalCase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': instance.type,
      'severity': instance.severity,
      'status': instance.status,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'imageUrl': instance.imageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'reportedBy': instance.reportedBy.toJson(),
      'assignedNgo': instance.assignedNgo?.toJson(),
    };

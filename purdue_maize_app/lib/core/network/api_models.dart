// Modelos de respuesta del API usados por el cliente Retrofit.
// Espejo de los Pydantic schemas del backend.

class ApiLoginResult {
  final String token;
  final String userId;
  final String email;
  final String fullName;

  const ApiLoginResult({
    required this.token,
    required this.userId,
    required this.email,
    required this.fullName,
  });
}

class ApiDisease {
  final int id;
  final String name;
  final String? commonName;
  final String? pathogen;
  final String? pathogenType;
  final String crop;

  const ApiDisease({
    required this.id,
    required this.name,
    this.commonName,
    this.pathogen,
    this.pathogenType,
    this.crop = 'maize',
  });

  factory ApiDisease.fromJson(Map<String, dynamic> j) => ApiDisease(
        id: j['id'] as int,
        name: j['name'] as String,
        commonName: j['common_name'] as String?,
        pathogen: j['pathogen'] as String?,
        pathogenType: j['pathogen_type'] as String?,
        crop: j['crop'] as String? ?? 'maize',
      );
}

class ApiPointCoords {
  final double latitude;
  final double longitude;
  final double? altitudeM;

  const ApiPointCoords({required this.latitude, required this.longitude, this.altitudeM});

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (altitudeM != null) 'altitude_m': altitudeM,
      };
}

class ApiSamplingPointCreate {
  final String? pointCode;
  final ApiPointCoords location;
  final String recordedAt; // ISO8601
  final String syncStatus;

  const ApiSamplingPointCreate({
    this.pointCode,
    required this.location,
    required this.recordedAt,
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toJson() => {
        if (pointCode != null) 'point_code': pointCode,
        'location': location.toJson(),
        'recorded_at': recordedAt,
        'sync_status': syncStatus,
      };
}

class ApiSamplingSessionCreate {
  final String fieldId;
  final String samplingType;
  final String sessionDate; // YYYY-MM-DD
  final String? notes;
  final List<ApiSamplingPointCreate> points;

  const ApiSamplingSessionCreate({
    required this.fieldId,
    required this.samplingType,
    required this.sessionDate,
    this.notes,
    this.points = const [],
  });

  Map<String, dynamic> toJson() => {
        'field_id': fieldId,
        'sampling_type': samplingType,
        'session_date': sessionDate,
        if (notes != null) 'notes': notes,
        'points': points.map((p) => p.toJson()).toList(),
      };
}

class ApiObservationCreate {
  final String samplingPointId;
  final int diseaseId;
  final double? incidencePct;
  final double? severityValue;
  final String? severityScale;
  final String? cultivar;
  final String? phenologicalStage;
  final String? plantingDate;
  final bool? irrigation;
  final bool? fungicideApplied;
  final String? fertilizationNotes;
  final String? notes;
  final String observedAt; // ISO8601

  const ApiObservationCreate({
    required this.samplingPointId,
    required this.diseaseId,
    this.incidencePct,
    this.severityValue,
    this.severityScale,
    this.cultivar,
    this.phenologicalStage,
    this.plantingDate,
    this.irrigation,
    this.fungicideApplied,
    this.fertilizationNotes,
    this.notes,
    required this.observedAt,
  });

  Map<String, dynamic> toJson() => {
        'sampling_point_id': samplingPointId,
        'disease_id': diseaseId,
        if (incidencePct != null) 'incidence_pct': incidencePct,
        if (severityValue != null) 'severity_value': severityValue,
        if (severityScale != null) 'severity_scale': severityScale,
        if (cultivar != null) 'cultivar': cultivar,
        if (phenologicalStage != null) 'phenological_stage': phenologicalStage,
        if (plantingDate != null) 'planting_date': plantingDate,
        if (irrigation != null) 'irrigation': irrigation,
        if (fungicideApplied != null) 'fungicide_applied': fungicideApplied,
        if (fertilizationNotes != null) 'fertilization_notes': fertilizationNotes,
        if (notes != null) 'notes': notes,
        'observed_at': observedAt,
      };
}

class ApiObservationOut {
  final String id;
  final String samplingPointId;
  final int diseaseId;
  final String? diseaseName;
  final double? incidencePct;
  final double? severityValue;

  const ApiObservationOut({
    required this.id,
    required this.samplingPointId,
    required this.diseaseId,
    this.diseaseName,
    this.incidencePct,
    this.severityValue,
  });

  factory ApiObservationOut.fromJson(Map<String, dynamic> j) => ApiObservationOut(
        id: j['id'] as String,
        samplingPointId: j['sampling_point_id'] as String,
        diseaseId: j['disease_id'] as int,
        diseaseName: j['disease_name'] as String?,
        incidencePct: (j['incidence_pct'] as num?)?.toDouble(),
        severityValue: (j['severity_value'] as num?)?.toDouble(),
      );
}

class ApiMediaOut {
  final String id;
  final String mediaType;
  final String url;

  const ApiMediaOut({required this.id, required this.mediaType, required this.url});

  factory ApiMediaOut.fromJson(Map<String, dynamic> j) => ApiMediaOut(
        id: j['id'] as String,
        mediaType: j['media_type'] as String,
        url: j['url'] as String,
      );
}

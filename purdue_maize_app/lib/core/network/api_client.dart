import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_models.dart';

/// URL base del backend. Sobrescribir desde Settings o env.
const _kBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator → localhost

class ApiClient {
  ApiClient({required String baseUrl, String? token})
      : _dio = _buildDio(baseUrl, token);

  final Dio _dio;

  static Dio _buildDio(String baseUrl, String? token) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
    return dio;
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────

  /// Login — retorna el objeto completo con token + datos del usuario.
  Future<ApiLoginResult> login(String email, String password) async {
    final resp = await _dio.post(
      '/auth/token',
      data: {'username': email, 'password': password},
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );
    final data = resp.data as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return ApiLoginResult(
      token: data['access_token'] as String,
      userId: user['id'] as String,
      email: user['email'] as String,
      fullName: user['full_name'] as String,
    );
  }

  // ── Diseases catalog ─────────────────────────────────────────────────────────

  Future<List<ApiDisease>> getDiseases() async {
    final resp = await _dio.get('/diseases');
    return (resp.data as List).map((e) => ApiDisease.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Sampling sessions ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createSession(ApiSamplingSessionCreate payload) async {
    final resp = await _dio.post('/sampling/sessions', data: payload.toJson());
    return resp.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getSessions({String? fieldId}) async {
    final resp = await _dio.get(
      '/sampling/sessions',
      queryParameters: {if (fieldId != null) 'field_id': fieldId},
    );
    return (resp.data as List).cast<Map<String, dynamic>>();
  }

  // ── Observations ──────────────────────────────────────────────────────────────

  Future<ApiObservationOut> createObservation(ApiObservationCreate payload) async {
    final resp = await _dio.post('/observations/', data: payload.toJson());
    return ApiObservationOut.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ApiMediaOut> uploadMedia(String observationId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
    });
    final resp = await _dio.post(
      '/observations/$observationId/media',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return ApiMediaOut.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Modeling ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitModelRun(Map<String, dynamic> payload) async {
    final resp = await _dio.post('/modeling/runs', data: payload);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getModelRun(String runId) async {
    final resp = await _dio.get('/modeling/runs/$runId');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getModelResults(String runId) async {
    final resp = await _dio.get('/modeling/runs/$runId/results');
    return (resp.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getModelResultsGeoJson(String runId, {String? date}) async {
    final resp = await _dio.get(
      '/modeling/runs/$runId/results/geojson',
      queryParameters: {if (date != null) 'result_date': date},
    );
    return resp.data as Map<String, dynamic>;
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

/// Token JWT del usuario (null = no autenticado).
final authTokenProvider = StateProvider<String?>((ref) => null);

final apiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(authTokenProvider);
  return ApiClient(baseUrl: _kBaseUrl, token: token);
});

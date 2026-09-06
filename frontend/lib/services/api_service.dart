import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/scheme_result.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Default base URL:
  /// - Flutter Web: http://127.0.0.1:8000
  /// - Android Emulator: http://10.0.2.2:8000
  /// - Other platforms (iOS/Windows/macOS/Linux): http://127.0.0.1:8000
  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  String _baseUrl = _resolveDefaultBaseUrl();

  String get baseUrl => _baseUrl;

  void setBaseUrl(String newUrl) {
    _baseUrl = newUrl.replaceAll(RegExp(r'/+$'), '');
  }

  /// Centralized HTTP headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// POST /search - Multilingual Semantic Scheme Retrieval & Ranking
  Future<List<SchemeResult>> searchSchemes(SearchRequest request) async {
    final uri = Uri.parse('$_baseUrl/search');

    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> resultsList = data['results'] ?? [];
        return resultsList.map((item) => SchemeResult.fromJson(item)).toList();
      } else {
        String detailMessage = 'Server error (${response.statusCode})';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData is Map && errorData.containsKey('detail')) {
            detailMessage = errorData['detail'].toString();
          }
        } catch (_) {}
        throw ApiException(detailMessage, statusCode: response.statusCode);
      }
    } on TimeoutException {
      throw ApiException(
        'Connection timed out connecting to $_baseUrl. Please verify the backend is running.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Network error connecting to SAARTHI AI server at $_baseUrl. '
        'Ensure FastAPI backend is running (uvicorn app.main:app --reload) and CORS is allowed. (${e.message})',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected network error connecting to $_baseUrl: ${e.toString()}');
    }
  }

  /// POST /feedback - Records 👍 or 👎 feedback for lightweight re-ranking
  Future<bool> submitFeedback(FeedbackRequest request) async {
    final uri = Uri.parse('$_baseUrl/feedback');

    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error submitting feedback to $_baseUrl: $e');
      return false;
    }
  }
}

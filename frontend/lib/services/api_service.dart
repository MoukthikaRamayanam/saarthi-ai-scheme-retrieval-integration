import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/scheme_result.dart';


class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() => message;
}


class ApiService {
  // Singleton
  static final ApiService _instance =
      ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();


  // ---------------------------------------------------------
  // Base URL
  // ---------------------------------------------------------

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (
        defaultTargetPlatform ==
        TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }


  String _baseUrl =
      _resolveDefaultBaseUrl();

  String get baseUrl => _baseUrl;


  void setBaseUrl(String newUrl) {
    _baseUrl = newUrl.replaceAll(
      RegExp(r'/+$'),
      '',
    );
  }


  // ---------------------------------------------------------
  // HTTP headers
  // ---------------------------------------------------------

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };


  // ---------------------------------------------------------
  // POST /search
  // ---------------------------------------------------------

  Future<List<SchemeResult>> searchSchemes(
    SearchRequest request,
  ) async {

    final uri = Uri.parse(
      '$_baseUrl/search',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(
              request.toJson(),
            ),
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );


      // -----------------------------------------------------
      // Successful HTTP response
      // -----------------------------------------------------

      if (response.statusCode == 200) {

        final Map<String, dynamic> data =
            jsonDecode(
          utf8.decode(
            response.bodyBytes,
          ),
        );


        // ---------------------------------------------------
        // Check backend query validation
        // ---------------------------------------------------

        final bool validQuery =
            data['valid_query'] ?? true;

        final String? message =
            data['message']?.toString();


        // Invalid / unrelated query
        if (!validQuery) {
          throw ApiException(
            message ??
                'Please describe a business or scheme-related need.',
            statusCode: 400,
          );
        }


        // ---------------------------------------------------
        // Read scheme results
        // ---------------------------------------------------

        final List<dynamic> resultsList =
            data['results'] ?? [];


        return resultsList
            .map(
              (item) =>
                  SchemeResult.fromJson(
                item,
              ),
            )
            .toList();
      }


      // -----------------------------------------------------
      // Backend HTTP error
      // -----------------------------------------------------

      String detailMessage =
          'Server error (${response.statusCode})';

      try {
        final errorData =
            jsonDecode(
          utf8.decode(
            response.bodyBytes,
          ),
        );

        if (
            errorData is Map &&
            errorData.containsKey(
              'detail',
            )) {

          detailMessage =
              errorData['detail']
                  .toString();
        }
      } catch (_) {}


      throw ApiException(
        detailMessage,
        statusCode:
            response.statusCode,
      );
    }


    // -------------------------------------------------------
    // Timeout
    // -------------------------------------------------------

    on TimeoutException {
      throw ApiException(
        'Connection timed out. '
        'Please verify that the SAARTHI backend is running.',
      );
    }


    // -------------------------------------------------------
    // Network error
    // -------------------------------------------------------

    on http.ClientException catch (e) {
      throw ApiException(
        'Unable to connect to the SAARTHI AI server at '
        '$_baseUrl. Please make sure the FastAPI backend '
        'is running. (${e.message})',
      );
    }


    // -------------------------------------------------------
    // Already formatted API error
    // -------------------------------------------------------

    on ApiException {
      rethrow;
    }


    // -------------------------------------------------------
    // Unexpected error
    // -------------------------------------------------------

    catch (e) {
      throw ApiException(
        'Unexpected network error: '
        '${e.toString()}',
      );
    }
  }


  // ---------------------------------------------------------
  // POST /feedback
  // ---------------------------------------------------------

  Future<bool> submitFeedback(
    FeedbackRequest request,
  ) async {

    final uri = Uri.parse(
      '$_baseUrl/feedback',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(
              request.toJson(),
            ),
          )
          .timeout(
            const Duration(
              seconds: 10,
            ),
          );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        'Error submitting feedback '
        'to $_baseUrl: $e',
      );

      return false;
    }
  }
}
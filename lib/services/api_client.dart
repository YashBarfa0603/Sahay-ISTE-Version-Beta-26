import 'dart:async';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sahay/core/config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  String? _customBaseUrl;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: defaultBaseUrl,
        connectTimeout: const Duration(seconds: AppConfig.apiTimeoutSeconds),
        receiveTimeout: const Duration(seconds: AppConfig.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client-App': AppConfig.appName,
          'X-Client-Version': AppConfig.appVersion,
        },
      ),
    );

    _dio.interceptors.add(_buildAuthInterceptor());
    _dio.interceptors.add(_buildLoggingInterceptor());
    _dio.interceptors.add(_buildRetryInterceptor());
  }

  Dio get client => _dio;

  /// Determines default base URL based on running platform.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      } else if (Platform.isIOS || Platform.isMacOS) {
        return 'http://127.0.0.1:8000';
      }
    } catch (_) {
      // Platform detection fallback
    }
    return 'http://127.0.0.1:8000';
  }

  /// Override baseUrl dynamically (e.g. for physical devices connecting to local Mac IP).
  void setBaseUrl(String url) {
    _customBaseUrl = url.trim();
    _dio.options.baseUrl = _customBaseUrl!;
    debugPrint('ApiClient: Base URL updated to: $_customBaseUrl');
  }

  void resetBaseUrl() {
    _customBaseUrl = null;
    _dio.options.baseUrl = defaultBaseUrl;
    debugPrint('ApiClient: Base URL reset to default: $defaultBaseUrl');
  }

  String get currentBaseUrl => _dio.options.baseUrl;

  /// Auth interceptor injecting Firebase ID token when user is logged in.
  Interceptor _buildAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final token = await currentUser.getIdToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              options.headers['X-User-Uid'] = currentUser.uid;
            }
          }
        } catch (e) {
          debugPrint('ApiClient AuthInterceptor: Failed to acquire token: $e');
        }
        return handler.next(options);
      },
    );
  }

  /// Safe logging interceptor that hides tokens, passwords, and sensitive keys.
  Interceptor _buildLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;
        final method = options.method;
        debugPrint('[API REQUEST] $method ${options.baseUrl}$path');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode;
        debugPrint('[API RESPONSE] $status ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException error, handler) {
        final status = error.response?.statusCode;
        debugPrint('[API ERROR] Status $status on ${error.requestOptions.path}: ${error.message}');
        return handler.next(error);
      },
    );
  }

  /// Safe retry interceptor for handling transient network dropouts.
  Interceptor _buildRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException error, handler) async {
        final requestOptions = error.requestOptions;
        final int retryCount = (requestOptions.extra['retry_count'] as num?)?.toInt() ?? 0;

        final isRetryable = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError ||
            (error.response?.statusCode != null &&
                error.response!.statusCode! >= 500 &&
                error.response!.statusCode! <= 504);

        if (isRetryable && retryCount < AppConfig.maxRetryAttempts) {
          requestOptions.extra['retry_count'] = retryCount + 1;
          final int delayMs = 500 * (retryCount + 1);
          debugPrint('ApiClient: Retrying request (attempt ${retryCount + 1}) after ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));

          try {
            final response = await _dio.fetch(requestOptions);
            return handler.resolve(response);
          } catch (retryError) {
            if (retryError is DioException) {
              return handler.next(retryError);
            }
          }
        }

        return handler.next(error);
      },
    );
  }

  /// Generic GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Generic POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Translates DioException into friendly typed ApiException.
  ApiException _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String message = 'Unable to connect to SAHAY service. Operating in offline-safe mode.';
    if (data is Map && data['detail'] != null) {
      message = data['detail'].toString();
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timed out while reaching the scheme service.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Backend service is currently unreachable. Using verified local scheme catalogue.';
    }

    return ApiException(message, statusCode: statusCode, details: data);
  }
}

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/api_config.dart';
import 'api_exceptions.dart';

class AppDioClient {
  AppDioClient({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';

          final authRequired = options.extra['authRequired'] == true;
          if (authRequired) {
            final token = await FirebaseAuth.instance.currentUser?.getIdToken();
            if (token == null || token.isEmpty) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  error: UnauthorizedException(),
                  type: DioExceptionType.unknown,
                ),
              );
              return;
            }
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  static BaseOptions get _defaultOptions => BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  );

  Future<Response<dynamic>> get(
    String path, {
    bool authRequired = false,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(extra: {'authRequired': authRequired}),
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    bool authRequired = false,
    Object? data,
  }) async {
    try {
      return await _dio.post<dynamic>(
        path,
        data: data,
        options: Options(extra: {'authRequired': authRequired}),
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  ApiException _mapException(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || e.error is UnauthorizedException) {
      return UnauthorizedException();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException('Connexion impossible au serveur');
    }

    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final detail = responseData['detail'];
      if (detail is String && detail.isNotEmpty) {
        return ApiException(detail, statusCode: statusCode);
      }
    }
    if (responseData is String && responseData.isNotEmpty) {
      return ApiException(responseData, statusCode: statusCode);
    }

    return ApiException(
      'Erreur API (${statusCode ?? 'inconnue'})',
      statusCode: statusCode,
    );
  }
}

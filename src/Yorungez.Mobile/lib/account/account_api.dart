import 'package:dio/dio.dart';
import 'account_models.dart';

abstract interface class AccountApi {
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    String? access,
    String? owner,
    String language = 'en',
  });
}

final class HttpAccountApi implements AccountApi {
  HttpAccountApi(Uri origin, {Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              baseUrl: origin.toString(),
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 6),
            ),
          );
  final Dio _client;
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    String? access,
    String? owner,
    String language = 'en',
  }) async {
    try {
      final response = await _client.request<dynamic>(
        '/api/v1/$path',
        data: body,
        options: Options(
          method: method,
          followRedirects: false,
          headers: {
            'Accept-Language': language,
            'Cache-Control': 'no-store',
            if (access != null) 'Authorization': 'Bearer $access',
            'X-Yorungez-Account': ?owner,
          },
        ),
      );
      return response.data;
    } on DioException catch (error) {
      final data = error.response?.data;
      final code =
          data is Map &&
              data['code'] is String &&
              (data['code'] as String).length <= 100
          ? data['code'] as String
          : '';
      final kind = switch (error.response?.statusCode) {
        401 => AccountFailureKind.unauthorized,
        403 when code == 'Identity.EmailNotConfirmed' =>
          AccountFailureKind.unconfirmed,
        403 => AccountFailureKind.unauthorized,
        409 => AccountFailureKind.conflict,
        400 || 422 => AccountFailureKind.validation,
        429 => AccountFailureKind.throttled,
        final int status when status >= 500 => AccountFailureKind.server,
        _ => switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.sendTimeout => AccountFailureKind.timeout,
          DioExceptionType.badResponse => AccountFailureKind.protocol,
          _ => AccountFailureKind.network,
        },
      };
      // Never propagate DioException: it contains credentials/request bodies.
      throw AccountFailure(kind, code);
    }
  }

  void close() => _client.close(force: true);
}

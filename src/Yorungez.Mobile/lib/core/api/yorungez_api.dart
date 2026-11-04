import 'dart:convert';
import 'package:dio/dio.dart';

enum ServiceFailureKind { network, timeout, server, protocol }

final class ServiceFailure implements Exception {
  const ServiceFailure(this.kind);
  final ServiceFailureKind kind;
}

Uri validateApiOrigin(String value, {required bool release}) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasAuthority ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/')) {
    throw const FormatException('API_BASE_URL must be an origin');
  }
  final loopback = [
    'localhost',
    '127.0.0.1',
    '::1',
    '10.0.2.2',
  ].contains(uri.host);
  if (uri.scheme != 'https' &&
      !(uri.scheme == 'http' && loopback && !release)) {
    throw const FormatException('API_BASE_URL requires HTTPS');
  }
  return uri;
}

final class YorungezApi {
  YorungezApi(Uri origin, {Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              baseUrl: origin.toString(),
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
              sendTimeout: const Duration(seconds: 6),
            ),
          );
  final Dio _client;

  Future<void> checkStatus(String language) async {
    try {
      final response = await _client.get<dynamic>(
        '/api/v1/status',
        options: Options(headers: {'Accept-Language': language}),
      );
      final data = response.data;
      if (data is! Map ||
          data['service'] != 'yorungez' ||
          data['apiVersion'] != 'v1') {
        throw const ServiceFailure(ServiceFailureKind.protocol);
      }
    } on DioException catch (error) {
      final kind = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => ServiceFailureKind.timeout,
        DioExceptionType.badResponse => ServiceFailureKind.server,
        _ => ServiceFailureKind.network,
      };
      throw ServiceFailure(kind);
    }
  }

  Future<Map<String, dynamic>> issElements() async {
    try {
      final response = await _client.get<String>(
        '/api/v1/catalog/satellites/iss',
        options: Options(responseType: ResponseType.plain),
      );
      final raw = response.data;
      if (raw == null || raw.length > 32768) {
        throw const ServiceFailure(ServiceFailureKind.protocol);
      }
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        throw const ServiceFailure(ServiceFailureKind.protocol);
      }
      return data;
    } on DioException catch (_) {
      throw const ServiceFailure(ServiceFailureKind.network);
    }
  }

  void close() => _client.close(force: true);
}

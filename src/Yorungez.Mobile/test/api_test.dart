import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/core/api/yorungez_api.dart';

void main() {
  test('API origin rejects insecure release and credential/query URLs', () {
    for (final value in [
      'http://api.yorungez.com',
      'https://name:password@example.com',
      'https://example.com?token=sample',
      'https://example.com/path',
      'file:///tmp/api',
    ]) {
      expect(
        () => validateApiOrigin(value, release: true),
        throwsFormatException,
      );
    }
    expect(
      validateApiOrigin('https://api.yorungez.com', release: true).host,
      'api.yorungez.com',
    );
    expect(
      validateApiOrigin('http://10.0.2.2:5000', release: false).port,
      5000,
    );
    expect(
      () => validateApiOrigin('http://10.0.2.2:5000', release: true),
      throwsFormatException,
    );
  });

  test(
    'status validates the shared contract and sends the explicit language',
    () async {
      final client = Dio();
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.path, '/api/v1/status');
            expect(request.headers['Accept-Language'], 'tr');
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {'service': 'yorungez', 'apiVersion': 'v1'},
              ),
            );
          },
        ),
      );
      final api = YorungezApi(Uri.parse('https://example.com'), client: client);
      addTearDown(api.close);
      await api.checkStatus('tr');
    },
  );

  test('an unexpected successful payload is a protocol error', () async {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) => h.resolve(
          Response(
            requestOptions: r,
            statusCode: 200,
            data: {'service': 'other'},
          ),
        ),
      ),
    );
    final api = YorungezApi(Uri.parse('https://example.com'), client: client);
    addTearDown(api.close);
    await expectLater(
      api.checkStatus('en'),
      throwsA(
        isA<ServiceFailure>().having(
          (e) => e.kind,
          'kind',
          ServiceFailureKind.protocol,
        ),
      ),
    );
  });

  for (final pair in [
    (DioExceptionType.connectionError, ServiceFailureKind.network),
    (DioExceptionType.receiveTimeout, ServiceFailureKind.timeout),
    (DioExceptionType.badResponse, ServiceFailureKind.server),
  ]) {
    test('${pair.$1} remains distinct from an offline failure', () async {
      final client = Dio();
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) =>
              h.reject(DioException(requestOptions: r, type: pair.$1)),
        ),
      );
      final api = YorungezApi(Uri.parse('https://example.com'), client: client);
      addTearDown(api.close);
      await expectLater(
        api.checkStatus('en'),
        throwsA(isA<ServiceFailure>().having((e) => e.kind, 'kind', pair.$2)),
      );
    });
  }
}

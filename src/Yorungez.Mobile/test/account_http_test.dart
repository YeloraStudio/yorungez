import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/account/account_api.dart';
import 'package:yorungez/account/account_models.dart';

void main() {
  test(
    'authenticated requests use the common API owner, Bearer, language and no-redirect contract',
    () async {
      final client = Dio();
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.path, '/api/v1/auth/language');
            expect(request.method, 'POST');
            expect(request.headers['Authorization'], 'Bearer synthetic-access');
            expect(request.headers['X-Yorungez-Account'], 'synthetic-owner');
            expect(request.headers['Accept-Language'], 'tr');
            expect(request.followRedirects, false);
            expect(request.data, {'preferredLanguage': 'tr'});
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {'accepted': true},
              ),
            );
          },
        ),
      );
      final api = HttpAccountApi(
        Uri.parse('https://example.invalid'),
        client: client,
      );
      addTearDown(api.close);
      expect(
        await api.request(
          'auth/language',
          method: 'POST',
          access: 'synthetic-access',
          owner: 'synthetic-owner',
          language: 'tr',
          body: {'preferredLanguage': 'tr'},
        ),
        {'accepted': true},
      );
    },
  );
  for (final sample in [
    (401, 'Identity.InvalidCredentials', AccountFailureKind.unauthorized),
    (403, 'Identity.EmailNotConfirmed', AccountFailureKind.unconfirmed),
    (409, 'Identity.PreferencesConflict', AccountFailureKind.conflict),
    (429, 'Common.RateLimited', AccountFailureKind.throttled),
  ]) {
    test(
      'HTTP ${sample.$1} becomes a safe typed error without credential-bearing Dio details',
      () async {
        final client = Dio();
        client.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: request,
                    statusCode: sample.$1,
                    data: {
                      'code': sample.$2,
                      'detail': 'synthetic-private-server-detail',
                    },
                  ),
                ),
              );
            },
          ),
        );
        final api = HttpAccountApi(
          Uri.parse('https://example.invalid'),
          client: client,
        );
        addTearDown(api.close);
        try {
          await api.request(
            'auth/login',
            method: 'POST',
            body: {
              'email': 'public@example.invalid',
              'password': 'synthetic-private-password',
            },
          );
          fail('Expected a typed failure');
        } on AccountFailure catch (error) {
          expect(error.kind, sample.$3);
          expect(error.code, sample.$2);
          expect(error.toString(), isNot(contains('synthetic-private')));
          expect(error, isNot(isA<DioException>()));
        }
      },
    );
  }
}

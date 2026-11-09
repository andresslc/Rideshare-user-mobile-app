import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/core/observability/observability_sanitizer.dart';

void main() {
  test('redacts sensitive headers and body fields', () {
    final headers = ObservabilitySanitizer.sanitizeHeaders(<String, dynamic>{
      'Authorization': 'Bearer secret',
      'content-type': 'application/json',
    });

    final body = ObservabilitySanitizer.sanitizeBody(<String, dynamic>{
      'phone': '+15551234567',
      'address': '123 Main Street',
      'nested': <String, dynamic>{
        'token': 'abc',
        'safe': 'ok',
      },
      'list': <dynamic>[
        <String, dynamic>{'email': 'user@example.com'},
        'value',
      ],
    }) as Map<String, dynamic>;

    expect(headers['Authorization'], '<redacted>');
    expect(headers['content-type'], 'application/json');
    expect(body['phone'], '<redacted>');
    expect(body['address'], '<redacted>');
    expect((body['nested'] as Map<String, dynamic>)['token'], '<redacted>');
    expect((body['nested'] as Map<String, dynamic>)['safe'], 'ok');
    expect(((body['list'] as List<dynamic>).first as Map<String, dynamic>)['email'], '<redacted>');
  });

  test('removes query string from paths', () {
    expect(
      ObservabilitySanitizer.sanitizePath('/api/ride?id=123&token=abc'),
      '/api/ride',
    );
  });
}

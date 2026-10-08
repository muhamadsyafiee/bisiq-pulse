import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/services/pro_entitlement.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // Signed by backend/entitlement.mjs with a test-only key.
  final fixture =
      jsonDecode(
            File('test/fixtures/entitlement_lease.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final document = fixture['document'] as String;
  final installation = fixture['installationId'] as String;
  final issued = DateTime.utc(2026, 10, 8);
  SignedEntitlementVerifier verifier({
    DateTime? now,
    String? key,
    http.Client? client,
  }) => SignedEntitlementVerifier(
    endpoint: 'https://billing.example/v1/entitlements/verify',
    publicKey: key ?? fixture['publicKey'] as String,
    client: client,
    now: () => now ?? issued.add(const Duration(days: 1)),
  );

  test(
    'backend-signed lease unlocks only its installation until expiry',
    () async {
      final lease = await verifier().cached(document, installation);
      expect(lease?.expiresAt, issued.add(const Duration(days: 7)));
      expect(await verifier().cached(document, 'another-installation'), isNull);
      expect(
        await verifier(
          now: issued.add(const Duration(days: 7)),
        ).cached(document, installation),
        isNull,
      );
    },
  );

  test('tampered payload or another signing key is rejected', () async {
    final envelope = jsonDecode(document) as Map<String, dynamic>;
    final claims =
        jsonDecode(
              utf8.decode(
                base64Url.decode(
                  base64Url.normalize(envelope['payload'] as String),
                ),
              ),
            )
            as Map<String, dynamic>;
    claims['expiresAt'] = (claims['expiresAt'] as int) + 86400 * 365;
    envelope['payload'] = base64Url
        .encode(utf8.encode(jsonEncode(claims)))
        .replaceAll('=', '');
    expect(await verifier().cached(jsonEncode(envelope), installation), isNull);
    expect(
      await verifier(
        key: base64Encode(List.filled(32, 7)),
      ).cached(document, installation),
      isNull,
    );
  });

  test('server responses map to purchase states', () async {
    Future<Object?> outcome(int status, [String body = '{}']) async {
      final client = MockClient((request) async {
        expect(request.headers['content-type'], startsWith('application/json'));
        expect(jsonDecode(request.body), {
          'purchaseToken': 'play-token',
          'installationId': installation,
        });
        return http.Response(status == 200 ? document : body, status);
      });
      try {
        return await verifier(
          client: client,
        ).verify('play-token', installation);
      } catch (error) {
        return error;
      }
    }

    expect(await outcome(200), isA<ProLease>());
    expect(await outcome(403), isA<PurchaseRejected>());
    expect(await outcome(409), isA<PurchasePending>());
    expect(await outcome(503), isA<StateError>());
  });
}

import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const proProductId = 'pulse_pro_lifetime';
const pulsePackage = 'com.pulseworkout.gym_timer';

class ProConfiguration {
  static const endpoint = String.fromEnvironment('PULSE_BILLING_URL');
  static const publicKey = String.fromEnvironment('PULSE_BILLING_PUBLIC_KEY');
  static bool get enabled {
    final uri = Uri.tryParse(endpoint);
    try {
      return uri?.scheme == 'https' &&
          uri!.host.isNotEmpty &&
          base64Decode(publicKey).length == 32;
    } catch (_) {
      return false;
    }
  }
}

abstract class ProCache {
  Future<String> installationId();
  Future<String?> read();
  Future<void> write(String? value);
}

class DeviceProCache implements ProCache {
  final _prefs = SharedPreferencesAsync();
  @override
  Future<String> installationId() async {
    var id = await _prefs.getString('pulse.billing.installation');
    if (id == null) {
      id = const Uuid().v4();
      await _prefs.setString('pulse.billing.installation', id);
    }
    return id;
  }

  @override
  Future<String?> read() => _prefs.getString('pulse.billing.lease');
  @override
  Future<void> write(String? value) async {
    if (value == null) {
      await _prefs.remove('pulse.billing.lease');
    } else {
      await _prefs.setString('pulse.billing.lease', value);
    }
  }
}

class ProLease {
  const ProLease(this.document, this.expiresAt);
  final String document;
  final DateTime expiresAt;
}

class PurchaseRejected implements Exception {}

class PurchasePending implements Exception {}

abstract class EntitlementVerifier {
  Future<ProLease?> cached(String document, String installationId);
  Future<ProLease> verify(String token, String installationId);
}

/// Only a server-signed, installation-bound lease can unlock offline access.
class SignedEntitlementVerifier implements EntitlementVerifier {
  SignedEntitlementVerifier({
    required this.endpoint,
    required this.publicKey,
    http.Client? client,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;
  final String endpoint, publicKey;
  final http.Client _client;
  final DateTime Function() _now;
  @override
  Future<ProLease?> cached(String document, String installationId) async {
    try {
      final envelope = jsonDecode(document) as Map;
      final payload = base64Url.decode(
        base64Url.normalize(envelope['payload'] as String),
      );
      final signature = base64Url.decode(
        base64Url.normalize(envelope['signature'] as String),
      );
      final valid = await Ed25519().verify(
        payload,
        signature: Signature(
          signature,
          publicKey: SimplePublicKey(
            base64Decode(publicKey),
            type: KeyPairType.ed25519,
          ),
        ),
      );
      if (!valid) return null;
      final claims = jsonDecode(utf8.decode(payload)) as Map;
      final issued = DateTime.fromMillisecondsSinceEpoch(
        (claims['issuedAt'] as int) * 1000,
        isUtc: true,
      );
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        (claims['expiresAt'] as int) * 1000,
        isUtc: true,
      );
      if (claims['version'] != 1 ||
          claims['productId'] != proProductId ||
          claims['packageName'] != pulsePackage ||
          claims['installationId'] != installationId ||
          issued.isAfter(_now().add(const Duration(minutes: 5))) ||
          !expiry.isAfter(_now()) ||
          !expiry.isAfter(issued) ||
          expiry.difference(issued) > const Duration(days: 7)) {
        return null;
      }
      return ProLease(document, expiry);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ProLease> verify(String token, String installationId) async {
    final uri = Uri.parse(endpoint);
    if (uri.scheme != 'https') throw StateError('HTTPS required');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'purchaseToken': token,
            'installationId': installationId,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 403) throw PurchaseRejected();
    if (response.statusCode == 409) throw PurchasePending();
    if (response.statusCode != 200 || response.body.length > 8192) {
      throw StateError('Verification unavailable');
    }
    final lease = await cached(response.body, installationId);
    if (lease == null) throw StateError('Invalid entitlement signature');
    return lease;
  }
}

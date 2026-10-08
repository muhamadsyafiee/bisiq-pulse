import 'dart:async';
import 'package:gym_timer/services/pro_controller.dart';
import 'package:gym_timer/services/pro_entitlement.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class TestProController extends ProController {
  TestProController() : super(enabled: false);
  bool active = true;
  @override
  bool get isPro => active;
  void setActive(bool value) {
    active = value;
    notifyListeners();
  }
}

class MemoryProCache implements ProCache {
  String? value;
  bool fail = false;
  @override
  Future<String> installationId() async => 'installation-test-1234';
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? document) async {
    if (fail) throw StateError('storage failure');
    value = document;
  }
}

class FakeProStore implements ProStore {
  final events = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  List<PurchaseDetails> purchasesOwned = [];
  bool online = true;
  int buys = 0, completions = 0;
  @override
  Stream<List<PurchaseDetails>> get purchases => events.stream;
  @override
  Future<bool> available() async => online;
  @override
  Future<ProductDetails?> product() async => ProductDetails(
    id: proProductId,
    title: 'Pro',
    description: 'Pro',
    price: 'RM19.90',
    rawPrice: 19.9,
    currencyCode: 'MYR',
  );
  @override
  Future<bool> buy(ProductDetails product) async {
    buys++;
    return true;
  }

  @override
  Future<List<PurchaseDetails>> owned() async {
    if (!online) throw StateError('offline');
    return purchasesOwned;
  }

  @override
  Future<void> complete(PurchaseDetails purchase) async {
    completions++;
  }
}

PurchaseDetails purchase(PurchaseStatus status) =>
    PurchaseDetails(
        productID: proProductId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: 'test-token',
          source: 'google_play',
        ),
        transactionDate: '0',
        status: status,
      )
      ..pendingCompletePurchase =
          status == PurchaseStatus.purchased ||
          status == PurchaseStatus.restored;

class FakeVerifier implements EntitlementVerifier {
  Object? error;
  final DateTime now;
  FakeVerifier(this.now);
  @override
  Future<ProLease?> cached(String document, String installationId) async =>
      document == 'signed'
      ? ProLease(document, now.add(const Duration(days: 7)))
      : null;
  @override
  Future<ProLease> verify(String token, String installationId) async {
    if (error != null) throw error!;
    return ProLease('signed', now.add(const Duration(days: 7)));
  }
}

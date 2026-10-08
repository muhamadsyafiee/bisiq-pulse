import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/services/pro_controller.dart';
import 'package:gym_timer/services/pro_entitlement.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'pro_test_support.dart';

void main() {
  final now = DateTime.utc(2026, 10, 8);
  late FakeProStore store;
  late MemoryProCache cache;
  late FakeVerifier verifier;
  late ProController controller;
  setUp(() {
    store = FakeProStore();
    cache = MemoryProCache();
    verifier = FakeVerifier(now);
    controller = ProController(
      enabled: true,
      store: store,
      cache: cache,
      verifier: verifier,
      now: () => now,
    );
  });
  tearDown(() async {
    controller.dispose();
    await store.events.close();
  });
  test('no configuration means no purchase and no entitlement', () async {
    final disabled = ProController(enabled: false);
    await disabled.initialize();
    await disabled.buy();
    expect(disabled.canBuy, false);
    expect(disabled.isPro, false);
    expect(disabled.message, 'proUnavailable');
    disabled.dispose();
  });
  test(
    'verified restored purchase unlocks and completes, revocation removes cached access',
    () async {
      store.purchasesOwned = [purchase(PurchaseStatus.restored)];
      await controller.initialize();
      expect(controller.isPro, true);
      expect(store.completions, 1);
      expect(cache.value, 'signed');
      verifier.error = PurchaseRejected();
      await controller.restore();
      expect(controller.isPro, false);
      expect(cache.value, isNull);
      expect(store.completions, 1);
    },
  );
  test(
    'pending, cancelled and failed transactions never grant or complete',
    () async {
      await controller.initialize();
      for (final status in [
        PurchaseStatus.pending,
        PurchaseStatus.canceled,
        PurchaseStatus.error,
      ]) {
        store.purchasesOwned = [purchase(status)];
        await controller.restore();
        expect(controller.isPro, false);
        expect(store.completions, 0);
        if (status == PurchaseStatus.pending) expect(controller.canBuy, false);
      }
    },
  );
  test(
    'verification or durable storage failure never completes a purchase',
    () async {
      await controller.initialize();
      store.purchasesOwned = [purchase(PurchaseStatus.purchased)];
      verifier.error = StateError('offline');
      await controller.restore();
      expect(controller.isPro, false);
      expect(store.completions, 0);
      verifier.error = null;
      cache.fail = true;
      await controller.restore();
      expect(controller.isPro, false);
      expect(store.completions, 0);
      cache.fail = false;
      await controller.restore();
      expect(controller.isPro, true);
      expect(store.completions, 1);
    },
  );
  test(
    'offline retains signed access, a successful empty restore removes it',
    () async {
      cache.value = 'signed';
      store.online = false;
      await controller.initialize();
      expect(controller.isPro, true);
      store.online = true;
      await controller.restore();
      expect(controller.isPro, false);
      expect(cache.value, isNull);
    },
  );
  test('purchase button cannot launch duplicate store flows', () async {
    await controller.initialize();
    await Future.wait([controller.buy(), controller.buy()]);
    expect(store.buys, 1);
    store.events.add([purchase(PurchaseStatus.purchased)]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(controller.isPro, true);
    expect(controller.busy, false);
    expect(store.completions, 1);
  });
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'pro_entitlement.dart';

abstract class ProStore {
  Stream<List<PurchaseDetails>> get purchases;
  Future<bool> available();
  Future<ProductDetails?> product();
  Future<bool> buy(ProductDetails product);
  Future<List<PurchaseDetails>> owned();
  Future<void> complete(PurchaseDetails purchase);
}

class GoogleProStore implements ProStore {
  final _iap = InAppPurchase.instance;
  @override
  Stream<List<PurchaseDetails>> get purchases => _iap.purchaseStream;
  @override
  Future<bool> available() => _iap.isAvailable();
  @override
  Future<ProductDetails?> product() async {
    final response = await _iap.queryProductDetails({proProductId});
    if (response.error != null) throw StateError('Product query failed');
    return response.productDetails
        .where((p) => p.id == proProductId)
        .firstOrNull;
  }

  @override
  Future<bool> buy(ProductDetails product) => _iap.buyNonConsumable(
    purchaseParam: PurchaseParam(productDetails: product),
  );
  @override
  Future<List<PurchaseDetails>> owned() async {
    final response = await _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .queryPastPurchases();
    if (response.error != null) throw StateError('Restore failed');
    return response.pastPurchases;
  }

  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

class ProController extends ChangeNotifier {
  ProController({
    required this.enabled,
    this.store,
    this.verifier,
    this.cache,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  factory ProController.device() {
    final enabled = ProConfiguration.enabled;
    return ProController(
      enabled: enabled,
      store: enabled ? GoogleProStore() : null,
      cache: enabled ? DeviceProCache() : null,
      verifier: enabled
          ? SignedEntitlementVerifier(
              endpoint: ProConfiguration.endpoint,
              publicKey: ProConfiguration.publicKey,
            )
          : null,
    );
  }
  final bool enabled;
  final ProStore? store;
  final EntitlementVerifier? verifier;
  final ProCache? cache;
  final DateTime Function() _now;
  ProLease? _lease;
  String? _installation;
  bool busy = false, ready = false, _disposed = false, _started = false;
  String? message;
  ProductDetails? product;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _expiryTimer, _purchaseTimer;
  Future<void> _queue = Future.value();
  bool get isPro => _lease != null && _lease!.expiresAt.isAfter(_now());
  bool get canBuy =>
      enabled &&
      ready &&
      product != null &&
      !busy &&
      !isPro &&
      message != 'proPending';
  bool canCreate(int count) => isPro || count < 3;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _setLease(ProLease? lease) {
    _lease = lease;
    _expiryTimer?.cancel();
    if (lease != null) {
      _expiryTimer = Timer(lease.expiresAt.difference(_now()), () {
        _lease = null;
        message = 'proRefresh';
        _notify();
      });
    }
  }

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    if (!enabled) {
      message = 'proUnavailable';
      _notify();
      return;
    }
    busy = true;
    _notify();
    try {
      _installation = await cache!.installationId();
      final raw = await cache!.read();
      if (raw != null) _setLease(await verifier!.cached(raw, _installation!));
      if (_disposed) return;
      _subscription = store!.purchases.listen(
        (items) {
          unawaited(_enqueue(items));
        },
        onError: (Object _) {
          busy = false;
          message = 'proStoreError';
          _notify();
        },
      );
      if (!await store!.available()) throw StateError('Store unavailable');
      ready = true;
      // Restoring ownership is independent of product availability/pricing.
      await _restore();
      if (message == 'proNoPurchase') message = null;
      product = await store!.product();
      if (product == null && !isPro) message = 'proUnavailable';
    } catch (_) {
      message = 'proStoreError';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _enqueue(List<PurchaseDetails> items) {
    final next = _queue.then((_) async {
      if (_disposed) return;
      for (final purchase in items) {
        if (purchase.productID != proProductId) continue;
        await _handle(purchase);
      }
    });
    _queue = next.catchError((Object _) {
      busy = false;
      message = 'proVerifyError';
      _notify();
    });
    return _queue;
  }

  Future<void> _handle(PurchaseDetails purchase) async {
    _purchaseTimer?.cancel();
    switch (purchase.status) {
      case PurchaseStatus.pending:
        busy = false;
        message = 'proPending';
        _notify();
        return;
      case PurchaseStatus.canceled:
        busy = false;
        message = 'proCancelled';
        _notify();
        return;
      case PurchaseStatus.error:
        busy = false;
        message = 'proStoreError';
        _notify();
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        busy = true;
        message = 'proVerifying';
        _notify();
        try {
          final token = purchase.verificationData.serverVerificationData;
          if (token.isEmpty) throw StateError('Missing token');
          final lease = await verifier!.verify(token, _installation!);
          await cache!.write(lease.document);
          if (_disposed) return;
          _setLease(lease);
          // The backend also acknowledges, so an interrupted client cannot
          // leave a verified purchase unacknowledged. Never consume lifetime Pro.
          if (purchase.pendingCompletePurchase) await store!.complete(purchase);
          message = 'proActivated';
        } on PurchaseRejected {
          _setLease(null);
          await cache!.write(null);
          message = 'proRejected';
        } on PurchasePending {
          message = 'proPending';
        } catch (_) {
          message = 'proVerifyError';
        } finally {
          busy = false;
          _notify();
        }
    }
  }

  Future<void> buy() async {
    if (!canBuy) return;
    busy = true;
    message = null;
    _notify();
    // Recover the UI if the store closes without delivering a callback.
    _purchaseTimer = Timer(const Duration(minutes: 2), () {
      busy = false;
      message = 'proRestoreHint';
      _notify();
    });
    try {
      if (!await store!.buy(product!)) {
        _purchaseTimer?.cancel();
        busy = false;
        message = 'proCancelled';
      }
    } catch (_) {
      _purchaseTimer?.cancel();
      busy = false;
      message = 'proStoreError';
    }
    _notify();
  }

  Future<void> _restore() async {
    final owned = await store!.owned();
    // A successful empty ownership query is authoritative; network errors are
    // not. Existing unexpired signed access survives temporary outages.
    if (!owned.any((p) => p.productID == proProductId)) {
      _setLease(null);
      await cache!.write(null);
      message = 'proNoPurchase';
    } else {
      await _enqueue(owned);
    }
  }

  Future<void> restore() async {
    if (!enabled || busy || _disposed) return;
    if (_installation == null || _subscription == null) {
      _started = false;
      await initialize();
      return;
    }
    busy = true;
    message = 'proVerifying';
    _notify();
    try {
      if (!await store!.available()) throw StateError('Store unavailable');
      ready = true;
      await _restore();
      product ??= await store!.product();
    } catch (_) {
      message = 'proStoreError';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expiryTimer?.cancel();
    _purchaseTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class ProScope extends InheritedNotifier<ProController> {
  const ProScope({
    super.key,
    required ProController controller,
    required super.child,
  }) : super(notifier: controller);
  static ProController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProScope>()?.notifier;
  static bool active(BuildContext context) => maybeOf(context)?.isPro ?? false;
}

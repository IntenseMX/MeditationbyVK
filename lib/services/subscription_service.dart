import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/subscription_config.dart';
import 'progress_service.dart';

/// Handles querying products, initiating purchases, listening for purchase updates,
/// and syncing premium status to Firestore via ProgressService.
class SubscriptionService {
  SubscriptionService({
    InAppPurchase? iap,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    ProgressService? progressService,
  })  : _iap = iap ?? InAppPurchase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _progress = progressService ?? ProgressService();

  final InAppPurchase _iap;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final ProgressService _progress;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  ProductDetails? _monthlyProduct;

  ProductDetails? get monthlyProduct => _monthlyProduct;

  Future<void> init() async {
    SubscriptionConfig.assertConfigured();
  }

  Future<void> start() async {
    // Skip IAP initialization if disabled (prevents spam during development)
    if (!SubscriptionConfig.enableIAP) {
      if (kDebugMode) {
        print('[SubscriptionService] IAP disabled via SubscriptionConfig.enableIAP');
      }
      return;
    }

    // Listen for purchase updates
    _purchaseSub = _iap.purchaseStream.listen(
      (purchases) => _handlePurchaseUpdates(purchases),
      onDone: () => _purchaseSub?.cancel(),
      onError: (Object error, StackTrace st) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('IAP purchase stream error: $error');
        }
      },
    );
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
  }

  Future<bool> isAvailable() async {
    if (!SubscriptionConfig.enableIAP) return false;
    return _iap.isAvailable();
  }

  Future<List<ProductDetails>> queryProducts() async {
    if (!SubscriptionConfig.enableIAP) return [];

    final response = await _iap.queryProductDetails(SubscriptionConfig.productIds.toSet());
    if (response.error != null) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('IAP query error: ${response.error}');
      }
    }
    if (response.productDetails.isNotEmpty) {
      _monthlyProduct = response.productDetails.firstWhere(
        (p) => p.id == SubscriptionConfig.monthlyProductId,
        orElse: () => response.productDetails.first,
      );
    }
    return response.productDetails;
  }

  Future<void> buyMonthly() async {
    final product = _monthlyProduct;
    if (product == null) {
      throw StateError('Monthly product not loaded');
    }
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Let UI reflect pending state via provider
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // In production, verify receipts server-side before granting entitlement.
          await _grantPremiumEntitlement();
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          if (kDebugMode) {
            // ignore: avoid_print
            print('IAP error: ${purchase.error}');
          }
          break;
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  Future<void> _grantPremiumEntitlement() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _progress.upsertUserPremium(isPremium: true);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to sync premium flag: $e');
      }
    }
  }
}



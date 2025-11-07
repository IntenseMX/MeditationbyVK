import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/subscription_config.dart';
import '../services/subscription_service.dart';

class SubscriptionState {
  final bool isLoading;
  final bool isPremium;
  final String? priceText;
  final String? error;
  final bool storeAvailable;

  const SubscriptionState({
    required this.isLoading,
    required this.isPremium,
    required this.storeAvailable,
    this.priceText,
    this.error,
  });

  const SubscriptionState.initial()
      : this(isLoading: true, isPremium: false, storeAvailable: false, priceText: null, error: null);

  SubscriptionState copyWith({
    bool? isLoading,
    bool? isPremium,
    String? priceText,
    String? error,
    bool? storeAvailable,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isPremium: isPremium ?? this.isPremium,
      priceText: priceText ?? this.priceText,
      error: error,
      storeAvailable: storeAvailable ?? this.storeAvailable,
    );
  }
}

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  late final SubscriptionService _service;
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  SubscriptionState build() {
    _service = SubscriptionService();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    ref.onDispose(() async {
      await _userDocSub?.cancel();
      await _service.dispose();
    });

    Future<void>(() => _init());
    return const SubscriptionState.initial();
  }

  Future<void> _init() async {
    try {
      await _service.init();
      await _service.start();

      // Observe user premium flag; falls back to false if missing
      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        _userDocSub = _firestore.collection('users').doc(uid).snapshots().listen((doc) {
          final data = doc.data();
          final isPremium = (data?['isPremium'] == true);
          state = state.copyWith(isPremium: isPremium);
        });
      }

      final available = await _service.isAvailable();
      final products = await _service.queryProducts();
      final price = _service.monthlyProduct?.price ?? SubscriptionConfig.monthlyDisplayPriceFallback;
      state = state.copyWith(
        isLoading: false,
        storeAvailable: available,
        priceText: price,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        priceText: SubscriptionConfig.monthlyDisplayPriceFallback,
      );
    }
  }

  Future<void> purchaseMonthly() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.buyMonthly();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> restore() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.restorePurchases();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(
  () => SubscriptionNotifier(),
);



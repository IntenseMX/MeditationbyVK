import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Emits true when offline (all connectivity results are none), false when any is online.
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  // Initial state
  final initial = await Connectivity().checkConnectivity();
  yield initial.every((r) => r == ConnectivityResult.none);

  // Changes
  await for (final results in Connectivity().onConnectivityChanged) {
    yield results.every((r) => r == ConnectivityResult.none);
  }
});



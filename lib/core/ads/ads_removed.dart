import 'package:blast_buddies/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the player bought "Remove ads" (banners and pop-up ads off; the
/// opt-in rewarded ads stay available).
class AdsRemovedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(prefsProvider).getBool('adsRemoved') ?? false;

  /// Sets the flag (called by the purchase flow and on restore).
  Future<void> set(bool value) async {
    state = value;
    await ref.read(prefsProvider).setBool('adsRemoved', value);
  }
}

/// "Remove ads" provider.
final adsRemovedProvider = NotifierProvider<AdsRemovedNotifier, bool>(AdsRemovedNotifier.new);

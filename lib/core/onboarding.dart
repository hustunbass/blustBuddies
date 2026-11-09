import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the player is with the first-run tutorial.
class OnboardingState {
  /// Creates the state.
  const OnboardingState({this.offered = false, this.done = false, this.rewarded = false});

  /// The welcome offer was shown once (never shown again on its own).
  final bool offered;

  /// The tutorial was finished or skipped.
  final bool done;

  /// The completion gift was paid out.
  final bool rewarded;
}

/// Remembers the tutorial offer and pays the gift once.
class OnboardingNotifier extends Notifier<OnboardingState> {
  /// Coins for finishing the tutorial for the first time.
  static const reward = 50;

  @override
  OnboardingState build() {
    final p = ref.watch(prefsProvider);
    return OnboardingState(
      offered: p.getBool('onboardingOffered') ?? false,
      done: p.getBool('onboardingDone') ?? false,
      rewarded: p.getBool('onboardingRewarded') ?? false,
    );
  }

  Future<void> _save(OnboardingState s) async {
    state = s;
    final p = ref.read(prefsProvider);
    await p.setBool('onboardingOffered', s.offered);
    await p.setBool('onboardingDone', s.done);
    await p.setBool('onboardingRewarded', s.rewarded);
  }

  /// The welcome offer has been shown.
  Future<void> markOffered() => _save(OnboardingState(offered: true, done: state.done, rewarded: state.rewarded));

  /// The player skipped the tutorial (no gift).
  Future<void> skip() => _save(OnboardingState(offered: true, done: true, rewarded: state.rewarded));

  /// The player finished the tutorial. Returns the coins paid (0 when the gift
  /// was already collected on an earlier run).
  Future<int> complete() async {
    final pay = !state.rewarded;
    await _save(const OnboardingState(offered: true, done: true, rewarded: true));
    if (!pay) return 0;
    await ref.read(walletProvider.notifier).earn(reward);
    return reward;
  }
}

/// Onboarding provider.
final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);

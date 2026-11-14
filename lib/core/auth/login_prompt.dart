import 'package:blast_buddies/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the first-launch login screen has been dealt with (signed in or
/// "continue as guest"). It is shown once; later changes happen in Settings.
class LoginPromptNotifier extends Notifier<bool> {
  static const _key = 'loginPromptDone';

  @override
  bool build() => ref.watch(prefsProvider).getBool(_key) ?? false;

  /// The player chose: never show the login screen on its own again.
  Future<void> markDone() async {
    state = true;
    await ref.read(prefsProvider).setBool(_key, true);
  }
}

/// See [LoginPromptNotifier].
final loginPromptDoneProvider = NotifierProvider<LoginPromptNotifier, bool>(LoginPromptNotifier.new);

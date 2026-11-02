import 'package:blast_buddies/core/audio/audio_service.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sound, music, vibration and control-size options.
class SettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SwitchListTile(
              title: Text(l.sound),
              value: s.sound,
              onChanged: (v) => notifier.update(s.copyWith(sound: v)),
            ),
            SwitchListTile(
              title: Text(l.music),
              value: s.music,
              onChanged: (v) => notifier.update(s.copyWith(music: v)),
            ),
            SwitchListTile(
              title: Text(l.vibration),
              value: s.vibration,
              onChanged: (v) {
                notifier.update(s.copyWith(vibration: v));
                if (v) ref.read(audioProvider).tap();
              },
            ),
            ListTile(
              title: Text(l.controlSize),
              subtitle: Slider(
                min: 0.7,
                max: 1.4,
                divisions: 7,
                value: s.controlScale,
                label: '${(s.controlScale * 100).round()}%',
                onChanged: (v) => notifier.update(s.copyWith(controlScale: v)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.language, style: const TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}

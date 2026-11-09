import 'package:blast_buddies/core/profile/profile.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the dialog to edit the player name. Resolves to true if it changed.
Future<bool> showRenameDialog(BuildContext context, WidgetRef ref) async {
  final saved = await showDialog<bool>(context: context, builder: (_) => const _RenameDialog());
  return saved ?? false;
}

class _RenameDialog extends ConsumerStatefulWidget {
  const _RenameDialog();

  @override
  ConsumerState<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends ConsumerState<_RenameDialog> {
  late final TextEditingController _ctrl = TextEditingController(text: ref.read(profileProvider).name);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (await ref.read(profileProvider.notifier).rename(_ctrl.text) && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final valid = PlayerNames.isValid(_ctrl.text);
    return AlertDialog(
      title: Text(l.editName),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLength: PlayerNames.maxLength,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => valid ? _save() : null,
        decoration: InputDecoration(
          labelText: l.yourName,
          helperText: l.nameRule(PlayerNames.minLength, PlayerNames.maxLength),
          helperMaxLines: 2,
          errorText: _ctrl.text.isNotEmpty && !valid ? l.nameInvalid : null,
          suffixIcon: IconButton(
            tooltip: l.randomName,
            icon: const Icon(Icons.casino),
            onPressed: () => setState(() {
              _ctrl.text = PlayerNames.suggest(ref.read(profileProvider).kind);
            }),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(onPressed: valid ? _save : null, child: Text(l.save)),
      ],
    );
  }
}

/// Small tappable "👤 name ✎" tag that opens the rename dialog.
class ProfileTag extends ConsumerWidget {
  /// Creates the tag.
  const ProfileTag({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final name = ref.watch(profileProvider.select((p) => p.name));
    return Semantics(
      button: true,
      label: '${l.editName}: $name',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showRenameDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ExcludeSemantics(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person, size: 18, color: Colors.white70),
              const SizedBox(width: 6),
              Flexible(
                child: Text(name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit, size: 14, color: Colors.white38),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Settings section: avatar, name, account type.
class AccountTile extends ConsumerWidget {
  /// Creates the tile.
  const AccountTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = ref.watch(profileProvider);
    final kind = switch (p.kind) {
      AuthKind.guest => l.accountGuest,
      AuthKind.apple => l.accountApple,
      AuthKind.google => l.accountGoogle,
    };
    return ListTile(
      leading: CircleAvatar(child: Text(p.name.characters.first.toUpperCase())),
      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(kind),
      trailing: const Icon(Icons.edit),
      onTap: () => showRenameDialog(context, ref),
    );
  }
}

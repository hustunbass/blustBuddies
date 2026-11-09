import 'package:blast_buddies/core/store/store.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';

/// Player-facing text for a store [StoreMessage].
String storeMessageText(AppLocalizations l, StoreMessage m) => switch (m.kind) {
      StoreMessageKind.coins => l.rewardGot(m.coins),
      StoreMessageKind.adsRemoved => l.adsRemovedThanks,
      StoreMessageKind.restored => l.purchasesRestored,
      StoreMessageKind.unavailable => l.storeUnavailable,
      StoreMessageKind.productMissing => l.productMissing,
      StoreMessageKind.failed => l.purchaseFailed,
    };

import 'package:blast_buddies/core/ads/ad_service.dart';
import 'package:blast_buddies/core/ads/ads_removed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-of-screen banner; empty for players who removed ads or when no ad
/// is available. Use on menu screens only, never during play.
class AdBannerSlot extends ConsumerWidget {
  /// Creates the slot.
  const AdBannerSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(adsRemovedProvider)) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) => Center(child: ref.read(adServiceProvider).buildBanner(context, c.maxWidth)),
    );
  }
}

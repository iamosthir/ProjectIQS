import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/widgets/bottom_nav_bar.dart';

/// Hosts the 5 bottom-nav branches via [StatefulNavigationShell], preserving
/// each tab's state (replaces the old manual `IndexedStack`). The shared
/// [BottomNavBar] drives branch switching; tapping the active tab pops it to
/// its root.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        destinations: [
          NavDestination(icon: Icons.home_rounded, label: l10n.navHome),
          NavDestination(
              icon: Icons.emoji_events_rounded, label: l10n.navMatches),
          NavDestination(icon: Icons.article_rounded, label: l10n.navNews),
          NavDestination(
              icon: Icons.smart_display_rounded, label: l10n.navVideo),
          NavDestination(icon: Icons.more_horiz_rounded, label: l10n.navMore),
        ],
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

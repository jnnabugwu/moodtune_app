import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';

import '../../helpers/helpers.dart';

const testEmail = 'user@example.com';
const testPassword = 'hunter22';
const testUser = AppUser(id: 'user-1', email: testEmail);

/// Path the page under test is pushed to by [PushLauncher].
const launchedPath = '/launched';

/// Label of the [PushLauncher] button.
const launcherLabel = 'Open page';

/// Root widget that pushes [launchedPath] so the page under test has a
/// route beneath it (making `context.canPop()` true).
class PushLauncher extends StatelessWidget {
  const PushLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: CupertinoButton(
          onPressed: () => context.push(launchedPath),
          child: const Text(launcherLabel),
        ),
      ),
    );
  }
}

/// Route that mounts [page] at [launchedPath] (used with [PushLauncher]).
GoRoute launchedRoute(Widget page) =>
    GoRoute(path: launchedPath, builder: (_, _) => page);

/// Text rendered by [stubRoute] for the `extra` it received.
String extraText(Object? extra) => 'extra:$extra';

/// A stub destination for [path] that renders [navigatedTo] plus the extra.
///
/// Needed for `context.push` destinations, which must resolve to a real route.
GoRoute stubRoute(String path) => GoRoute(
  path: path,
  builder: (_, state) => CupertinoPageScaffold(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(navigatedTo(path)), Text(extraText(state.extra))],
      ),
    ),
  ),
);

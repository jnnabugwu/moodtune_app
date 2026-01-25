import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnectSpotifyPage extends StatefulWidget {
  const ConnectSpotifyPage({super.key});

  @override
  State<ConnectSpotifyPage> createState() => _ConnectSpotifyPageState();
}

class _ConnectSpotifyPageState extends State<ConnectSpotifyPage> {
  final TextEditingController _codeController = TextEditingController();
  String? _lastLaunchedUrl;
  StreamSubscription<Uri?>? _linkSub;
  late final AppLinks _appLinks;
  static const _sessionId = 'debug-session';
  static const _runId = 'prefix-connect';
  static const _localLogPath = 'debug_connect.log';

  Future<void> _log(
    String hypothesisId,
    String message, [
    Map<String, Object?> data = const {},
  ]) async {
    try {
      // #region agent log
      final payload = {
        'sessionId': _sessionId,
        'runId': _runId,
        'hypothesisId': hypothesisId,
        'location':
            'connect_spotify_page.dart:${StackTrace.current.toString().split('\n').first}',
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final file = File(_localLogPath);
      await file.writeAsString(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
        flush: true,
      );
      // Also emit to console so we can capture from flutter run output.
      // #endregion
      // #region agent log
      // ignore: avoid_print
      print('AGENTLOG ${jsonEncode(payload)}');
      // #endregion
    } catch (_) {
      // ignore logging failures
    }
  }

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    context.read<SpotifyBloc>().add(const SpotifyStarted());
    _initDeepLinks();
    _log('H1', 'initState', {});
  }

  @override
  void dispose() {
    _codeController.dispose();
    _linkSub?.cancel();
    _log('H1', 'dispose', {});
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Initial link (if app was cold-started from the deep link).
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        unawaited(_handleIncomingUri(initialUri));
      }
    } catch (_) {}

    // Listen for subsequent deep links.
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) async => _handleIncomingUri(uri),
      onError: (_) {},
    );
  }

  Future<void> _handleIncomingUri(Uri? uri) async {
    if (uri == null) return;
    final status = uri.queryParameters['status'];
    final code = uri.queryParameters['code'];

    if (status == 'success' && mounted) {
      _log('H2', 'received success deep link', {});
      context.read<SpotifyBloc>().add(const SpotifyProfileRequested());
      return;
    }

    if (code != null && code.isNotEmpty && mounted) {
      _log('H2', 'received deep link code', {'codeLen': code.length});
      context.read<SpotifyBloc>().add(SpotifyAuthCodeReceived(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);

    return BlocConsumer<SpotifyBloc, SpotifyState>(
      listenWhen: (previous, current) =>
          previous.authorizeUrl != current.authorizeUrl ||
          previous.status != current.status,
      listener: (context, state) async {
        if (state.status == SpotifyStatus.awaitingCode &&
            state.authorizeUrl != null &&
            state.authorizeUrl != _lastLaunchedUrl) {
          _lastLaunchedUrl = state.authorizeUrl;
          _log('H2', 'launch authorize url', {
            'status': state.status.toString(),
            'authorizeUrl': state.authorizeUrl,
            'lastLaunched': _lastLaunchedUrl,
          });
          await launchUrl(
            Uri.parse(state.authorizeUrl!),
            mode: LaunchMode.externalApplication,
          );
        }
      },
      builder: (context, state) {
        final isBusy =
            state.status == SpotifyStatus.loading ||
            state.status == SpotifyStatus.connecting;
        _log('H3', 'build', {
          'status': state.status.toString(),
          'isBusy': isBusy,
          'hasError': state.error != null,
        });

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Connect Spotify'),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Icon(
                      CupertinoIcons.music_note_2,
                      size: 96,
                      color: cupertinoTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connect your Spotify account',
                      style: cupertinoTheme.textTheme.navTitleTextStyle
                          .copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sync your favorite artists and discover recommendations.',
                      style: cupertinoTheme.textTheme.textStyle.copyWith(
                        color: cupertinoTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CupertinoButton.filled(
                      onPressed: isBusy
                          ? null
                          : () {
                              _log('H1', 'tap connect button', {
                                'status': state.status.toString(),
                              });
                              context.read<SpotifyBloc>().add(
                                const SpotifyAuthorizeRequested(),
                              );
                            },
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: isBusy
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text('Connect to Spotify'),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      onPressed: isBusy
                          ? null
                          : () => context.go(RouteNames.uploadMusic),
                      child: const Text('Upload a local song'),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      onPressed: isBusy
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Paste callback code (for testing)',
                        style: cupertinoTheme.textTheme.textStyle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _codeController,
                      placeholder: 'Enter authorization code',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              final code = _codeController.text.trim();
                              if (code.isNotEmpty) {
                                context.read<SpotifyBloc>().add(
                                  SpotifyAuthCodeReceived(code),
                                );
                              }
                            },
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text('Submit code'),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: CupertinoColors.systemRed.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_circle,
                              color: CupertinoColors.systemRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.error ?? 'Something went wrong',
                                style: cupertinoTheme.textTheme.textStyle
                                    .copyWith(
                                      color: CupertinoColors.systemRed,
                                    ),
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(24, 24),
                              onPressed: () => context.read<SpotifyBloc>().add(
                                const SpotifyClearErrorRequested(),
                              ),
                              child: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                size: 18,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

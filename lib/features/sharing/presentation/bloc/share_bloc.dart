import 'dart:ui' show Rect;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_caption.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_content.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_image.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_outcome.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_request.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_target.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_card_renderer.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_repository.dart';
import 'package:moodtune_app/features/sharing/domain/share_failures.dart';

part 'share_event.dart';
part 'share_state.dart';

/// Builds the caption for [content] and [target]; the presentation layer
/// supplies one backed by `AppLocalizations`.
typedef ShareCaptionBuilder =
    ShareCaption Function(ShareContent content, ShareTarget target);

/// Drives the share sheet: lists the available targets, renders the card
/// once, hands it to the chosen target and reports the outcome (R1, R3,
/// R9, R10).
class ShareBloc extends Bloc<ShareEvent, ShareState> {
  ShareBloc({
    required ShareRepository repository,
    required ShareCardRenderer renderer,
    required ShareCaptionBuilder captionBuilder,
  }) : _repository = repository,
       _renderer = renderer,
       _captionBuilder = captionBuilder,
       super(const ShareState()) {
    on<ShareOpened>(_onOpened);
    on<ShareTargetSelected>(_onTargetSelected);
  }

  final ShareRepository _repository;
  final ShareCardRenderer _renderer;
  final ShareCaptionBuilder _captionBuilder;

  /// The card is the same for every target, so it is rendered once per
  /// sheet.
  ShareImage? _image;

  Future<void> _onOpened(ShareOpened event, Emitter<ShareState> emit) async {
    talker.info('share_opened');
    _image = null;
    emit(
      ShareState(status: ShareStatus.loadingTargets, content: event.content),
    );
    final targets = <ShareTarget>[
      for (final target in ShareTarget.values)
        if (await _repository.isAvailable(target)) target,
    ];
    emit(state.copyWith(status: ShareStatus.ready, targets: targets));
  }

  Future<void> _onTargetSelected(
    ShareTargetSelected event,
    Emitter<ShareState> emit,
  ) async {
    final content = state.content;
    if (content == null || state.isSharing) return;
    final target = event.target;
    talker.info('share_target_selected {target: ${target.name}}');
    emit(state.copyWith(status: ShareStatus.sharing, activeTarget: target));

    final ShareImage image;
    try {
      image = _image ??= await _renderer.render(content);
      // Layout and engine problems surface as Errors (FlutterError,
      // StateError), and a failed render must never take the results page
      // down (R10), so everything is caught here.
      // ignore: avoid_catches_without_on_clauses
    } catch (e, stack) {
      talker.error('share: render failed', e, stack);
      _complete(emit, target, failure: ShareRenderFailure(e.toString()));
      return;
    }

    final colors = MoodTheme.colorsFor(content.mood);
    final result = await _repository.share(
      ShareRequest(
        target: target,
        image: image,
        caption: _captionBuilder(content, target),
        backgroundTopColor: colors.background.toARGB32(),
        backgroundBottomColor: colors.backgroundEnd.toARGB32(),
        sharePositionOrigin: event.origin,
      ),
    );
    result.fold(
      (failure) => _complete(emit, target, failure: failure),
      (outcome) => _complete(emit, target, outcome: outcome),
    );
  }

  void _complete(
    Emitter<ShareState> emit,
    ShareTarget target, {
    ShareOutcome? outcome,
    Failure? failure,
  }) {
    final success = outcome == ShareOutcome.completed;
    talker.info(
      'share_completed {target: ${target.name}, success: $success}'
      '${failure == null ? '' : ' failure: ${failure.message}'}',
    );
    emit(
      state.copyWith(
        status: failure == null ? ShareStatus.done : ShareStatus.failure,
        activeTarget: target,
        outcome: outcome,
        failure: failure,
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';

// Same warm wireframe palette as the results page.
const _cardBackground = Color(0xFFFFFCF5);
const _cardBorder = Color(0xFFE4DCCB);
const _textPrimary = Color(0xFF2D2A26);
const _textSecondary = Color(0xFF6B6256);
const _textMuted = Color(0xFF8A8275);

enum _PromptStep { asking, picking, answered }

/// "Does this feel right?" with thumbs up / down for the results screen.
///
/// Thumbs up calls [onAgree]. Thumbs down reveals the four [MoodIdentity]
/// buckets; picking one calls [onDisagree]. Either answer switches to a
/// short thank-you and the prompt can't be answered again.
///
/// Pass [displayedMood] (the bucket the hero card shows) to leave it out of
/// the picker, since choosing it would contradict the thumbs down.
class MoodFeedbackPrompt extends StatefulWidget {
  const MoodFeedbackPrompt({
    required this.onAgree,
    required this.onDisagree,
    this.displayedMood,
    super.key,
  });

  final VoidCallback onAgree;
  final ValueChanged<MoodIdentity> onDisagree;
  final MoodIdentity? displayedMood;

  @override
  State<MoodFeedbackPrompt> createState() => _MoodFeedbackPromptState();
}

class _MoodFeedbackPromptState extends State<MoodFeedbackPrompt> {
  _PromptStep _step = _PromptStep.asking;

  void _agree() {
    if (_step == _PromptStep.answered) return;
    setState(() => _step = _PromptStep.answered);
    widget.onAgree();
  }

  void _toggleDisagree() {
    if (_step == _PromptStep.answered) return;
    setState(() {
      _step = _step == _PromptStep.picking
          ? _PromptStep.asking
          : _PromptStep.picking;
    });
  }

  void _pick(MoodIdentity mood) {
    if (_step != _PromptStep.picking) return;
    setState(() => _step = _PromptStep.answered);
    widget.onDisagree(mood);
  }

  @override
  Widget build(BuildContext context) {
    final content = _step == _PromptStep.answered
        ? const _ThankYou()
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Question(
                disagreeSelected: _step == _PromptStep.picking,
                onAgree: _agree,
                onDisagree: _toggleDisagree,
              ),
              if (_step == _PromptStep.picking) ...[
                const SizedBox(height: 12),
                _MoodPicker(
                  moods: [
                    for (final mood in MoodIdentity.values)
                      if (mood != widget.displayedMood) mood,
                  ],
                  onPick: _pick,
                ),
              ],
            ],
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      // AnimatedSize asserts with a zero duration, so reduced motion skips
      // it entirely rather than passing Duration.zero.
      child: MediaQuery.of(context).disableAnimations
          ? content
          : AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: content,
            ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.disagreeSelected,
    required this.onAgree,
    required this.onDisagree,
  });

  final bool disagreeSelected;
  final VoidCallback onAgree;
  final VoidCallback onDisagree;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Does this feel right?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ),
        _ThumbButton(
          icon: CupertinoIcons.hand_thumbsup,
          semanticLabel: 'Yes, this feels right',
          onPressed: onAgree,
        ),
        const SizedBox(width: 8),
        _ThumbButton(
          icon: disagreeSelected
              ? CupertinoIcons.hand_thumbsdown_fill
              : CupertinoIcons.hand_thumbsdown,
          semanticLabel: 'No, this feels off',
          selected: disagreeSelected,
          onPressed: onDisagree,
        ),
      ],
    );
  }
}

class _ThumbButton extends StatelessWidget {
  const _ThumbButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? _textPrimary : null,
            border: Border.all(color: selected ? _textPrimary : _cardBorder),
          ),
          child: Icon(
            icon,
            size: 20,
            color: selected ? _cardBackground : _textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MoodPicker extends StatelessWidget {
  const _MoodPicker({required this.moods, required this.onPick});

  final List<MoodIdentity> moods;
  final ValueChanged<MoodIdentity> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'What does it feel like?',
          style: TextStyle(fontSize: 13, color: _textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood in moods)
              _MoodOption(mood: mood, onTap: () => onPick(mood)),
          ],
        ),
      ],
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({required this.mood, required this.onTap});

  final MoodIdentity mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MoodTheme.colorsFor(mood);
    final label = MoodTheme.shortLabel(mood);

    return Semantics(
      button: true,
      label: '$label, ${MoodTheme.quadrantLabel(mood)}',
      excludeSemantics: true,
      child: CupertinoButton(
        key: ValueKey('mood_feedback_option_${mood.name}'),
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.tagBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.accent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(MoodTheme.iconFor(mood), size: 16, color: colors.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThankYou extends StatelessWidget {
  const _ThankYou();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(CupertinoIcons.checkmark_circle_fill, size: 20, color: _textMuted),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Thanks! That helps MoodTune learn.',
            style: TextStyle(fontSize: 14, color: _textSecondary),
          ),
        ),
      ],
    );
  }
}

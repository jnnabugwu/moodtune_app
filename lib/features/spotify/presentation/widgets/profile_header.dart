import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';

class SpotifyProfileHeader extends StatelessWidget {
  const SpotifyProfileHeader({required this.profile, super.key});

  final SpotifyProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final initial = profile.displayName.isNotEmpty
        ? profile.displayName.characters.first
        : profile.username.characters.first;

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            image: profile.avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(profile.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: profile.avatarUrl == null
              ? Text(
                  initial.toUpperCase(),
                  style: theme.textTheme.navTitleTextStyle.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.displayName,
              style: theme.textTheme.navTitleTextStyle
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              profile.username,
              style: theme.textTheme.textStyle.copyWith(
                color: theme.textTheme.textStyle.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

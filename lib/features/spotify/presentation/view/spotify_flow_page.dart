import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';
import 'package:moodtune_app/features/spotify/presentation/view/connect_spotify_page.dart';
import 'package:moodtune_app/features/spotify/presentation/view/profile_page.dart';

class SpotifyFlowPage extends StatelessWidget {
  const SpotifyFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpotifyBloc, SpotifyState>(
      builder: (context, state) {
        if (state.status == SpotifyStatus.connected && state.profile != null) {
          return const SpotifyProfilePage();
        }

        return const ConnectSpotifyPage();
      },
    );
  }
}

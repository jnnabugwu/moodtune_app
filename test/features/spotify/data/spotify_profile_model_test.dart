import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/spotify/data/models/spotify_profile_model.dart';

void main() {
  test('SpotifyProfileModel parses backend profile shape', () {
    const json = {
      'id': 'user123',
      'display_name': 'Test User',
      'email': 'user@test.com',
      'image_url': 'https://img.test/avatar.jpg',
      'followers': {'total': 42},
      'product': 'premium',
    };

    final model = SpotifyProfileModel.fromJson(json);

    expect(model.id, 'user123');
    expect(model.displayName, 'Test User');
    expect(model.username, 'user123');
    expect(model.avatarUrl, 'https://img.test/avatar.jpg');
    expect(model.followersCount, 42);
    expect(model.playlistsCount, 0);
    expect(model.email, 'user@test.com');
  });
}

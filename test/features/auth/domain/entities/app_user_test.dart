import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppUser', () {
    test('supports value equality on id and email', () {
      expect(
        const AppUser(id: '1', email: 'a@b.c'),
        const AppUser(id: '1', email: 'a@b.c'),
      );
      expect(
        const AppUser(id: '1', email: 'a@b.c'),
        isNot(const AppUser(id: '2', email: 'a@b.c')),
      );
      expect(
        const AppUser(id: '1', email: 'a@b.c'),
        isNot(const AppUser(id: '1', email: 'x@b.c')),
      );
    });

    test('props are [id, email]', () {
      expect(const AppUser(id: '1', email: 'a@b.c').props, ['1', 'a@b.c']);
    });
  });
}

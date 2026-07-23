import 'package:flutter_test/flutter_test.dart';
import 'package:localmsg/design/colors.dart';

void main() {
  test('avatarColorFor is deterministic for a given id', () {
    final color1 = AppColors.avatarColorFor('peer-123');
    final color2 = AppColors.avatarColorFor('peer-123');
    expect(color1, equals(color2));
  });

  test('avatarColorFor always returns one of the defined palette hues', () {
    for (final id in ['a', 'peer-1', 'peer-2', 'some-uuid-4321']) {
      expect(AppColors.avatarHues, contains(AppColors.avatarColorFor(id)));
    }
  });
}

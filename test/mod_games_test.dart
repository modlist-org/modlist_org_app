import 'package:flutter_test/flutter_test.dart';
import 'package:modlist_org_app/src/models/mod_model.dart';

void main() {
  test('parses multi-game mods with primary game first', () {
    final mod = ModItem.fromJson({
      'name': 'Multi',
      'game': 'rhythm-doctor',
      'games': ['adofai', 'rhythm-doctor'],
    });
    expect(mod.game, 'rhythm-doctor');
    expect(mod.games, ['rhythm-doctor', 'adofai']);
    expect(mod.supportsGame('adofai'), isTrue);
    expect(mod.supportsGame('dancing-line'), isFalse);
  });

  test('falls back to [game] when games is missing', () {
    final mod = ModItem.fromJson({'name': 'Legacy', 'game': 'adofai'});
    expect(mod.games, ['adofai']);
    expect(mod.copyWith().games, ['adofai']);
  });

  test('uses games.first when game is missing', () {
    final mod = ModItem.fromJson({
      'name': 'NoPrimary',
      'games': ['dancing-line', 'adofai'],
    });
    expect(mod.game, 'dancing-line');
    expect(mod.games, ['dancing-line', 'adofai']);
  });
}

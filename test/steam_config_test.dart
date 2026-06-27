import 'package:flutter_test/flutter_test.dart';
import 'package:modlist_org_app/src/core/steam_config.dart';

/// Wraps an `apps` block body in the rest of a minimal localconfig.vdf tree.
String wrap(String appsBody) =>
    '"UserLocalConfigStore"\n'
    '{\n'
    '\t"Software"\n'
    '\t{\n'
    '\t\t"Valve"\n'
    '\t\t{\n'
    '\t\t\t"Steam"\n'
    '\t\t\t{\n'
    '\t\t\t\t"apps"\n'
    '\t\t\t\t{\n'
    '$appsBody\n'
    '\t\t\t\t}\n'
    '\t\t\t}\n'
    '\t\t}\n'
    '\t}\n'
    '}\n';

/// An app block with the given id and an explicit LaunchOptions value.
String appWithLaunch(String id, String value) =>
    '\t\t\t\t\t"$id"\n'
    '\t\t\t\t\t{\n'
    '\t\t\t\t\t\t"LastPlayed"\t\t"1700000000"\n'
    '\t\t\t\t\t\t"LaunchOptions"\t\t"$value"\n'
    '\t\t\t\t\t}';

/// An app block with the given id and no LaunchOptions key.
String appNoLaunch(String id) =>
    '\t\t\t\t\t"$id"\n'
    '\t\t\t\t\t{\n'
    '\t\t\t\t\t\t"LastPlayed"\t\t"1700000001"\n'
    '\t\t\t\t\t}';

void main() {
  group('SteamConfig.setLaunchOptionsInVdf', () {
    test('replaces an existing LaunchOptions value in the target app block', () {
      final vdf = wrap(appWithLaunch('977950', 'OLDVALUE'));
      final out = SteamConfig.setLaunchOptionsInVdf(
        vdf,
        appId: '977950',
        escapedValue: 'NEWVAL',
      );
      expect(out, isNotNull);
      expect(out, contains('"NEWVAL"'));
      expect(out, isNot(contains('OLDVALUE')));
      // Exactly one LaunchOptions value, not duplicated.
      expect('NEWVAL'.allMatches(out!).length, 1);
    });

    test('inserts LaunchOptions when the app block has none', () {
      final vdf = wrap(appNoLaunch('774181'));
      final out = SteamConfig.setLaunchOptionsInVdf(
        vdf,
        appId: '774181',
        escapedValue: 'NEWVAL',
      );
      expect(out, isNotNull);
      expect(out, contains('"LaunchOptions"'));
      expect(out, contains('"NEWVAL"'));
      // The pre-existing key in the block is preserved.
      expect(out, contains('"LastPlayed"'));
    });

    test('inserts a new app block when the id is absent', () {
      final vdf = wrap(appWithLaunch('111111', 'OTHER'));
      final out = SteamConfig.setLaunchOptionsInVdf(
        vdf,
        appId: '977950',
        escapedValue: 'NEWVAL',
      );
      expect(out, isNotNull);
      expect(out, contains('"977950"'));
      expect(out, contains('"NEWVAL"'));
      // The unrelated existing app is left intact.
      expect(out, contains('"111111"'));
      expect(out, contains('OTHER'));
    });

    test('returns null when there is no apps block', () {
      const vdf = '"UserLocalConfigStore"\n{\n\t"Friends"\n\t{\n\t}\n}\n';
      final out = SteamConfig.setLaunchOptionsInVdf(
        vdf,
        appId: '977950',
        escapedValue: 'NEWVAL',
      );
      expect(out, isNull);
    });

    test('only edits the id inside the apps block, ignoring decoys outside', () {
      // A stray "977950" block sits in an unrelated section before apps.
      final vdf = '"UserLocalConfigStore"\n'
          '{\n'
          '\t"apptickets"\n'
          '\t{\n'
          '\t\t"977950"\n'
          '\t\t{\n'
          '\t\t\t"LaunchOptions"\t\t"DECOY"\n'
          '\t\t}\n'
          '\t}\n'
          '${_appsTree(appWithLaunch('977950', 'REALOLD'))}'
          '}\n';
      final out = SteamConfig.setLaunchOptionsInVdf(
        vdf,
        appId: '977950',
        escapedValue: 'NEWVAL',
      );
      expect(out, isNotNull);
      // The real in-apps value is replaced...
      expect(out, contains('"NEWVAL"'));
      expect(out, isNot(contains('REALOLD')));
      // ...and the decoy outside apps is untouched.
      expect(out, contains('DECOY'));
    });

    test('is case-insensitive for Apps and LaunchOptions keys', () {
      final vdf = wrap(
        '\t\t\t\t\t"977950"\n'
        '\t\t\t\t\t{\n'
        '\t\t\t\t\t\t"launchoptions"\t\t"OLDVALUE"\n'
        '\t\t\t\t\t}',
      ).replaceFirst('"apps"', '"Apps"');
      final out = SteamConfig.setLaunchOptionsInVdf(
        vdf,
        appId: '977950',
        escapedValue: 'NEWVAL',
      );
      expect(out, isNotNull);
      expect(out, contains('"NEWVAL"'));
      expect(out, isNot(contains('OLDVALUE')));
    });

    test('locates the value past escaped quotes (macOS-style value)', () {
      // Simulate a value already containing escaped quotes, then re-set it.
      final escaped = r'\"/Users/me/game/setup_helper.sh\" %command%';
      final vdf = wrap(appWithLaunch('977950', escaped));
      final out = SteamConfig.setLaunchOptionsInVdf(
        vdf,
        appId: '977950',
        escapedValue: 'REPLACED',
      );
      expect(out, isNotNull);
      expect(out, contains('"REPLACED"'));
      expect(out, isNot(contains('setup_helper.sh')));
      // The trailing %command% from the old value must be gone too.
      expect('%command%'.allMatches(out!).length, 0);
    });
  });

  group('SteamConfig.clearLaunchOptionsInVdf', () {
    test('blanks our wrapper value', () {
      final vdf = wrap(appWithLaunch('977950', './setup_helper.sh %command%'));
      final out = SteamConfig.clearLaunchOptionsInVdf(vdf, appId: '977950');
      expect(out, isNotNull);
      expect(out, isNot(contains('setup_helper.sh')));
      expect(out, contains('"LaunchOptions"\t\t""'));
    });

    test('blanks a Proton WINEDLLOVERRIDES wrapper value', () {
      final vdf = wrap(
        appWithLaunch('4395300', r'WINEDLLOVERRIDES=\"winhttp=n,b\" %command%'),
      );
      final out = SteamConfig.clearLaunchOptionsInVdf(vdf, appId: '4395300');
      expect(out, isNotNull);
      expect(out, isNot(contains('WINEDLLOVERRIDES')));
    });

    test('leaves a user custom (non-wrapper) value untouched', () {
      final vdf = wrap(appWithLaunch('977950', 'gamemoderun %command%'));
      final out = SteamConfig.clearLaunchOptionsInVdf(vdf, appId: '977950');
      expect(out, isNull);
    });

    test('returns null when the app block is absent', () {
      final vdf = wrap(appWithLaunch('111111', './setup_helper.sh %command%'));
      final out = SteamConfig.clearLaunchOptionsInVdf(vdf, appId: '977950');
      expect(out, isNull);
    });
  });
}

/// Builds just the Software→Valve→Steam→apps subtree (used to compose a file
/// that also has unrelated sections alongside it).
String _appsTree(String appsBody) =>
    '\t"Software"\n'
    '\t{\n'
    '\t\t"Valve"\n'
    '\t\t{\n'
    '\t\t\t"Steam"\n'
    '\t\t\t{\n'
    '\t\t\t\t"apps"\n'
    '\t\t\t\t{\n'
    '$appsBody\n'
    '\t\t\t\t}\n'
    '\t\t\t}\n'
    '\t\t}\n'
    '\t}\n';

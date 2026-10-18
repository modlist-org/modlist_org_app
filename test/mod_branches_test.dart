import 'package:flutter_test/flutter_test.dart';
import 'package:modlist_org_app/src/models/mod_model.dart';

Map<String, dynamic> _version(String v, {Object? loaders, Object? generic, String? branchId}) => {
      'version': v,
      'changelog': '',
      'isApproved': true,
      'createdAt': '',
      'branchId': ?branchId,
      'availableLoaders': ?loaders,
      'hasGenericDownload': ?generic,
    };

Map<String, dynamic> _json({Object? branches, Object? organization}) => {
      '_id': 'x',
      'name': 'Mod',
      'slug': 'mod',
      'summary': 'Summary',
      'game': 'adofai',
      'downloads': 0,
      'latestVersion': _version('1.0.0', branchId: 'main'),
      'branches': ?branches,
      'defaultBranchId': ?(branches == null ? null : 'main'),
      'betaBranchId': ?(branches == null ? null : 'beta'),
      'organization': ?organization,
    };

void main() {
  test('parses branches sorted by position, ids and organization', () {
    final mod = ModItem.fromJson(_json(
      branches: [
        {'_id': 'beta', 'name': 'Beta', 'isBeta': true, 'position': 1, 'latestVersion': _version('2.0.0-b', branchId: 'beta')},
        {'_id': 'main', 'name': 'Main', 'isDefault': true, 'position': 0, 'latestVersion': _version('1.0.0', branchId: 'main')},
      ],
      organization: {'_id': 'o', 'name': 'Team', 'slug': 'team', 'memberIds': []},
    ));
    expect(mod.branches.map((b) => b.id), ['main', 'beta']);
    expect(mod.defaultBranchId, 'main');
    expect(mod.isBetaBranch('beta'), isTrue);
    expect(mod.latestVersionForBranch('beta')?.version, '2.0.0-b');
    expect(mod.latestVersionForBranch(null)?.version, '1.0.0');
    expect(mod.latestVersionForBranch('gone')?.version, '1.0.0');
    expect(mod.organization?.name, 'Team');
    expect(mod.copyWith().branches.length, 2);
  });

  test('old servers without branches, loaders or organization still parse', () {
    final mod = ModItem.fromJson(_json());
    expect(mod.branches, isEmpty);
    expect(mod.betaBranchId, isNull);
    expect(mod.organization, isNull);
    expect(mod.latestVersion!.isInstallableWithMelonLoader, isTrue);
  });

  test('installable with MelonLoader only via generic link or melonloader file', () {
    expect(ModVersion.fromJson(_version('1', loaders: ['melonloader'], generic: false)).isInstallableWithMelonLoader, isTrue);
    expect(ModVersion.fromJson(_version('1', loaders: <String>[], generic: true)).isInstallableWithMelonLoader, isTrue);
    expect(ModVersion.fromJson(_version('1', loaders: ['bepinex', 'umm'], generic: false)).isInstallableWithMelonLoader, isFalse);
  });

  test('InstalledMod branchId roundtrips and is null for old data', () {
    final mod = InstalledMod(id: 'm', slug: 'm', name: 'M', version: '1', isBeta: false, installedAt: '', installedFiles: const [], branchId: 'beta');
    expect(InstalledMod.fromJson(mod.toJson()).branchId, 'beta');
    expect(InstalledMod.fromJson({'id': 'm', 'slug': 'm'}).branchId, isNull);
  });

  test('organization-owned mods credit only people outside the organization', () {
    Map<String, dynamic> user(String id) => {'_id': id, 'username': id};
    final json = _json(organization: {'_id': 'o', 'name': 'Team', 'slug': 'team', 'logo': '/logos/t.webp', 'memberIds': ['a', 'm']})
      ..['authorId'] = user('a')
      ..['collaboratorIds'] = [user('m'), user('out')];
    final mod = ModItem.fromJson(json);
    expect(mod.organization?.logo, '/logos/t.webp');
    expect(mod.creditedPeople.map((p) => p.id), ['out']);
    expect(ModItem.fromJson(_json()..['authorId'] = user('a')).creditedPeople.map((p) => p.id), ['a']);
  });
}

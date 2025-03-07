/*
 * Copyright © 2020 Birju Vachhani
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:spider/src/constants.dart';
import 'package:spider/src/process_terminator.dart';
import 'package:spider/src/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  final MockProcessTerminator processTerminatorMock = MockProcessTerminator();
  const Map<String, dynamic> testConfig = {
    "generate_tests": false,
    "no_comments": true,
    "export": true,
    "use_part_of": true,
    "use_references_list": true,
    "package": "resources",
    "groups": [
      {
        "path": "assets/images",
        "class_name": "Assets",
        "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
      }
    ]
  };

  group('Utils tests', () {
    test('extension formatter test', () {
      expect('.png', formatExtension('png'));
      expect('.jpg', formatExtension('.jpg'));
    });

    test('process terminator singleton test', () {
      expect(ProcessTerminator.getInstance(),
          equals(ProcessTerminator.getInstance()));
      expect(
          identical(
              ProcessTerminator.getInstance(), ProcessTerminator.getInstance()),
          isTrue);
    });

    test('checkFlutterProject test', () async {
      ProcessTerminator.setMock(processTerminatorMock);

      addTearDown(() async {
        await File(p.join(Directory.current.path, 'pubspec.txt'))
            .rename('pubspec.yaml');
        reset(processTerminatorMock);
      });

      checkFlutterProject();
      verifyNever(processTerminatorMock.terminate(any, any));

      await File(p.join(Directory.current.path, 'pubspec.yaml'))
          .rename('pubspec.txt');
      checkFlutterProject();
      verify(processTerminatorMock.terminate(
              ConsoleMessages.notFlutterProjectError, any))
          .called(1);
    });

    test('getReference test', () async {
      expect(
          getReference(
            properties: 'static const',
            assetName: 'avatar',
            assetPath: 'assets/images/avatar.png',
          ),
          equals("static const String avatar = 'assets/images/avatar.png';"));
    });

    test('getTestCase test', () async {
      expect(getTestCase('Images', 'avatar'),
          equals("expect(File(Images.avatar).existsSync(), true);"));
    });

    test('writeToFile test', () async {
      writeToFile(name: 'test.txt', path: 'resources', content: 'Hello');
      final file = File('lib/resources/test.txt');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), equals('Hello'));

      addTearDown(() {
        file.deleteSync();
        Directory('lib/resources').deleteSync();
      });
    });

    test('getExportContent test', () async {
      expect(getExportContent(fileNames: ['test.dart'], noComments: true),
          equals("export 'test.dart';"));

      expect(getExportContent(fileNames: ['test.dart'], noComments: false),
          contains('Generated by spider'));

      expect(
          getExportContent(
              fileNames: ['test.dart'], noComments: true, usePartOf: true),
          equals("part 'test.dart';"));
    });
  });

  group('parse config tests', () {
    setUp(() {
      ProcessTerminator.setMock(processTerminatorMock);
    });

    test('no config file test', () async {
      parseConfig('');
      verify(processTerminatorMock.terminate(
              ConsoleMessages.configNotFound, any))
          .called(1);
    });

    test('empty yaml config file test', () async {
      File('spider.yaml').createSync();

      parseConfig('');
      verify(processTerminatorMock.terminate(
              ConsoleMessages.invalidConfigFile, any))
          .called(1);
    });

    test('empty yml config file test', () async {
      File('spider.yml').createSync();

      parseConfig('');
      verify(processTerminatorMock.terminate(
              ConsoleMessages.invalidConfigFile, any))
          .called(1);
    });

    test('empty json config file test', () async {
      File('spider.json').writeAsStringSync('{}');

      parseConfig('');
      verify(processTerminatorMock.terminate(
              ConsoleMessages.invalidConfigFile, any))
          .called(1);
    });

    test('invalid json config file test', () async {
      File('spider.json').createSync();

      parseConfig('');
      verify(processTerminatorMock.terminate(ConsoleMessages.parseError, any))
          .called(1);
    });

    test('valid config file test', () async {
      createTestConfigs(testConfig);
      createTestAssets();
      var config = parseConfig('');
      expect(config, isNotNull,
          reason: 'valid config file should not return null but it did.');

      expect(config!.groups, isNotEmpty);
      expect(config.groups.length, testConfig['groups'].length);
      expect(config.globals.generateTests, testConfig['generate_tests']);
      expect(config.globals.noComments, testConfig['no_comments']);
      expect(config.globals.export, testConfig['export']);
      expect(config.globals.usePartOf, testConfig['use_part_of']);
      expect(config.globals.package, testConfig['package']);

      createTestConfigs(testConfig.copyWith({'generate_tests': true}));
      config = parseConfig('')!;
      expect(config.globals.generateTests, isTrue);
      expect(config.globals.projectName, isNotNull);
      expect(config.globals.projectName, isNotEmpty);
      expect(config.globals.projectName, equals('spider'));
    });

    tearDown(() {
      deleteConfigFiles();
      reset(processTerminatorMock);
    });
  });

  group('validateConfigs tests', () {
    setUp(() {
      ProcessTerminator.setMock(processTerminatorMock);
    });

    test('config with no groups test', () async {
      validateConfigs(testConfig.except('groups'));
      verify(processTerminatorMock.terminate(
              ConsoleMessages.noGroupsFound, any))
          .called(1);
    });

    test('config with no groups test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': true, // invalid group type.
      }));
      verify(processTerminatorMock.terminate(
              ConsoleMessages.invalidGroupsType, any))
          .called(1);
    });

    test('config group with null data test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': [
          {
            "path": null, // null data
            "class_name": "Assets",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          }
        ],
      }));
      verify(processTerminatorMock.terminate(
              sprintf(ConsoleMessages.nullValueError, ['path']), any))
          .called(1);
    });

    test('config group with no path test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': [
          {
            "class_name": "Assets",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          }
        ],
      }));
      verify(processTerminatorMock.terminate(
              ConsoleMessages.noPathInGroupError, any))
          .called(1);
    });

    test('config group path with wildcard test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': [
          {
            "path": "assets/*",
            "class_name": "Assets",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          }
        ],
      }));
      verify(processTerminatorMock.terminate(
              sprintf(ConsoleMessages.noWildcardInPathError, ['assets/*']),
              any))
          .called(1);
    });

    test('config group with non-existent path test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': [
          {
            "path": "assets/fonts",
            "class_name": "Assets",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          }
        ],
      }));
      verify(processTerminatorMock.terminate(
              sprintf(ConsoleMessages.pathNotExistsError, ['assets/fonts']),
              any))
          .called(1);
    });

    test('config group path with invalid directory test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': [
          {
            "path": "assets/images/test1.png",
            "class_name": "Assets",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          }
        ],
      }));
      createTestAssets();

      verify(processTerminatorMock.terminate(
              sprintf(ConsoleMessages.pathNotExistsError,
                  ['assets/images/test1.png']),
              any))
          .called(1);
    });

    test('config group with class name null test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': [
          {
            "path": "assets/images",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          }
        ],
      }));
      createTestAssets();

      verify(processTerminatorMock.terminate(
              ConsoleMessages.noClassNameError, any))
          .called(1);
    });

    test('config group with empty class name test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': [
          {
            "path": "assets/images",
            "class_name": "   ",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          }
        ],
      }));
      createTestAssets();

      verify(processTerminatorMock.terminate(
              ConsoleMessages.emptyClassNameError, any))
          .called(1);
    });

    test('config group with invalid class name test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': [
          {
            "path": "assets/images",
            "class_name": "My Assets",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          }
        ],
      }));
      createTestAssets();

      verify(processTerminatorMock.terminate(
              ConsoleMessages.classNameContainsSpacesError, any))
          .called(1);
    });

    test('config group with invalid paths data test', () async {
      validateConfigs(testConfig.copyWith({
        'groups': [
          {
            "paths": "assets/images",
            "class_name": "Assets",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          }
        ],
      }));
      createTestAssets();

      verify(processTerminatorMock.terminate(
              ConsoleMessages.configValidationFailed, any))
          .called(1);
    });

    tearDown(() {
      reset(processTerminatorMock);
      deleteConfigFiles();
      deleteTestAssets();
    });
  });
}

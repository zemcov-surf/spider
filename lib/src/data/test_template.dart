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

/// A template for generating file author line.
String get timeStampTemplate => '/// Generated by spider on [TIME]\n\n';

/// A template for generating test files.
String get testTemplate => '''import 'dart:io';

import 'package:[PROJECT_NAME]/[PACKAGE]/[IMPORT_FILE_NAME]';
import 'package:test/test.dart';

void main() {
  test('[FILE_NAME] assets test', () {
    [TESTS]
  });
}''';

/// A template for generating single test expect statement.
String get expectTestTemplate =>
    'expect(File([CLASS_NAME].[ASSET_NAME]).existsSync(), true);';

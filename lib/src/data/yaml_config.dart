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

/// A template for `yaml` config file generation.
const String YAML_CONFIGS = '''# Generated by Spider

# Generates unit tests to verify that the assets exists in assets directory
generate_tests: true

# Use this to remove vcs noise created by the `generated` comments in dart code
no_comments: true

# Exports all the generated file as the one library
export: true

# This allows you to import all the generated references with 1 single import!
use_part_of: true

# Generates a variable that contains a list of all asset values.
use_references_list: false

# Location where all the generated references will be stored
package: resources

groups:
  - path: assets/images
    class_name: Images
    types: [ .png, .jpg, .jpeg, .webp, .webm, .bmp ]
#  - path: assets/vectors
#    class_name: Svgs
#    package: res
#    types: [ .svg ]''';

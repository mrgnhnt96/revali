// --- LICENSE ---
/**
Copyright 2024 CouchSurfing International Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
import 'package:zora_annotations/zora_annotations.dart';

// --- LICENSE ---
import 'type_checker.dart';

final controllerChecker =
    TypeChecker.fromName('$Controller', packageName: 'zora_annotations');
final methodChecker =
    TypeChecker.fromName('$Method', packageName: 'zora_annotations');
final middlewareChecker =
    TypeChecker.fromName('$Middleware', packageName: 'zora_annotations');

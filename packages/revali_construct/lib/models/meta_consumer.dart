import 'package:revali_construct/models/meta_method.dart';
import 'package:revali_construct/models/meta_param.dart';

/// A method annotated with `@Consumes`.
///
/// Kept separate from [MetaMethod] rather than folded into it: a consumer has
/// no HTTP verb, no path and no request to bind from, so every field they
/// would share is one that does not apply.
class MetaConsumer {
  const MetaConsumer({
    required this.name,
    required this.topic,
    required this.group,
    required this.params,
  });

  /// The Dart method name.
  final String name;

  final String topic;
  final String group;

  /// The handler's parameters.
  ///
  /// Only an optional `BrokerMessage` is supported today; anything else is
  /// rejected at generation time rather than producing code that does not
  /// compile.
  final List<MetaParam> params;
}

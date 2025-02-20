// ignore_for_file: unused_element

import 'package:code_builder/code_builder.dart';

class _BinaryExpression extends Expression implements BinaryExpression {
  const _BinaryExpression._(
    this.left,
    this.right,
    this.operator, {
    this.addSpace = true,
    this.isConst = false,
  });

  @override
  final Expression left;
  @override
  final Expression right;
  @override
  final String operator;
  @override
  final bool addSpace;
  @override
  final bool isConst;

  @override
  R accept<R>(ExpressionVisitor<R> visitor, [R? context]) =>
      visitor.visitBinaryExpression(this, context);
}

class _LiteralExpression extends Expression implements LiteralExpression {
  const _LiteralExpression._(this.literal);

  @override
  final String literal;

  @override
  R accept<R>(ExpressionVisitor<R> visitor, [R? context]) =>
      visitor.visitLiteralExpression(this, context);

  @override
  String toString() => literal;
}

extension ExpressionX on Expression {
  Expression get yielded => _BinaryExpression._(
        const _LiteralExpression._('yield'),
        this,
        '',
      );

  Expression get yieldedStar => _BinaryExpression._(
        const _LiteralExpression._('yield*'),
        this,
        '',
      );
}

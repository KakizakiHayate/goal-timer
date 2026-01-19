import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns against using force unwrap (!) operator.
class AvoidForceUnwrap extends DartLintRule {
  const AvoidForceUnwrap() : super(code: _code);

  static const _code = LintCode(
    name: 'tanzam_avoid_force_unwrap',
    problemMessage: '強制アンラップ(!)の使用は禁止されています。null チェックを使用してください。',
    correctionMessage: 'if文やnull合体演算子(??)を使用してください。',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPostfixExpression((node) {
      // Check for null assertion operator (!)
      if (node.operator.type.lexeme == '!') {
        reporter.atNode(node, code);
      }
    });
  }
}

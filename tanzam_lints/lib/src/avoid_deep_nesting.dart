import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns against deep nesting (more than 2 levels).
class AvoidDeepNesting extends DartLintRule {
  const AvoidDeepNesting() : super(code: _code);

  static const _code = LintCode(
    name: 'tanzam_avoid_deep_nesting',
    problemMessage: 'ネストが深すぎます（最大2階層まで）。早期リターンやメソッド分割を検討してください。',
    correctionMessage: '条件を反転して早期リターンするか、処理を別メソッドに分割してください。',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _maxNestingLevel = 2;

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionBody((node) {
      final visitor = _NestingVisitor(reporter, code);
      node.accept(visitor);
    });
  }
}

class _NestingVisitor extends RecursiveAstVisitor<void> {
  _NestingVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;
  int _currentLevel = 0;

  void _visitNestableNode(AstNode node, void Function() visitChildren) {
    _currentLevel++;
    if (_currentLevel > AvoidDeepNesting._maxNestingLevel) {
      reporter.atNode(node, code);
    }
    visitChildren();
    _currentLevel--;
  }

  @override
  void visitIfStatement(IfStatement node) {
    _visitNestableNode(node, () => super.visitIfStatement(node));
  }

  @override
  void visitForStatement(ForStatement node) {
    _visitNestableNode(node, () => super.visitForStatement(node));
  }

  @override
  void visitForElement(ForElement node) {
    _visitNestableNode(node, () => super.visitForElement(node));
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _visitNestableNode(node, () => super.visitWhileStatement(node));
  }

  @override
  void visitDoStatement(DoStatement node) {
    _visitNestableNode(node, () => super.visitDoStatement(node));
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _visitNestableNode(node, () => super.visitSwitchStatement(node));
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _visitNestableNode(node, () => super.visitSwitchExpression(node));
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Reset nesting level for nested functions (lambdas)
    final previousLevel = _currentLevel;
    _currentLevel = 0;
    super.visitFunctionExpression(node);
    _currentLevel = previousLevel;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Reset nesting level for method declarations
    final previousLevel = _currentLevel;
    _currentLevel = 0;
    super.visitMethodDeclaration(node);
    _currentLevel = previousLevel;
  }
}

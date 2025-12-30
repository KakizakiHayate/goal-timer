library tanzam_lints;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/avoid_deep_nesting.dart';
import 'src/avoid_force_unwrap.dart';

PluginBase createPlugin() => _TanzamLints();

class _TanzamLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const AvoidForceUnwrap(),
        const AvoidDeepNesting(),
      ];
}

import '../../../swagger_parser.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';

/// Provides template for generating dart Provider
String dartProviderTemplate({
  required String name,
  required bool putInFolder,
  required bool markFileAsGenerated,
  required UniversalRestClient restClient,
  String? dioProviderPath,
}) {
  final sb = StringBuffer('''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '${putInFolder ? '../../domain/repositories/' : '../domain/'}${name}_repo.dart';
import '${putInFolder ? '../clients/' : ''}${name}_client.dart';
import '${putInFolder ? '../repositories/' : ''}${name}_repo_impl.dart';
${dioProviderPath != null ? "import '$dioProviderPath';" : ''}

part '${name}_provider.g.dart';

@Riverpod(keepAlive: true)
${name.toPascal}Client ${name.toCamel}Client(Ref ref) {
  return ${name.toPascal}Client(ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
${name.toPascal}Repo ${name.toCamel}Repo(Ref ref) {
  return ${name.toPascal}RepoImpl(ref.watch(${name.toCamel}ClientProvider));
}
''');
  return sb.toString();
}

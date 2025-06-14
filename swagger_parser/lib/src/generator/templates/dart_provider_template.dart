import '../../../swagger_parser.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/encode.dart';

/// Provides template for generating dart Provider
String dartProviderTemplate({
  required String name,
  required bool isMerge,
  required bool mockGen,
  required bool putInFolder,
  required bool markFileAsGenerated,
  required UniversalRestClient restClient,
  String? dioProviderPath,
}) {
  final sb = StringBuffer('''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '${putInFolder ? '../../domain/repositories/' : isMerge ? '../../domain/$name/' : '../domain/'}${name}_repo.dart';
import '${putInFolder ? '../clients/' : '../../../../../gen/'}${isMerge ? '$name/' : ''}${encode('${name}_client').toSnake}.dart';
import '${putInFolder ? '../repositories/' : ''}${name}_repo_impl.dart';
${mockGen ? '' : dioProviderPath != null ? "import '${isMerge ? '../$dioProviderPath' : dioProviderPath}';" : ''}

part '${name}_provider.g.dart';

@Riverpod(keepAlive: true)
${encode('${name.toPascal}Client')} ${name.toCamel}Client(Ref ref) {
${mockGen ? 'return ${name.toPascal}ClientMock();' : 'return ${encode('${name.toPascal}Client')}(ref.watch(dioProvider));'}
}

@Riverpod(keepAlive: true)
${encode('${name.toPascal}Repo')} ${name.toCamel}Repo(Ref ref) {
  return ${encode('${name.toPascal}RepoImpl')}(ref.watch(${name.toCamel}ClientProvider));
}
''');
  return sb.toString();
}

import 'package:collection/collection.dart';
import 'package:yaml/src/yaml_node.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/encode.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart Retrofit client
String dartUseCaseTemplate({
  required String name,
  required bool isMerge,
  required String repoName,
  required bool putInFolder,
  required bool markFileAsGenerated,
  required String defaultContentType,
  required UniversalRestClient restClient,
  required YamlList sendProgress,
  bool originalHttpResponse = false,
  bool extrasParameterByDefault = false,
  bool dioOptionsParameterByDefault = false,
}) {
  final sb = StringBuffer(
    '''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}${_fileImport(restClient)}${_dioImport(restClient, sendProgress)}${getImports(restClient.imports, putInFolder, isMerge, '../../data/')}
import '${putInFolder ? '../repositories/' : ''}${repoName.toSnake}.dart';
''',
  );
  for (final request in restClient.requests) {
    sb.write(
      _toUseCase(
        request,
        repoName,
        defaultContentType,
        originalHttpResponse: originalHttpResponse,
        extrasParameterByDefault: extrasParameterByDefault,
        dioOptionsParameterByDefault: dioOptionsParameterByDefault,
        sendProgress: sendProgress,
      ),
    );
  }
  return sb.toString();
}

String _toUseCase(
  UniversalRequest request,
  String repoName,
  String defaultContentType, {
  required bool originalHttpResponse,
  required bool extrasParameterByDefault,
  required bool dioOptionsParameterByDefault,
  required YamlList sendProgress,
}) {
  final responseType = request.returnType == null
      ? 'void'
      : request.returnType!.toSuitableType(ProgrammingLanguage.dart);
  final sb = StringBuffer(
    '''

  ${descriptionComment(request.description, tabForFirstLine: false, tab: '  ')}${request.isDeprecated ? "@Deprecated('This method is marked as deprecated')\n  " : ''}
  Future<${originalHttpResponse ? 'HttpResponse<$responseType>' : responseType}> ${request.name}UseCase(''',
  );
  if (request.parameters.isNotEmpty ||
      extrasParameterByDefault ||
      dioOptionsParameterByDefault) {
    sb.write('{\n');
  }
  final sortedByRequired = List<UniversalRequestType>.from(
    request.parameters.sorted((a, b) => a.type.compareTo(b.type)),
  );
  for (final parameter in sortedByRequired) {
    sb.write('${_toParameter(parameter)}\n');
  }
  sb.write(
    '${request.parameters.isNotEmpty ? 'required' : ''} ${encode(repoName)} repo,\n',
  );
  if (sendProgress.contains(request.route)) {
    sb.write(
      '    required ProgressCallback onSendProgress,\n',
    );
  }

  if (extrasParameterByDefault) {
    sb.write(_addExtraParameter());
  }
  if (dioOptionsParameterByDefault) {
    sb.write(_addDioOptionsParameter());
  }
  if (request.parameters.isNotEmpty ||
      extrasParameterByDefault ||
      dioOptionsParameterByDefault) {
    sb.write('  })');
  } else {
    sb.write(')');
  }
  sb.writeln(' {\n    return repo.${encode(request.name)}(');

  for (final parameter in sortedByRequired) {
    sb.write('      ${_toConstructor(parameter)}\n');
  }
  if (sendProgress.contains(request.route)) {
    sb.write(
      '    onSendProgress:onSendProgress,\n',
    );
  }

  sb
    ..writeln('    );')
    ..writeln('  }');
  return sb.toString();
}

String _fileImport(UniversalRestClient restClient) => restClient.requests.any(
      (r) => r.parameters.any(
        (e) => e.type.toSuitableType(ProgrammingLanguage.dart).contains('File'),
      ),
    )
        ? "import 'dart:io';\n\n"
        : '';

String _dioImport(UniversalRestClient restClient, YamlList sendProgress) =>
    restClient.requests.any(
      (r) => sendProgress.contains(r.route),
    )
        ? "import 'package:dio/dio.dart';"
        : '';

String _addExtraParameter() => '    Map<String, dynamic>? extras,\n';

String _addDioOptionsParameter() => '    RequestOptions? options,\n';

String _toParameter(UniversalRequestType parameter) {
  var parameterType = parameter.type.toSuitableType(ProgrammingLanguage.dart);
  // https://github.com/trevorwang/retrofit.dart/issues/631
  // https://github.com/Carapacik/swagger_parser/issues/110
  if (parameter.parameterType.isBody &&
      (parameterType == 'Object' || parameterType == 'Object?')) {
    parameterType = 'dynamic';
  }

  // https://github.com/trevorwang/retrofit.dart/issues/661
  // The Word `value` cant be used a a keyword argument
  final keywordArguments =
      parameter.type.name!.toCamel.replaceFirst('value', 'value_');

  return '    '
      '${_required(parameter.type)}'
      '$parameterType '
      '$keywordArguments${_defaultValue(parameter.type)},';
}

String _toConstructor(UniversalRequestType parameter) {
  final keywordArguments =
      parameter.type.name!.toCamel.replaceFirst('value', 'value_');

  return '$keywordArguments: $keywordArguments,';
}

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) => t.defaultValue != null
    ? ' = '
        '${t.wrappingCollections.isNotEmpty ? 'const ' : ''}'
        '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue?.toCamel)?.toCamel}' : protectDefaultValue(t.defaultValue, type: t.type)}'
    : '';

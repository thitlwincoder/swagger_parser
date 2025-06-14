import 'package:collection/collection.dart';
import 'package:yaml/yaml.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/encode.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart Retrofit client
String dartRetrofitClientTemplate({
  required String name,
  required bool isMerge,
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
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}${_fileImport(
      restClient,
    )}import 'package:dio/dio.dart'${_hideHeaders(restClient, defaultContentType)};
import 'package:retrofit/retrofit.dart';
${getImports(restClient.imports, putInFolder, isMerge, '../')}
part '${encode(name.toSnake).toSnake}.g.dart';

@RestApi()
abstract class ${encode(name.toPascal)} {
  factory ${encode(name.toPascal)}(Dio dio, {String? baseUrl}) = _${encode(name.toPascal)};
''',
  );
  for (final request in restClient.requests) {
    sb.write(
      _toClientRequest(
        request,
        defaultContentType,
        originalHttpResponse: originalHttpResponse,
        extrasParameterByDefault: extrasParameterByDefault,
        dioOptionsParameterByDefault: dioOptionsParameterByDefault,
        sendProgress: sendProgress,
      ),
    );
  }
  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest(
  UniversalRequest request,
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

  ${request.isDeprecated ? "@Deprecated('This method is marked as deprecated')\n  " : ''}\n${_contentTypeHeader(request, defaultContentType)}@${request.requestType.name.toUpperCase()}('${request.route}')
  Future<${originalHttpResponse ? 'HttpResponse<$responseType>' : responseType}> ${encode(request.name).toCamel}(''',
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
  if (sendProgress.contains(request.route)) {
    sb.write(
      '    @SendProgress() required ProgressCallback onSendProgress,\n',
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
    sb.write('  });\n');
  } else {
    sb.write(');\n');
  }
  return sb.toString();
}

String _fileImport(UniversalRestClient restClient) => restClient.requests.any(
      (r) => r.parameters.any(
        (e) => e.type.toSuitableType(ProgrammingLanguage.dart).contains('File'),
      ),
    )
        ? "import 'dart:io';\n\n"
        : '';

String _addExtraParameter() => '    @Extras() Map<String, dynamic>? extras,\n';

String _addDioOptionsParameter() =>
    '    @DioOptions() RequestOptions? options,\n';

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

  return "    @${parameter.parameterType.type}(${parameter.name != null && !parameter.parameterType.isBody ? "${parameter.parameterType.isPart ? 'name: ' : ''}'${parameter.name}'" : ''}) "
      '${_required(parameter.type)}'
      '$parameterType '
      '$keywordArguments${_defaultValue(parameter.type)},';
}

String _contentTypeHeader(
  UniversalRequest request,
  String defaultContentType,
) {
  if (request.isMultiPart) {
    return '@MultiPart()\n  ';
  }
  if (request.isFormUrlEncoded) {
    return '@FormUrlEncoded()\n  ';
  }
  if (request.contentType != defaultContentType) {
    return "@Headers(<String, String>{'Content-Type': '${request.contentType}'})\n  ";
  }
  return '';
}

/// ` hide Headers ` for retrofit Headers
String _hideHeaders(
  UniversalRestClient restClient,
  String defaultContentType,
) =>
    restClient.requests.any(
      (r) =>
          r.contentType != defaultContentType &&
          !(r.isMultiPart || r.isFormUrlEncoded),
    )
        ? ' hide Headers'
        : '';

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) => t.defaultValue != null
    ? ' = '
        '${t.wrappingCollections.isNotEmpty ? 'const ' : ''}'
        '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue?.toCamel)?.toCamel}' : protectDefaultValue(t.defaultValue, type: t.type)}'
    : '';

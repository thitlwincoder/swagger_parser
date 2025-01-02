import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:yaml/yaml.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart Retrofit client
String dartRetrofitClientMockTemplate({
  required String name,
  required bool isMerge,
  required bool putInFolder,
  required YamlMap mockData,
  required bool markFileAsGenerated,
  required String defaultContentType,
  required UniversalRestClient restClient,
  bool originalHttpResponse = false,
  bool extrasParameterByDefault = false,
  bool dioOptionsParameterByDefault = false,
}) {
  final imports =
      getImports(restClient.imports, putInFolder, isMerge, '../').split('\n');

  final sb = StringBuffer(
    '''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}${_convertImport(restClient)}${_fileImport(
      restClient,
    )}import 'package:faker/faker.dart'${_hideHeaders(restClient, defaultContentType)};
${imports.join('\n')}
import '${name.toSnake.replaceFirst('_mock', '')}.dart';

class $name implements ${name.replaceFirst('Mock', '')}{
''',
  );
  for (final request in restClient.requests) {
    sb.write(
      _toClientRequest(
        request,
        defaultContentType,
        imports: imports,
        mockData: mockData,
        putInFolder: putInFolder,
        originalHttpResponse: originalHttpResponse,
        extrasParameterByDefault: extrasParameterByDefault,
        dioOptionsParameterByDefault: dioOptionsParameterByDefault,
      ),
    );
  }
  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest(
  UniversalRequest request,
  String defaultContentType, {
  required bool putInFolder,
  required YamlMap mockData,
  required List<String> imports,
  required bool originalHttpResponse,
  required bool extrasParameterByDefault,
  required bool dioOptionsParameterByDefault,
}) {
  final responseType = request.returnType == null
      ? 'void'
      : request.returnType!.toSuitableType(ProgrammingLanguage.dart);
  final sb = StringBuffer(
    '''

  ${descriptionComment(request.description, tabForFirstLine: false, tab: '  ', end: '  ')}${request.isDeprecated ? "@Deprecated('This method is marked as deprecated')\n  " : ''}\n   @override
  Future<${originalHttpResponse ? 'HttpResponse<$responseType>' : responseType}> ${request.name}(''',
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

  if (responseType.contains('List')) {
    final name = responseType.split('<')[1].split('>')[0];
    sb
      ..writeln(
        ' async {\n    return List.generate(10, (index) {\n      return $name(',
      )
      ..writeln(_getModelMock(name, imports, putInFolder, mockData))
      ..writeln('  );\n  });\n  }');
  } else {
    sb
      ..writeln(' async {\n    return $responseType(')
      ..writeln(_getModelMock(responseType, imports, putInFolder, mockData))
      ..writeln('    );')
      ..writeln('  }');
  }

  return sb.toString();
}

String _getModelMock(
  String type,
  List<String> imports,
  bool putInFolder,
  YamlMap mockData,
) {
  final name = type.contains('List') ? type.split('<')[1].split('>')[0] : type;
  final path = imports.where((e) => e.contains(name.toSnake)).firstOrNull;
  if (path == null) {
    return '';
  }

  final result = parseFile(
    path:
        'lib/${putInFolder ? 'data' : ''}/${path.replaceAll('../', '').replaceFirst("import '", '').replaceFirst("';", '')}',
    featureSet: FeatureSet.latestLanguageVersion(),
  );
  final unit = result.unit;

  final sb = StringBuffer();

  for (final declaration in unit.declarations) {
    if (declaration is ClassDeclaration) {
      for (final member in declaration.members) {
        if (member is ConstructorDeclaration) {
          if (member.name != null) {
            continue;
          }

          for (final param in member.parameters.parameters) {
            final name = '${param.name}';

            String? defaultValue;

            if (param is DefaultFormalParameter) {
              defaultValue = param.defaultValue?.toSource();
            }

            final value =
                _genMockValue(param.toSource(), defaultValue, name, mockData);

            if (param.isNamed) {
              sb.writeln('$name: $value,');
            } else {
              sb.writeln(value);
            }
          }
        }
      }
    }
  }

  return sb.toString();
}

dynamic _genMockValue(
  String string,
  String? defaultValue,
  String name,
  YamlMap mockData,
) {
  final list = string.split(' ');
  final type = list[list.length - 2];

  if (mockData.containsKey(name)) {
    final value = mockData[name];
    if (type == 'String') return '"$value"';

    return value;
  }

  if (defaultValue != null) {
    return defaultValue;
  }

  if (type == 'String') {
    if (name == 'email') return 'faker.internet.email()';
    if (name == 'username') return 'faker.internet.userName()';
    if (name == 'name') return 'faker.person.name()';
    if (name == 'uuid') return 'faker.guid.guid()';
    if (name == 'image') return 'faker.image.loremPicsum()';
    if (name == 'accessToken') return 'faker.jwt.valid()';
    if (name == 'refreshToken') return 'faker.jwt.valid()';
    if (name == 'phone') {
      return "faker.randomGenerator.fromPattern(['09#########'])";
    }
    if (name == 'sessionToken') {
      return 'faker.jwt.valid(expiresIn: DateTime.now().add(Duration(minutes: 30)))';
    }
    if (name == 'gender') {
      return "faker.randomGenerator.boolean()?'Male':'Female'";
    }

    return '""';
  }

  if (type == 'int') {
    return 'faker.randomGenerator.integer(100)';
  }

  if (type == 'bool') {
    return 'faker.randomGenerator.boolean()';
  }

  return '""';
}

String _convertImport(UniversalRestClient restClient) =>
    restClient.requests.any(
      (r) => r.parameters.any(
        (e) => e.parameterType.isPart,
      ),
    )
        ? "import 'dart:convert';\n"
        : '';

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

  return '${_required(parameter.type)}'
      '$parameterType '
      '$keywordArguments${_defaultValue(parameter.type)},';
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

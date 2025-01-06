import 'package:path/path.dart' as p;

import '../config/swp_config.dart';
import '../generator/config/generator_config.dart';
import '../generator/model/programming_language.dart';
import '../parser/swagger_parser_core.dart';
import '../parser/utils/case_utils.dart';
import 'type_utils.dart';

/// Provides imports as String from list of imports
String dartImports({required Set<String> imports, String? pathPrefix}) {
  if (imports.isEmpty) {
    return '';
  }
  return '\n${imports.map((import) => "import '${pathPrefix ?? ''}${import.toSnake}.dart';").join('\n')}\n';
}

String indentation(int length) => ' ' * length;

/// Provides description
String descriptionComment(
  String? description, {
  bool tabForFirstLine = true,
  String tab = '',
  String end = '',
}) {
  if (description == null || description.isEmpty) {
    return '';
  }

  final lineStart = RegExp('^(.*)', multiLine: true);

  final result = description.replaceAllMapped(
    lineStart,
    (m) =>
        '${!tabForFirstLine && m.start == 0 ? '' : tab}///${m[1]!.trim().isEmpty ? '' : ' '}${m.start == 0 && m.end == description.length ? m[1] : addDot(m[1])}',
  );

  if (end.trim().isEmpty) {
    return result;
  }

  return '$result\n$end\n';
}

/// Add dot to string if not exist
/// https://dart.dev/effective-dart/documentation#do-format-comments-like-sentences
String? addDot(String? text) =>
    text != null && text.trim().isNotEmpty && !_punctuationRegExp.hasMatch(text)
        ? '$text.'
        : text;

/// RegExp for punctuation marks in the end of string
final _punctuationRegExp = RegExp(r'[.!?]$');

/// Replace all not english letters in text
String? replaceNotEnglishLetter(String? text) {
  if (text == null || text.isEmpty) {
    return null;
  }
  final lettersRegex = RegExp('[^a-zA-Z]');
  return text.replaceAll(lettersRegex, ' ');
}

/// Specially for File import
String ioImport(UniversalComponentClass dataClass) => dataClass.parameters.any(
      (p) => p.toSuitableType(ProgrammingLanguage.dart).startsWith('File'),
    )
        ? "import 'dart:io';\n\n"
        : '';

String formatNumber(int number) => number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );

String generatedFileComment({
  required bool markFileAsGenerated,
  bool ignoreLints = true,
}) =>
    markFileAsGenerated
        ? ignoreLints
            ? '$_generatedCodeComment$_ignoreLintsComment\n'
            : '$_generatedCodeComment\n'
        : '';

const _generatedCodeComment = '''
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
''';

const _ignoreLintsComment = '''
// ignore_for_file: type=lint, unused_import
''';

// String createCleanFolder(GenerateCleanArch arch, String name, String path) {
//   return p.join(
//     arch.baseFolder,
//     name.toSnake,
//     path,
//   );
// }

String checkArchMapping(GenerateCleanArch arch, String name) {
  if (arch.folderMapping != null) {
    final d = arch.folderMapping![name];
    if (d != null) {
      return '$d';
    }
  }

  return name;
}

String? checkMerge(GeneratorConfig config, String name) {
  final mergeClients = config.generateCleanArch?.mergeClients;

  if (mergeClients == null) {
    return null;
  }

  for (final e in mergeClients.entries) {
    final v = e.value as List;

    if (v.contains(name)) {
      return '${e.key}';
    }
  }

  return null;
}

({
  String name,
  String folderName,
  String fileName,
  String? mergeName,
}) getNames(
  GeneratorConfig config,
  UniversalRestClient client, {
  required String postfix,
  required String folder,
}) {
  String folderName;
  String fileName;
  String name;
  String? mergeName;

  final arch = config.generateCleanArch;
  if (arch != null) {
    name = checkArchMapping(arch, client.name);
    mergeName = checkMerge(config, client.name);

    folderName = config.putInFolder
        ? p.join(
            folder,
            postfix == 'repo' || postfix == 'repo_impl'
                ? 'repositories'
                : postfix == 'use_case'
                    ? 'use_cases'
                    : postfix == 'provider'
                        ? 'providers'
                        : 'clients',
          )
        : '${arch.baseFolder}/${name.toSnake}/$folder';
    fileName = '${name}_$postfix'.toSnake;
  } else {
    name = client.name;
    folderName = config.putClientsInFolder ? 'clients' : name.toSnake;
    fileName = config.language == ProgrammingLanguage.dart
        ? '${client.name}_$postfix'.toSnake
        : (client.name + postfix).toPascal;
  }

  return (
    name: name.toSnake,
    folderName: folderName,
    fileName: fileName,
    mergeName: mergeName
  );
}

String getImports(
  Set<String> imports,
  bool putInFolder,
  bool isMerge,
  String putInFolderPath,
) {
  return dartImports(
    imports: imports,
    pathPrefix:
        '${putInFolder ? putInFolderPath : '../../../../${isMerge ? '../' : ''}'}models/',
  );
}

import 'package:yaml/yaml.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/encode.dart';
import '../config/generator_config.dart';
import '../model/generated_file.dart';
import '../model/programming_language.dart';

/// Handles generating files
final class FillController {
  /// Constructor that accepts configuration parameters with default values to create files
  const FillController({
    required this.config,
    this.info = const OpenApiInfo(schemaVersion: OAS.v3_1),
  });

  /// Api info
  final OpenApiInfo info;

  /// Config
  final GeneratorConfig config;

  /// Return [GeneratedFile] generated from given [UniversalDataClass]
  GeneratedFile fillDtoContent(UniversalDataClass dataClass) {
    var name = 'models/'
        '${config.language == ProgrammingLanguage.dart ? dataClass.name.toSnake : dataClass.name.toPascal}'
        '.${config.language.fileExtension}';

    if (config.putInFolder) {
      name = 'data/$name';
    }

    return GeneratedFile(
      name: name,
      content: config.language.dtoFileContent(
        dataClass,
        jsonSerializer: config.jsonSerializer,
        enumsToJson: config.enumsToJson,
        unknownEnumValue: config.unknownEnumValue,
        markFilesAsGenerated: config.markFilesAsGenerated,
        generateValidator: config.generateValidator,
      ),
    );
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRestClientContent(UniversalRestClient client) {
    final postfix = config.clientPostfix ?? 'Client';

    final names = getNames(config, client, postfix: postfix, folder: 'data');

    String name;

    if (names.mergeName == null) {
      name =
          '${names.folderName}/${encode(names.fileName).toSnake}.${config.language.fileExtension}';
    } else {
      name =
          '${names.folderName.replaceFirst(names.name, names.mergeName!)}/${names.name}/${encode(names.fileName).toSnake}.${config.language.fileExtension}';
    }

    return GeneratedFile(
      name: name,
      content: config.language.restClientFileContent(
        client,
        names.fileName.toPascal,
        putInFolder: config.putInFolder,
        isMerge: names.mergeName != null,
        defaultContentType: config.defaultContentType,
        markFilesAsGenerated: config.markFilesAsGenerated,
        originalHttpResponse: config.originalHttpResponse,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        sendProgress: config.generateCleanArch?.sendProgress ?? YamlList(),
      ),
    );
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillClientMockContent(UniversalRestClient client) {
    const postfix = 'client_mock';

    final names = getNames(config, client, postfix: postfix, folder: 'data');

    String name;

    if (names.mergeName == null) {
      name =
          '${names.folderName}/${names.fileName}.${config.language.fileExtension}';
    } else {
      name =
          '${names.folderName.replaceFirst(names.name, names.mergeName!)}/${names.name}/${names.fileName}.${config.language.fileExtension}';
    }

    return GeneratedFile(
      name: name,
      content: config.language.restClientMockFileContent(
        client,
        names.fileName.toPascal,
        putInFolder: config.putInFolder,
        isMerge: names.mergeName != null,
        defaultContentType: config.defaultContentType,
        markFilesAsGenerated: config.markFilesAsGenerated,
        originalHttpResponse: config.originalHttpResponse,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        mockData: config.generateCleanArch!.mockData ?? YamlMap(),
      ),
    );
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRepoContent(UniversalRestClient client) {
    final names = getNames(config, client, postfix: 'repo', folder: 'domain');

    String name;

    if (names.mergeName == null) {
      name =
          '${names.folderName}/${names.fileName}.${config.language.fileExtension}';
    } else {
      name =
          '${names.folderName.replaceFirst(names.name, names.mergeName!)}/${names.name}/${names.fileName}.${config.language.fileExtension}';
    }

    return GeneratedFile(
      name: name,
      content: config.language.repoFileContent(
        client,
        name: names.fileName.toPascal,
        putInFolder: config.putInFolder,
        isMerge: names.mergeName != null,
        defaultContentType: config.defaultContentType,
        markFilesAsGenerated: config.markFilesAsGenerated,
        originalHttpResponse: config.originalHttpResponse,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        sendProgress: config.generateCleanArch?.sendProgress ?? YamlList(),
      ),
    );
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRepoImplContent(UniversalRestClient client) {
    final names =
        getNames(config, client, postfix: 'repo_impl', folder: 'data');

    String name;

    if (names.mergeName == null) {
      name =
          '${names.folderName}/${names.fileName}.${config.language.fileExtension}';
    } else {
      name =
          '${names.folderName.replaceFirst(names.name, names.mergeName!)}/${names.name}/${names.fileName}.${config.language.fileExtension}';
    }

    return GeneratedFile(
      name: name,
      content: config.language.repoImplFileContent(
        client,
        mergeName: names.mergeName,
        name: names.name,
        fileName: names.fileName.toPascal,
        markFilesAsGenerated: config.markFilesAsGenerated,
        defaultContentType: config.defaultContentType,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        originalHttpResponse: config.originalHttpResponse,
        putInFolder: config.putInFolder,
        sendProgress: config.generateCleanArch?.sendProgress ?? YamlList(),
      ),
    );
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillUseCaseContent(UniversalRestClient client) {
    const postfix = 'use_case';

    final names = getNames(config, client, postfix: postfix, folder: 'domain');

    String name;

    if (names.mergeName == null) {
      name =
          '${names.folderName}/${names.fileName}.${config.language.fileExtension}';
    } else {
      name =
          '${names.folderName.replaceFirst(names.name, names.mergeName!)}/${names.name}/${names.fileName}.${config.language.fileExtension}';
    }

    return GeneratedFile(
      name: name,
      content: config.language.useCaseFileContent(
        client,
        name: names.fileName.toPascal,
        isMerge: names.mergeName != null,
        repoName: names.name.toPascal + 'repo'.toPascal,
        markFilesAsGenerated: config.markFilesAsGenerated,
        defaultContentType: config.defaultContentType,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        originalHttpResponse: config.originalHttpResponse,
        putInFolder: config.putInFolder,
        sendProgress: config.generateCleanArch?.sendProgress ?? YamlList(),
      ),
    );
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillProviderContent(UniversalRestClient client) {
    const postfix = 'provider';

    final names = getNames(config, client, postfix: postfix, folder: 'data');

    String name;

    if (names.mergeName == null) {
      name =
          '${names.folderName}/${names.fileName}.${config.language.fileExtension}';
    } else {
      name =
          '${names.folderName.replaceFirst(names.name, names.mergeName!)}/${names.name}/${names.fileName}.${config.language.fileExtension}';
    }

    return GeneratedFile(
      name: name,
      content: config.language.providerFileContent(
        client,
        name: names.name.toSnake,
        putInFolder: config.putInFolder,
        isMerge: names.mergeName != null,
        markFilesAsGenerated: config.markFilesAsGenerated,
        mockGen: config.generateCleanArch?.mockGen ?? false,
        dioProviderPath: config.generateCleanArch?.dioProviderPath,
      ),
    );
  }

  /// Return [GeneratedFile] root client generated from given clients
  GeneratedFile fillRootClient(Iterable<UniversalRestClient> clients) {
    final rootClientName = config.rootClientName ?? 'RestClient';
    final postfix = config.clientPostfix ?? 'Client';
    final clientsNames = clients.map((c) => c.name.toPascal).toSet();

    return GeneratedFile(
      name: '${rootClientName.toSnake}.${config.language.fileExtension}',
      content: config.language.rootClientFileContent(
        clientsNames,
        openApiInfo: info,
        name: rootClientName,
        postfix: postfix.toPascal,
        putClientsInFolder: config.putClientsInFolder,
        markFilesAsGenerated: config.markFilesAsGenerated,
      ),
    );
  }

  /// Return [GeneratedFile] with all exports from all files
  GeneratedFile fillExportFile({
    required List<GeneratedFile> restClients,
    required List<GeneratedFile> dataClasses,
    required GeneratedFile? rootClient,
  }) {
    return GeneratedFile(
      name: 'export.${config.language.fileExtension}',
      content: config.language.exportFileContent(
        restClients: restClients,
        dataClasses: dataClasses,
        rootClient: rootClient,
        markFileAsGenerated: config.markFilesAsGenerated,
      ),
    );
  }
}

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
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
  GeneratedFile fillDtoContent(UniversalDataClass dataClass) => GeneratedFile(
        name: 'models/'
            '${config.language == ProgrammingLanguage.dart ? dataClass.name.toSnake : dataClass.name.toPascal}'
            '.${config.language.fileExtension}',
        content: config.language.dtoFileContent(
          dataClass,
          jsonSerializer: config.jsonSerializer,
          enumsToJson: config.enumsToJson,
          unknownEnumValue: config.unknownEnumValue,
          markFilesAsGenerated: config.markFilesAsGenerated,
          generateValidator: config.generateValidator,
        ),
      );

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRestClientContent(UniversalRestClient client) {
    final postfix = config.clientPostfix ?? 'Client';

    final names = getNames(config, client, postfix: postfix, folder: 'data');

    return GeneratedFile(
      name:
          '${names.folderName}/${names.fileName}.${config.language.fileExtension}',
      content: config.language.restClientFileContent(
        client,
        names.fileName.toPascal,
        markFilesAsGenerated: config.markFilesAsGenerated,
        defaultContentType: config.defaultContentType,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        originalHttpResponse: config.originalHttpResponse,
      ),
    );
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRepoContent(UniversalRestClient client) {
    final names = getNames(config, client, postfix: 'repo', folder: 'domain');

    return GeneratedFile(
      name:
          '${names.folderName}/${names.fileName}.${config.language.fileExtension}',
      content: config.language.repoFileContent(
        client,
        name: names.fileName.toPascal,
        markFilesAsGenerated: config.markFilesAsGenerated,
        defaultContentType: config.defaultContentType,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        originalHttpResponse: config.originalHttpResponse,
      ),
    );
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillRepoImplContent(UniversalRestClient client) {
    final names =
        getNames(config, client, postfix: 'repo_impl', folder: 'data');

    return GeneratedFile(
      name:
          '${names.folderName}/${names.fileName}.${config.language.fileExtension}',
      content: config.language.repoImplFileContent(
        client,
        name: names.fileName.toPascal,
        repoName: names.name.toPascal + 'repo'.toPascal,
        clientName: names.name.toPascal + 'client'.toPascal,
        markFilesAsGenerated: config.markFilesAsGenerated,
        defaultContentType: config.defaultContentType,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        originalHttpResponse: config.originalHttpResponse,
      ),
    );
  }

  /// Return [GeneratedFile] generated from given [UniversalRestClient]
  GeneratedFile fillUseCaseContent(UniversalRestClient client) {
    const postfix = 'use_case';

    final names = getNames(config, client, postfix: postfix, folder: 'domain');

    return GeneratedFile(
      name:
          '${names.folderName}/${names.fileName}.${config.language.fileExtension}',
      content: config.language.useCaseFileContent(
        client,
        name: names.fileName.toPascal,
        repoName: names.name.toPascal + 'repo'.toPascal,
        markFilesAsGenerated: config.markFilesAsGenerated,
        defaultContentType: config.defaultContentType,
        extrasParameterByDefault: config.extrasParameterByDefault,
        dioOptionsParameterByDefault: config.dioOptionsParameterByDefault,
        originalHttpResponse: config.originalHttpResponse,
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

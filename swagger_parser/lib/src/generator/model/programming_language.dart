import '../../parser/swagger_parser_core.dart';
import '../model/generated_file.dart';
import '../model/json_serializer.dart';
import '../templates/dart_dart_mappable_dto_template.dart';
import '../templates/dart_enum_dto_template.dart';
import '../templates/dart_export_file_template.dart';
import '../templates/dart_freezed_dto_template.dart';
import '../templates/dart_json_serializable_dto_template.dart';
import '../templates/dart_provider_template.dart';
import '../templates/dart_repo_impl_template.dart';
import '../templates/dart_repo_template.dart';
import '../templates/dart_retrofit_client_template.dart';
import '../templates/dart_root_client_template.dart';
import '../templates/dart_typedef_template.dart';
import '../templates/dart_use_case_template.dart';
import '../templates/kotlin_enum_dto_template.dart';
import '../templates/kotlin_moshi_dto_template.dart';
import '../templates/kotlin_retrofit_client_template.dart';
import '../templates/kotlin_typedef_template.dart';

/// Enumerates supported programming languages to determine templates
enum ProgrammingLanguage {
  /// Dart language
  dart('dart'),

  /// Kotlin language
  kotlin('kt');

  /// Constructor with [fileExtension] for every language
  const ProgrammingLanguage(this.fileExtension);

  /// Returns [ProgrammingLanguage] from string
  factory ProgrammingLanguage.fromString(String value) =>
      ProgrammingLanguage.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError(
          "'$value' must be contained in ${ProgrammingLanguage.values.map((e) => e.name)}",
        ),
      );

  /// Extension for generated files
  final String fileExtension;

  /// Determines template for generating DTOs by language
  String dtoFileContent(
    UniversalDataClass dataClass, {
    required JsonSerializer jsonSerializer,
    required bool enumsToJson,
    required bool unknownEnumValue,
    required bool markFilesAsGenerated,
    required bool generateValidator,
  }) {
    switch (this) {
      case dart:
        if (dataClass is UniversalEnumClass) {
          return dartEnumDtoTemplate(
            dataClass,
            jsonSerializer: jsonSerializer,
            enumsToJson: enumsToJson,
            unknownEnumValue: unknownEnumValue,
            markFileAsGenerated: markFilesAsGenerated,
          );
        } else if (dataClass is UniversalComponentClass) {
          if (dataClass.typeDef) {
            return dartTypeDefTemplate(
              dataClass,
              markFileAsGenerated: markFilesAsGenerated,
            );
          }
          return switch (jsonSerializer) {
            JsonSerializer.freezed => dartFreezedDtoTemplate(
                dataClass,
                markFileAsGenerated: markFilesAsGenerated,
                generateValidator: generateValidator,
              ),
            JsonSerializer.jsonSerializable => dartJsonSerializableDtoTemplate(
                dataClass,
                markFileAsGenerated: markFilesAsGenerated,
              ),
            JsonSerializer.dartMappable => dartDartMappableDtoTemplate(
                dataClass,
                markFileAsGenerated: markFilesAsGenerated,
              )
          };
        }
      case kotlin:
        if (dataClass is UniversalEnumClass) {
          return kotlinEnumDtoTemplate(
            dataClass,
            markFileAsGenerated: markFilesAsGenerated,
          );
        } else if (dataClass is UniversalComponentClass) {
          if (dataClass.typeDef) {
            return kotlinTypeDefTemplate(
              dataClass,
              markFileAsGenerated: markFilesAsGenerated,
            );
          }
          return kotlinMoshiDtoTemplate(
            dataClass,
            markFileAsGenerated: markFilesAsGenerated,
          );
        }
    }
    throw ArgumentError('Unknown type exception');
  }

  /// Determines template for generating Rest client by language
  String restClientFileContent(
    UniversalRestClient restClient,
    String name, {
    required bool putInFolder,
    required bool markFilesAsGenerated,
    required String defaultContentType,
    bool originalHttpResponse = false,
    bool extrasParameterByDefault = false,
    bool dioOptionsParameterByDefault = false,
  }) =>
      switch (this) {
        dart => dartRetrofitClientTemplate(
            name: name,
            restClient: restClient,
            putInFolder: putInFolder,
            defaultContentType: defaultContentType,
            markFileAsGenerated: markFilesAsGenerated,
            originalHttpResponse: originalHttpResponse,
            extrasParameterByDefault: extrasParameterByDefault,
            dioOptionsParameterByDefault: dioOptionsParameterByDefault,
          ),
        kotlin => kotlinRetrofitClientTemplate(
            name: name,
            restClient: restClient,
            markFileAsGenerated: markFilesAsGenerated,
          ),
      };

  String repoFileContent(
    UniversalRestClient restClient, {
    required String name,
    required bool markFilesAsGenerated,
    required String defaultContentType,
    required bool putInFolder,
    bool originalHttpResponse = false,
    bool extrasParameterByDefault = false,
    bool dioOptionsParameterByDefault = false,
  }) =>
      switch (this) {
        dart => dartRepoTemplate(
            name: name,
            restClient: restClient,
            putInFolder: putInFolder,
            defaultContentType: defaultContentType,
            markFileAsGenerated: markFilesAsGenerated,
            originalHttpResponse: originalHttpResponse,
            extrasParameterByDefault: extrasParameterByDefault,
            dioOptionsParameterByDefault: dioOptionsParameterByDefault,
          ),
        kotlin => '',
      };

  String repoImplFileContent(
    UniversalRestClient restClient, {
    required String name,
    required String repoName,
    required String clientName,
    required bool markFilesAsGenerated,
    required String defaultContentType,
    required bool putInFolder,
    bool originalHttpResponse = false,
    bool extrasParameterByDefault = false,
    bool dioOptionsParameterByDefault = false,
  }) =>
      switch (this) {
        dart => dartRepoImplTemplate(
            name: name,
            repoName: repoName,
            restClient: restClient,
            clientName: clientName,
            putInFolder: putInFolder,
            defaultContentType: defaultContentType,
            markFileAsGenerated: markFilesAsGenerated,
            originalHttpResponse: originalHttpResponse,
            extrasParameterByDefault: extrasParameterByDefault,
            dioOptionsParameterByDefault: dioOptionsParameterByDefault,
          ),
        kotlin => '',
      };

  String useCaseFileContent(
    UniversalRestClient restClient, {
    required String name,
    required String repoName,
    required bool putInFolder,
    required bool markFilesAsGenerated,
    required String defaultContentType,
    bool originalHttpResponse = false,
    bool extrasParameterByDefault = false,
    bool dioOptionsParameterByDefault = false,
  }) =>
      switch (this) {
        dart => dartUseCaseTemplate(
            name: name,
            repoName: repoName,
            restClient: restClient,
            putInFolder: putInFolder,
            defaultContentType: defaultContentType,
            markFileAsGenerated: markFilesAsGenerated,
            originalHttpResponse: originalHttpResponse,
            extrasParameterByDefault: extrasParameterByDefault,
            dioOptionsParameterByDefault: dioOptionsParameterByDefault,
          ),
        kotlin => '',
      };

  String providerFileContent(
    UniversalRestClient restClient, {
    required String name,
    required bool putInFolder,
    required bool markFilesAsGenerated,
    String? dioProviderPath,
  }) =>
      switch (this) {
        dart => dartProviderTemplate(
            name: name,
            restClient: restClient,
            putInFolder: putInFolder,
            dioProviderPath: dioProviderPath,
            markFileAsGenerated: markFilesAsGenerated,
          ),
        kotlin => '',
      };

  /// Determines template for generating root client for clients
  String rootClientFileContent(
    Set<String> clientsNames, {
    required String name,
    required String postfix,
    required OpenApiInfo openApiInfo,
    required bool putClientsInFolder,
    required bool markFilesAsGenerated,
  }) =>
      switch (this) {
        dart => dartRootClientTemplate(
            name: name,
            postfix: postfix,
            openApiInfo: openApiInfo,
            clientsNames: clientsNames,
            putClientsInFolder: putClientsInFolder,
            markFileAsGenerated: markFilesAsGenerated,
          ),
        kotlin => '',
      };

  /// Export file by language
  String exportFileContent({
    required bool markFileAsGenerated,
    required GeneratedFile? rootClient,
    required List<GeneratedFile> restClients,
    required List<GeneratedFile> dataClasses,
  }) =>
      switch (this) {
        dart => dartExportFileTemplate(
            rootClient: rootClient,
            restClients: restClients,
            dataClasses: dataClasses,
            markFileAsGenerated: markFileAsGenerated,
          ),
        kotlin => '',
      };
}

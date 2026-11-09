//v3
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'generate_feature.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    debugPrint('❌ Please provide a feature name and JSON file path.');
    return;
  }

  final featureName = args[0];
  final jsonFilePath = args[1];

  final featureDir = 'lib/features/$featureName';
  final fileName = p.basenameWithoutExtension(jsonFilePath);
  // Read JSON file
  final jsonFile = File(jsonFilePath);
  if (!await jsonFile.exists()) {
    debugPrint('❌ JSON file not found: $jsonFilePath');
    return;
  }

  final jsonData = jsonDecode(await jsonFile.readAsString());

  // Check if the parsed data is a map or list
  if (jsonData is! Map<String, dynamic>) {
    debugPrint('❌ Invalid JSON format. Expected a Map<String, dynamic>.');
    return;
  }

  // Extract the fields from the JSON
  final modelClassName = _capitalize(_camelCase(featureName));
  // final modelVariableName = _camelCase(featureName);

  final fields = jsonData.keys.map((key) {
    return {'name': key, 'type': _getFieldType(jsonData[key])};
  }).toList();

  final modelFilePath = '$featureDir/data/models/${fileName}_model.dart';
  final entityFilePath = '$featureDir/domain/entities/${fileName}_entity.dart';
  final repositoryFilePath =
      '$featureDir/domain/repositories/${featureName}_repository.dart';
  final usecaseFilePath =
      '$featureDir/domain/use_cases/${fileName}_use_case.dart';
  final repositoryImplFilePath =
      '$featureDir/data/repositories_impl/${featureName}_repository_impl.dart';
  final dataSourceFilePath =
      '$featureDir/data/datasources/${featureName}_remote_datasource.dart';

  final files = {
    modelFilePath: _generateModelClass(
      modelClassName,
      fields,
      "${fileName.capitalize()}Entity",
      featureName,
      fileName,
    ), // Or provide a superclass if needed

    entityFilePath: _generateEntityClass(fileName, fields),
    repositoryFilePath: generateRepositoryInterface(
      featureName: featureName,
      className: modelClassName,
      fileName: fileName,
      methodName: '${fileName}Request',
    ),
    usecaseFilePath: _generateUseCase(
      featureName: featureName,
      className: modelClassName,
      fileName: fileName,
    ),
    repositoryImplFilePath: _generateRepositoryImplementation(
      className: modelClassName,
      featureName: featureName,
      fileName: fileName,
    ),
    dataSourceFilePath: _generateDataSourceInterface(modelClassName, fileName),
  };

  for (final path in files.keys) {
    final file = File(path);
    file.createSync(recursive: true);
    file.writeAsStringSync(files[path]!);
    debugPrint('✅ Created: $path');
  }

  debugPrint('\n🎉 API generation for "$featureName" completed.');
}

String _generateModelClass(
  String className,
  List<Map<String, dynamic>> fields,
  String? superClass,
  String featureName,
  String fileName,
) {
  final fieldDefinitions = fields
      .map(
        (field) =>
            'final ${field['type']}? ${_removeUnderScore(field['name'])},',
      )
      .join('\n  ');

  final superClassCall = superClass != null
      ? 'super(${fields.map((field) {
          final name = _removeUnderScore(field['name']);
          final type = field['type'];
          final defaultValue = _getDefaultValue(type);
          return '$name: $name${defaultValue != null ? ' ?? $defaultValue' : ''}';
        }).join(', ')})'
      : '';

  final fromJson =
      '''
  factory ${fileName.capitalize()}Model.fromJson(Map<String, dynamic> json) {
    return ${fileName.capitalize()}Model(
      ${fields.map((field) => '${_removeUnderScore(field['name'])}: json[\'${field['name']}\'],').join('\n      ')}
    );
  }
  ''';

  final toJson =
      '''
  Map<String, dynamic> toJson() {
    return {
      ${fields.map((field) => '\'${field['name']}\': ${_removeUnderScore(field['name'])},').join('\n      ')}
    };
  }
  ''';

  return '''


${superClass != null ? "import '../../domain/entities/${fileName}_entity.dart';" : ''}

class ${fileName.capitalize()}Model ${superClass != null ? 'extends $superClass' : ''}  {

  const ${fileName.capitalize()}Model({
  $fieldDefinitions
  }) : $superClassCall;

  $fromJson

  $toJson

}
''';
}

String _generateEntityClass(
  String fileName,
  List<Map<String, dynamic>> fields,
) {
  final fieldDefinitions = fields
      .map(
        (field) =>
            'final ${field['type']} ${_removeUnderScore(field['name'])};',
      )
      .join('\n  ');
  final constructorParams = fields
      .map((field) => 'required this.${_removeUnderScore(field['name'])},')
      .join('\n    ');

  return '''
class ${fileName.capitalize()}Entity {
  $fieldDefinitions


  const ${fileName.capitalize()}Entity ({
  $constructorParams
  });
}
''';
}

// String generateRepositoryInterface({
//   required String featureName,
//   required String className,
//   required String fileName,
//   required String methodName,
// }) {
//   final featureDir = 'lib/features/$featureName';
//   final repositoryFilePath =
//       '$featureDir/domain/repositories/${featureName}_repository.dart';

//   // Define the entity name and import path for dynamic entity handling
//   final entityName = '${fileName.capitalize()}Entity';
//   final entityImportPath =
//       '../../domain/entities/${fileName.toLowerCase()}_entity.dart';
//   final failureImportPath = '../../../../core/errors/failure.dart';

//   final classHeader = 'abstract class ${className}Repository {';
//   final methodSignature =
//       'Future<Either<Failure, $entityName>> $methodName(dynamic params);';

//   final file = File(repositoryFilePath);

//   if (!file.existsSync()) {
//     // Create the repository interface file from scratch if it doesn't exist
//     return '''
// import 'package:dartz/dartz.dart';

// import '$entityImportPath';
// import '$failureImportPath';

// $classHeader
//   $methodSignature
// }
// ''';
//   }

//   // File exists, read its contents and check if the method already exists
//   String content = file.readAsStringSync();

//   if (content.contains('$methodName(')) {
//     return 'Method "$methodName" already exists in repository.';
//   }

//   // Append the new method before the closing bracket of the class
//   final updatedContent = content.replaceFirst(
//     RegExp(r'\}\s*$'),
//     '  $methodSignature\n}',
//   );

//   return updatedContent;
// }

String generateRepositoryInterface({
  required String featureName,
  required String className,
  required String fileName,
  required String methodName,
}) {
  final featureDir = 'lib/features/$featureName';
  final repositoryFilePath =
      '$featureDir/domain/repositories/${featureName}_repository.dart';

  final entityName = '${fileName.capitalize()}Entity';
  final entityImportPath =
      '../../domain/entities/${fileName.toLowerCase()}_entity.dart';
  const failureImportPath = '../../../../core/errors/failure.dart';

  final classHeader = 'abstract class ${className}Repository {';
  final methodSignature =
      'Future<Either<Failure, $entityName>> $methodName(dynamic params);';

  final file = File(repositoryFilePath);

  // If file doesn't exist, create it from scratch
  if (!file.existsSync()) {
    return '''
import 'package:dartz/dartz.dart';

import '$entityImportPath';
import '$failureImportPath';

$classHeader
  $methodSignature
}
''';
  }

  String content = file.readAsStringSync();

  // If method already exists, return the original content unchanged
  if (content.contains(RegExp(r'\b' + methodName + r'\s*\('))) {
    return content;
  }

  // Ensure necessary imports are present
  if (!content.contains(entityImportPath)) {
    content = content.replaceFirst(
      RegExp(r"import 'package:dartz/dartz\.dart';\n"),
      "import 'package:dartz/dartz.dart';\n\nimport '$entityImportPath';",
    );
  }

  if (!content.contains(failureImportPath)) {
    content = content.replaceFirst(
      RegExp(r"(import '.*_entity\.dart';)"),
      "$entityImportPath\nimport '$failureImportPath';",
    );
  }

  // Add the new method just before the final closing bracket of the class
  final updatedContent = content.replaceFirst(
    RegExp(r'\}\s*$'),
    '  $methodSignature\n}',
  );

  return updatedContent;
}

String _generateUseCase({
  required String featureName,
  required String className,
  required String fileName,
}) {
  return '''
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/${featureName.toLowerCase()}_repository.dart';

import '../../domain/entities/${fileName.toLowerCase()}_entity.dart';

class ${fileName.capitalize()}UseCase {
  final ${featureName.capitalize()}Repository _repo;

const  ${fileName.capitalize()}UseCase(this._repo);
  Future<Either<Failure, ${fileName.capitalize()}Entity>> ${fileName}Request(
       params) async {
    return await _repo.${fileName}Request(params);
  }
}

''';
}

String _generateRepositoryImplementation({
  required String className,
  required String fileName,
  required String featureName,
}) {
  return '''
import '../datasources/${featureName.toLowerCase()}_remote_datasource.dart';
import '../../domain/repositories/${featureName.toLowerCase()}_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';

import '../../domain/entities/${fileName.toLowerCase()}_entity.dart';

abstract class ${className}RepositoryInternal implements ${className}Repository {}

class ${className}RepositoryImpl implements ${className}RepositoryInternal{
  final ${className}RemoteDatasource remoteDatasource;

  ${className}RepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, ${fileName.capitalize()}Entity>> ${fileName}Request(
      param) async {
    final response = await remoteDatasource.${fileName}Request(param);

    return response.fold(
        (left) => Left(ServerFailure(errorMessage: left.errorMessage)),
        (right) => Right(right));
  }
}
''';
}

String _generateDataSourceInterface(String className, String fileName) {
  return '''
import 'package:dartz/dartz.dart';


import '../../../../../shared/model/api_response.dart';
import '../../../../core/constant/endpoints.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/network_error_handler.dart';
import '../../../../core/services/api_services.dart';
import '../../../../core/services/shared_prefs_services/service_locator.dart';

import '../../data/models/${fileName.toLowerCase()}_model.dart';
abstract class ${className}RemoteDatasource {
  Future<Either<Failure, ${fileName.capitalize()}Model>> ${fileName}Request(params);
 }

class ${className}RemoteDatasourceImpl implements ${className}RemoteDatasource {
  final ApiService apiService = locator<ApiService>();

  @override
  Future<Either<Failure, ${fileName.capitalize()}Model>> ${fileName}Request(params) async {
    return handleNetworkError(() async {
      final res = await apiService.post(
        Endpoints.signIn,
        payload: params.toJson(),
      );
      final ApiResponse response = ApiResponse.fromMap(res.data);
      final ${fileName.capitalize()}Model responseData = ${fileName.capitalize()}Model.fromJson(response.data);
      return responseData;
    });
  }
}
''';
}

String _getFieldType(dynamic value) {
  if (value is int) return 'num';
  if (value is double) return 'num';
  if (value is String) return 'String';
  if (value is bool) return 'bool';
  if (value is List) return 'List<dynamic>';
  return 'dynamic';
}

String _capitalize(String input) =>
    input.isNotEmpty ? input[0].toUpperCase() + input.substring(1) : '';

String _camelCase(String input) {
  final parts = input.split('_');
  return parts.first + parts.skip(1).map((word) => _capitalize(word)).join();
}

String _removeUnderScore(String input) {
  final parts = input.split('_');
  return parts.first +
      parts.skip(1).map((word) => "$word${_camelCase(input)}").join();
}

String? _getDefaultValue(String type) {
  switch (type) {
    case 'String':
      return "''";
    case 'DateTime':
      return 'DateTime.now()';
    case 'int':
      return '0';
    case 'double':
      return '0.0';
    case 'bool':
      return 'false';
    case 'List<dynamic>':
      return 'const[]';
    case 'List<dynamic>?':
      return 'const[]';
    case 'Map':
    case 'Map<String, dynamic>':
      return '{}';
    case 'num':
      return '0';
    case 'dynamic':
      return 'null';
    default:
      return 'null';
  }
}

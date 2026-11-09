import 'dart:io';

import 'package:flutter/material.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    debugPrint('❌ Please provide a feature name.');
    return;
  }
  final featureName = args[0];
  final className = _capitalize(_camelCase(featureName));
  final variableName = _camelCase(featureName);
  final baseDir = 'lib/features/$featureName';

  final files = {
    '$baseDir/data/datasources/${featureName}_remote_datasource.dart':
        '''
abstract class ${className}RemoteDatasource {
 
}

class ${className}RemoteDatasourceImpl implements ${className}RemoteDatasource {
 
}

''',
    '$baseDir/data/repositories_impl/${featureName}_repository_impl.dart':
        '''
import '../../domain/repositories/${featureName}_repository.dart';
import '../datasources/${featureName}_remote_datasource.dart';
abstract class ${className}RepositoryInternal implements ${className}Repository {}

class ${className}RepositoryImpl implements ${className}RepositoryInternal{
  final ${className}RemoteDatasource remoteDatasource;

  ${className}RepositoryImpl(this.remoteDatasource);

  
}

''',
    '$baseDir/domain/repositories/${featureName}_repository.dart':
        '''
abstract class ${className}Repository {
  
}

 ''',
    '$baseDir/presentation/controller/${featureName}_provider.dart':
        '''
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
part '../state/${featureName}_state.dart';

final ${variableName}Provider =
    StateNotifierProvider.autoDispose<${className}Controller, ${className}State>(
        (ref) => ${className}Controller());

class ${className}Controller extends StateNotifier<${className}State> {
  ${className}Controller() : super(${className}State());
}
''',
    '$baseDir/presentation/state/${featureName}_state.dart':
        '''
part of '../controller/${featureName}_provider.dart';

class ${className}State extends Equatable {
  @override
  List<Object?> get props => [];
}
''',
    '$baseDir/presentation/view/${featureName}_screen.dart':
        '''
import 'package:flutter/material.dart';

class ${className}Screen extends StatelessWidget {
  const ${className}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$className')),
      body: const Center(child: Text('Coming soon...')),
    );
  }
}
''',
  };

  for (final path in files.keys) {
    try {
      final file = File(path);
      file.createSync(recursive: true);
      file.writeAsStringSync(files[path]!);
      debugPrint('✅ Created: $path');
    } catch (e) {
      debugPrint('❌ Failed to create file: $path\nError: $e');
    }
  }

  debugPrint('\n🎉 Feature "$featureName" created with basic structure.');
}

String _capitalize(String input) =>
    input.isNotEmpty ? input[0].toUpperCase() + input.substring(1) : '';

String _camelCase(String input) {
  final parts = input.split('_');
  return parts.first + parts.skip(1).map((word) => _capitalize(word)).join();
}

extension StringExtensions on String {
  String capitalize() {
    if (trim().isNotEmpty) {
      final words = trim()
          .split(' ')
          .map((e) => e[0].toUpperCase() + (e.length > 1 ? e.substring(1) : ''))
          .toList();
      return words.join(' ');
    } else {
      return this;
    }
  }
}

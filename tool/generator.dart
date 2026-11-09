import 'dart:io';

import 'package:flutter/material.dart';

void main(List<String> args) {
  if (args.length != 2) {
    debugPrint('Usage: dart generator.dart <folder_name> <function_name>');
    return;
  }

  final folderName = args[0];
  final functionName = args[1];
  final className = '${_capitalize(folderName)}DataSource';
  final fileName = '${folderName}_datasource.dart';

  final directory = Directory(folderName);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }

  final file = File('${directory.path}/$fileName');
  if (!file.existsSync()) {
    file.writeAsStringSync('''
class $className {
  $functionName() {}
}
''');
    debugPrint('Created $fileName with $functionName()');
    return;
  }

  final String content = file.readAsStringSync();

  // Check if function already exists
  if (content.contains('$functionName()')) {
    debugPrint('$functionName() already exists in $fileName');
    return;
  }

  // Insert new function before last closing }
  final updatedContent = content.replaceFirstMapped(
    RegExp(r'(}\s*)$'),
    (match) => '  $functionName() {}\n${match[0]}',
  );

  file.writeAsStringSync(updatedContent);
  debugPrint('Added $functionName() to $fileName');
}

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

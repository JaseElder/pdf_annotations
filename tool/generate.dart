import 'dart:io';

void main() async {
  stdout.writeln('Generating Pigeon files...');

  final pigeonFiles = Directory('pigeons').listSync().where((file) => file.path.endsWith('.dart'));

  for (final file in pigeonFiles) {
    stdout.writeln('Processing ${file.path}...');
    final result = await Process.run('dart', [
      'run',
      'pigeon',
      '--input',
      file.path,
    ]);

    if (result.exitCode != 0) {
      stdout.writeln('Error generating Pigeon for ${file.path}:');
      stdout.writeln(result.stdout);
      stdout.writeln(result.stderr);
      exit(1);
    }
  }

  stdout.writeln('Post-processing generated Dart files to remove meta dependency...');

  final generatedDir = Directory('lib/generated');
  if (generatedDir.existsSync()) {
    final generatedFiles = generatedDir.listSync().where((file) => file.path.endsWith('.dart'));

    for (final file in generatedFiles) {
      if (file is File) {
        final content = file.readAsStringSync();
        if (content.contains("import 'package:meta/meta.dart'")) {
          stdout.writeln('Removing meta import from ${file.path}');
          // Regex to remove the import line and the following newline
          final updatedContent = content.replaceFirst(
            RegExp(r"import 'package:meta/meta.dart' show .*;\n+"),
            '',
          );
          file.writeAsStringSync(updatedContent);
        }
      }
    }

    await Process.run('dart', [
      'format',
      'lib/generated/.',
    ]);
  }

  stdout.writeln('Generation complete.');
}

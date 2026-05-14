import 'dart:io';

void main() {
  void processFile(File file) {
    String content = file.readAsStringSync();
    
    if (content.contains("import 'utils/currency_format.dart';")) {
      String path = file.path.replaceAll('\\', '/');
      int depth = path.split('/').length - 2;
      if (depth < 0) depth = 0;
      
      String prefix = '';
      for (int i = 0; i < depth; i++) {
        prefix += '../';
      }
      
      content = content.replaceAll(
        "import 'utils/currency_format.dart';", 
        "import '${prefix}utils/currency_format.dart';"
      );
      
      file.writeAsStringSync(content);
      print('Fixed ${file.path} with prefix ${prefix}');
    }
  }

  for (var entity in Directory('lib').listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      processFile(entity);
    }
  }
}

import 'dart:io';

void main() {
  final dir = Directory('lib');
  
  void processFile(File file) {
    String content = file.readAsStringSync();
    String orig = content;
    
    // RegExp to replace 'Rp ${...toInt()}' -> CurrencyFormat.idr(...)
    content = content.replaceAllMapped(RegExp(r"'Rp \$\{([^}]+)\.toInt\(\)\}'"), (match) {
      return 'CurrencyFormat.idr(${match.group(1)})';
    });
    
    content = content.replaceAllMapped(RegExp(r"'Rp \$\{([^}]+)\}'"), (match) {
      return 'CurrencyFormat.idr(${match.group(1)})';
    });
    
    content = content.replaceAll("NumberFormat.currency(locale: 'en_US', symbol: '\\\$')", "NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)");
    content = content.replaceAll("NumberFormat.currency(locale: 'en_US', symbol: 'Rp ', decimalDigits: 0)", "NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)");
    
    content = content.replaceAll("'Rp 0'", "CurrencyFormat.idr(0)");
    
    if (content != orig) {
      String path = file.path.replaceAll('\\\\', '/');
      int depth = path.split('/').length - 2;
      if (depth < 0) depth = 0;
      
      String prefix = '';
      for (int i = 0; i < depth; i++) {
        prefix += '../';
      }
      
      String importStmt = "import '${prefix}utils/currency_format.dart';\n";
      
      List<String> lines = content.split('\n');
      int lastImport = 0;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('import ')) {
          lastImport = i;
        }
      }
      
      // If we already have the import, don't add it again
      if (!content.contains('currency_format.dart')) {
        lines.insert(lastImport + 1, importStmt.trim());
      }
      
      file.writeAsStringSync(lines.join('\n'));
      print('Updated ${file.path}');
    }
  }

  void walkDir(Directory directory) {
    for (var entity in directory.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart') && !entity.path.contains('utils')) {
        processFile(entity);
      }
    }
  }

  walkDir(dir);
  print('Done formatting to IDR!');
}

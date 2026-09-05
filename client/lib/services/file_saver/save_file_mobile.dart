import 'dart:io';

Future<void> saveAndLaunchPdf(List<int> bytes, String fileName) async {
  try {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
  } catch (e) {
    // Handle error gracefully
  }
}

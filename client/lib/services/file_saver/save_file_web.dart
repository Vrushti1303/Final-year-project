// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveAndLaunchPdf(List<int> bytes, String fileName) async {
  final Uint8List byteList = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final blob = html.Blob([byteList], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);

  // Keep Blob URL active for 10 seconds so browser download stream completes cleanly
  Future.delayed(const Duration(seconds: 10), () {
    html.Url.revokeObjectUrl(url);
  });
}

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> savePdf(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = fileName
    ..click();
  Timer(const Duration(seconds: 1), () => html.Url.revokeObjectUrl(url));
  return true;
}

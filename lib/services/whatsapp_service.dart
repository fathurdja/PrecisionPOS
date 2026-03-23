import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WhatsAppService {
  Future<void> shareTextContent(String content, {String? phoneNumber}) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final url = Uri.parse('whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(content)}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // ignore: deprecated_member_use
        await Share.share(content);
      }
    } else {
      // ignore: deprecated_member_use
      await Share.share(content);
    }
  }

  Future<void> sharePdfFile(File pdfFile, {String? text}) async {
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(pdfFile.path)], text: text);
  }
}

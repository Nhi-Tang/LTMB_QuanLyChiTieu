import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/receipt_parser.dart';

/// Kết quả quét: thông tin đọc được và đường dẫn ảnh để người dùng xem lại.
class ReceiptScanResult {
  final ReceiptData data;
  final String imagePath;

  const ReceiptScanResult({required this.data, required this.imagePath});
}

/// Chọn ảnh hoá đơn rồi đọc chữ bằng ML Kit ngay trên máy (ảnh không gửi lên server).
class ReceiptScanService {
  ReceiptScanService._();
  static final ReceiptScanService instance = ReceiptScanService._();

  final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh hoá đơn có sẵn; null nếu người dùng huỷ.
  Future<String?> pickFromGallery() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      // Giảm kích thước để đọc nhanh, vẫn đủ nét cho chữ hoá đơn
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    return photo?.path;
  }

  /// Đọc chữ trên ảnh rồi tách thông tin hoá đơn.
  Future<ReceiptScanResult> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return ReceiptScanResult(
        data: ReceiptParser.parse(_rowsText(recognized)),
        imagePath: imagePath,
      );
    } finally {
      await recognizer.close();
    }
  }

  /// ML Kit hay tách cột tên món và cột giá thành các khối riêng. Ghép lại theo hàng:
  /// các dòng có tâm dọc gần nhau là cùng một hàng hoá đơn, xếp trái sang phải.
  /// Ảnh chụp bằng tay thường nghiêng vài độ, nên xoay toạ độ theo độ nghiêng chung trước khi so.
  String _rowsText(RecognizedText recognized) {
    final lines = [for (final b in recognized.blocks) ...b.lines];
    if (lines.isEmpty) return '';

    // Độ nghiêng của từng dòng lấy từ cạnh trên (góc trên-trái → trên-phải); dùng trung vị cho cả ảnh
    final angles = <double>[];
    for (final l in lines) {
      final p = l.cornerPoints;
      if (p.length >= 2 && p[1].x != p[0].x) {
        angles.add(atan2((p[1].y - p[0].y).toDouble(), (p[1].x - p[0].x).toDouble()));
      }
    }
    angles.sort();
    final skew = angles.isEmpty ? 0.0 : angles[angles.length ~/ 2];
    final sinA = sin(skew), cosA = cos(skew);

    // Toạ độ sau khi xoay thẳng: y' theo hàng, x' theo cột
    double rowY(TextLine l) => -l.boundingBox.center.dx * sinA + l.boundingBox.center.dy * cosA;
    double colX(TextLine l) => l.boundingBox.center.dx * cosA + l.boundingBox.center.dy * sinA;
    double lineHeight(TextLine l) {
      final p = l.cornerPoints;
      if (p.length < 4) return l.boundingBox.height;
      return sqrt(pow(p[3].x - p[0].x, 2) + pow(p[3].y - p[0].y, 2));
    }

    lines.sort((a, b) => rowY(a).compareTo(rowY(b)));
    final rows = <List<TextLine>>[];
    for (final line in lines) {
      if (rows.isNotEmpty) {
        final first = rows.last.first;
        if ((rowY(line) - rowY(first)).abs() < lineHeight(first) * 0.6) {
          rows.last.add(line);
          continue;
        }
      }
      rows.add([line]);
    }

    return rows.map((row) {
      row.sort((a, b) => colX(a).compareTo(colX(b)));
      return row.map((l) => l.text).join('  ');
    }).join('\n');
  }
}

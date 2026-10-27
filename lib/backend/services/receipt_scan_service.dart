import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/receipt_parser.dart';

/// Kết quả quét: thông tin đọc được và đường dẫn ảnh để người dùng xem lại.
class ReceiptScanResult {
  final ReceiptData data;
  final String imagePath;

  const ReceiptScanResult({required this.data, required this.imagePath});
}

/// Chụp / chọn ảnh hoá đơn rồi đọc chữ bằng ML Kit ngay trên máy (ảnh không gửi lên server).
class ReceiptScanService {
  ReceiptScanService._();
  static final ReceiptScanService instance = ReceiptScanService._();

  final ImagePicker _picker = ImagePicker();

  /// Trả về null nếu người dùng huỷ chụp / chọn ảnh.
  /// [onImagePicked] gọi khi đã có ảnh, trước lúc đọc chữ (để hiện vòng tải).
  Future<ReceiptScanResult?> scan({required bool fromCamera, void Function()? onImagePicked}) async {
    final photo = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      // Giảm kích thước để đọc nhanh, vẫn đủ nét cho chữ hoá đơn
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (photo == null) return null;
    onImagePicked?.call();

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(InputImage.fromFilePath(photo.path));
      return ReceiptScanResult(
        data: ReceiptParser.parse(_rowsText(recognized)),
        imagePath: photo.path,
      );
    } finally {
      await recognizer.close();
    }
  }

  /// ML Kit hay tách cột tên món và cột giá thành các khối riêng. Ghép lại theo hàng:
  /// các dòng có tâm dọc gần nhau là cùng một hàng hoá đơn, xếp trái sang phải.
  String _rowsText(RecognizedText recognized) {
    final lines = [for (final b in recognized.blocks) ...b.lines]
      ..sort((a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));

    final rows = <List<TextLine>>[];
    for (final line in lines) {
      final box = line.boundingBox;
      if (rows.isNotEmpty) {
        final last = rows.last.first.boundingBox;
        if ((box.center.dy - last.center.dy).abs() < last.height * 0.6) {
          rows.last.add(line);
          continue;
        }
      }
      rows.add([line]);
    }

    return rows.map((row) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      return row.map((l) => l.text).join('  ');
    }).join('\n');
  }
}

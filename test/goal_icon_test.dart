import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/frontend/widgets/mousey_avatar.dart';

void main() {
  test('icon mục tiêu điện thoại cũ (đã xoá) đổi sang cat_phone', () {
    expect(normalizeGoalIcon('assets/icon/dienthoai_icon.jpg'), 'assets/icon/cat_phone.png');
  });

  test('icon mục tiêu khác giữ nguyên, null dùng icon tiết kiệm', () {
    expect(normalizeGoalIcon('assets/icon/xe_icon.jpg'), 'assets/icon/xe_icon.jpg');
    expect(normalizeGoalIcon(null), 'assets/icon/tietkiem_icon.jpg');
  });
}

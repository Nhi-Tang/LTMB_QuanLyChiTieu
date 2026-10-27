import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/models/category_model.dart';

CategoryModel _cat(String name, String iconKey) => CategoryModel(
      name: name,
      iconKey: iconKey,
      type: 'expense',
      sortOrder: 0,
      isDefault: false,
      isArchived: false,
      createdAt: '',
      updatedAt: '',
    );

void main() {
  test('tên danh mục mặc định có hoặc không dấu đều ra cùng icon', () {
    expect(CategoryModel.getCategoryAssetPath('Ăn uống'), 'assets/icon/cat_an_uong.png');
    expect(CategoryModel.getCategoryAssetPath('an uong'), 'assets/icon/cat_an_uong.png');
    expect(CategoryModel.getCategoryAssetPath('Sức khoẻ'), 'assets/icon/cat_suc_khoe.png');
    expect(CategoryModel.getCategoryAssetPath('Sức khỏe'), 'assets/icon/cat_suc_khoe.png');
    // Dạng dấu tổ hợp (NFD)
    expect(CategoryModel.getCategoryAssetPath('Tiền nợ'), 'assets/icon/cat_tien_no.png');
    expect(CategoryModel.getCategoryAssetPath('Tiền Nợ'), 'assets/icon/cat_tien_no.png');
  });

  test('icon Tất cả cho bộ lọc và Kết hôn', () {
    expect(CategoryModel.getCategoryAssetPath('Tất cả'), 'assets/icon/cat_tat_ca.png');
    expect(CategoryModel.getCategoryAssetPath('total'), 'assets/icon/cat_tat_ca.png');
    expect(CategoryModel.getCategoryAssetPath('Kết hôn'), 'assets/icon/cat_ket_hon.png');
  });

  test('icon Cà phê và Trà sữa theo tên hoặc iconKey', () {
    expect(CategoryModel.getCategoryAssetPath('Cà phê'), 'assets/icon/cat_ca_phe.png');
    expect(CategoryModel.getCategoryAssetPath('cafe'), 'assets/icon/cat_ca_phe.png');
    expect(CategoryModel.getCategoryAssetPath('Trà sữa'), 'assets/icon/cat_tra_sua.png');
    expect(CategoryModel.getCategoryAssetPath('Đồ uống', iconKey: 'local_cafe_rounded'), 'assets/icon/cat_ca_phe.png');
    expect(CategoryModel.getCategoryAssetPath('Đồ uống', iconKey: 'emoji_food_beverage_rounded'), 'assets/icon/cat_tra_sua.png');
  });

  test('icon người dùng chọn được ưu tiên, category_rounded thì theo tên', () {
    expect(CategoryModel.getCategoryAssetPath('Cà phê', iconKey: 'fastfood_rounded'), 'assets/icon/cat_an_uong.png');
    expect(CategoryModel.getCategoryAssetPath('Kết hôn', iconKey: 'category_rounded'), 'assets/icon/cat_ket_hon.png');
    expect(CategoryModel.getCategoryAssetPath('Không biết'), 'assets/icon/cat_khac.png');
  });

  test('giao dịch chỉ lưu tên vẫn lấy icon của danh mục tự tạo', () {
    CategoryModel.rememberIconKeys([_cat('Tiền mèo', 'pets_rounded')]);
    expect(CategoryModel.getCategoryAssetPath('Tiền mèo'), 'assets/icon/cat_thu_cung.png');
    expect(CategoryModel.getCategoryAssetPath('tien meo'), 'assets/icon/cat_thu_cung.png');
  });
}

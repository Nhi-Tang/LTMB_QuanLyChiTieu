import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../backend/database/db_helper.dart';
import '../../../backend/models/user_model.dart';
import '../../../core/widgets/asset_icon.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';
import '../../utils/app_translations.dart';
import '../app_alert_dialog.dart';
import '../mousey_avatar.dart';

void showEditProfileDialog(
  BuildContext context, {
  required UserModel currentUser,
  required String selectedAvatarKey,
  required void Function(UserModel updatedUser) onUserUpdated,
  required void Function(String newAvatarKey) onAvatarChanged,
}) {
  final lang = context.lang;
  final nameController = TextEditingController(text: currentUser.name);
  final emailController = TextEditingController(text: currentUser.email);
  final formKey = GlobalKey<FormState>();
  var avatarKey = selectedAvatarKey;

  void changeAvatar(String key, StateSetter setDialogState) {
    onAvatarChanged(key);
    setDialogState(() => avatarKey = key);
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppTranslations.tr(lang, 'personal_info'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarPickerSheet(
                      context,
                      selectedAvatarKey: avatarKey,
                      userName: currentUser.name,
                      onSelected: (key) => changeAvatar(key, setDialogState),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        buildUserAvatar(
                          avatarKey: avatarKey,
                          userName: currentUser.name,
                          size: 72,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accentBeige,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: AppTranslations.tr(lang, 'full_name'),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(10),
                        child: AssetIcon('tab_ca_nhan', size: 26),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập họ và tên') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppTranslations.tr(lang, 'email_or_phone'),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(10),
                        child: AssetIcon('ui_thu', size: 26),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập Email / SĐT') : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.tr(lang, 'cancel'),
                style: TextStyle(color: AppColors.grey500),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBeige,
                foregroundColor: AppColors.onTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newName = nameController.text.trim();
                  final newEmail = emailController.text.trim().toLowerCase();

                  final updatedUser = currentUser.copyWith(
                    name: newName,
                    email: newEmail,
                  );

                  await DatabaseHelper.instance.updateUser(updatedUser);
                  onUserUpdated(updatedUser);

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);

                  if (!context.mounted) return;
                  showAppAlertDialog(
                    context: context,
                    title: context.t('Thành công'),
                    message: context.t('Đã cập nhật thông tin cá nhân thành công!'),
                    isSuccess: true,
                  );
                }
              },
              child: Text(
                AppTranslations.tr(lang, 'save_changes'),
                style: const TextStyle(color: AppColors.onTeal, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ),
  );
}

void _showAvatarPickerSheet(
  BuildContext context, {
  required String selectedAvatarKey,
  required String userName,
  required void Function(String key) onSelected,
}) {
  final lang = context.lang;
  final avatars = [
    {'key': 'cat', 'name': 'Mochi Cat'},
    {'key': 'dog', 'name': context.t('Cún con')},
    {'key': 'fox', 'name': context.t('Cáo nhỏ')},
    {'key': 'rabbit', 'name': context.t('Thỏ con')},
    {'key': 'panda', 'name': context.t('Gấu trúc')},
    {'key': 'lion', 'name': context.t('Sư tử')},
    {'key': 'bear', 'name': context.t('Gấu bông')},
    {'key': 'initials', 'name': 'Mousey'},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppTranslations.tr(lang, 'choose_avatar'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBeige,
                    foregroundColor: AppColors.darkBeige,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    AppTranslations.tr(lang, 'upload_from_device'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showDeviceImagePicker(context, onSelected: onSelected);
                  },
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final item = avatars[index];
                  final key = item['key'] as String;
                  final isSel = selectedAvatarKey == key;

                  return InkWell(
                    onTap: () {
                      onSelected(key);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primaryBeige : AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSel ? AppColors.darkBeige : Colors.transparent,
                          width: isSel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildUserAvatar(
                            avatarKey: key,
                            userName: userName,
                            size: 38,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['name'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? AppColors.darkBeige : AppColors.black87,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showDeviceImagePicker(
  BuildContext context, {
  required void Function(String path) onSelected,
}) async {
  final lang = context.lang;
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      onSelected(pickedFile.path);
      if (!context.mounted) return;
      showAppAlertDialog(
        context: context,
        title: AppTranslations.tr(lang, 'choose_avatar'),
        message: context.t('Đã cập nhật ảnh đại diện từ thiết bị thành công!'),
        isSuccess: true,
      );
    }
  } catch (e) {
    if (context.mounted) {
      showAppAlertDialog(
        context: context,
        title: context.t('Lỗi chọn ảnh'),
        message: context.t('Không thể mở thư viện ảnh: {e}', {'e': e}),
        isSuccess: false,
      );
    }
  }
}

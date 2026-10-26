import 'package:flutter/material.dart';
import '../../../backend/database/db_helper.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
import '../../utils/app_language.dart';

/// Bottom Sheet nhập ghi chú giao dịch chuẩn AppColors, hỗ trợ gợi ý từ lịch sử và i18n
Future<String?> showNoteSheet({
  required BuildContext context,
  required String currentNote,
  String? category,
}) async {
  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NoteSheetWidget(
      currentNote: currentNote,
      category: category,
    ),
  );
}

class _NoteSheetWidget extends StatefulWidget {
  final String currentNote;
  final String? category;

  const _NoteSheetWidget({
    required this.currentNote,
    this.category,
  });

  @override
  State<_NoteSheetWidget> createState() => _NoteSheetWidgetState();
}

class _NoteSheetWidgetState extends State<_NoteSheetWidget> {
  late TextEditingController _noteController;
  List<String> _recentNotes = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.currentNote);
    _loadRecentNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentNotes() async {
    try {
      final txs = await DatabaseHelper.instance.getTransactions();
      final Set<String> uniqueNotes = {};

      for (var t in txs) {
        final title = t.title.trim();
        if (title.isNotEmpty && title != t.category) {
          if (widget.category == null || t.category == widget.category) {
            uniqueNotes.add(title);
          }
        }
        if (uniqueNotes.length >= 5) break;
      }

      // Fallback nếu chưa đủ 5 gợi ý theo danh mục
      if (uniqueNotes.length < 5) {
        for (var t in txs) {
          final title = t.title.trim();
          if (title.isNotEmpty && title != t.category) {
            uniqueNotes.add(title);
          }
          if (uniqueNotes.length >= 5) break;
        }
      }

      if (mounted) {
        setState(() {
          _recentNotes = uniqueNotes.toList();
          _isLoadingRecent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRecent = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final lang = context.lang;

    return Padding(
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.tealWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.tealPale, width: 1.5)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.darkBeige, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppTranslations.tr(lang, 'enter_note_title'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBeige,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Text Input Box (Max 120 chars, Autofocus)
              TextField(
                controller: _noteController,
                autofocus: true,
                maxLength: 120,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: AppColors.darkBeige, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: AppTranslations.tr(lang, 'note_hint'),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.tealPale),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.tealPale),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Recent Suggestions Chips
              if (!_isLoadingRecent && _recentNotes.isNotEmpty) ...[
                Text(
                  AppTranslations.tr(lang, 'recent_suggestions'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _recentNotes.map((note) {
                    return ActionChip(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.tealPale),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      label: Text(
                        note,
                        style: const TextStyle(fontSize: 12, color: AppColors.darkBeige, fontWeight: FontWeight.w500),
                      ),
                      onPressed: () {
                        setState(() {
                          _noteController.text = note;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.tealPale),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _noteController.clear();
                        });
                      },
                      child: Text(
                        AppTranslations.tr(lang, 'clear'),
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBeige,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context, _noteController.text.trim());
                      },
                      child: Text(
                        AppTranslations.tr(lang, 'save'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import '../../core/utils/money_input_formatter.dart';
import 'app_texts.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _keys = {
    'vi': {
      'home': 'Trang chủ',
      'savings': 'Tiết kiệm',
      'budgets': 'Ngân sách',
      'reports': 'Báo cáo',
      'profile': 'Cá nhân',
      'total_balance': 'Tổng số dư',
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'recent_transactions': 'Hoạt động gần đây',
      'view_all': 'Xem tất cả',
      'no_transactions': 'Chưa có giao dịch nào trong tháng này',
      'add_first_transaction': 'Nhấn vào nút Thu nhập/Chi tiêu ở trên hoặc nút (+) bên dưới để thêm giao dịch đầu tiên nhé!',
      'add_transaction': 'Thêm giao dịch mới',
      'add_expense': 'Nhập khoản chi tiêu',
      'add_income': 'Nhập khoản thu nhập',
      'transaction_title': 'Ghi chú / Tên giao dịch',
      'amount': 'Số tiền (đ)',
      'category': 'Danh mục',
      'save_transaction': 'LƯU GIAO DỊCH',
      'savings_management': 'Quản lý Tiết kiệm',
      'savings_goals': 'MỤC TIÊU TIẾT KIỆM',
      'create_goal': 'Tạo mục tiêu',
      'no_savings_goals': 'Chưa có mục tiêu tiết kiệm nào',
      'net_income': 'Thu nhập ròng',
      'total_spent': 'TỔNG ĐÃ CHI',
      'total_earned': 'TỔNG ĐÃ KIẾM',
      'details': 'CHI TIẾT',
      'trend': 'XU HƯỚNG',
      'income_sources': 'NGUỒN THU',
      'personal_account': 'TÀI KHOẢN CÁ NHÂN',
      'personal_info': 'Thông tin cá nhân',
      'upgrade_account': 'Nâng cấp tài khoản',
      'upgrade_account_subtitle': 'Nâng cấp lên PRO để mở khóa tất cả tính năng',
      'ledger_settings': 'CÀI ĐẶT SỔ',
      'ledger_book': 'Sổ sách',
      'categories_manager': 'Danh mục chi tiêu / thu nhập',
      'export_files': 'Xuất file CSV, XLSX',
      'app_settings': 'CÀI ĐẶT ỨNG DỤNG',
      'language': 'Ngôn ngữ',
      'balance_toggle': 'Số dư',
      'daily_reminder': 'Nhắc nhở hằng ngày',
      'about': 'GIỚI THIỆU',
      'rate_app': 'Đánh giá Mousey',
      'contact_support': 'Liên hệ hỗ trợ',
      'version': 'Phiên bản',
      'logout': 'Đăng xuất tài khoản',
      'logout_subtitle': 'Đăng xuất tài khoản khỏi thiết bị này',
      'cancel': 'Hủy',
      'save_changes': 'LƯU THAY ĐỔI',
      'all_time': 'Toàn bộ thời gian',
      'this_month': 'Tháng này',
      'last_month': 'Tháng trước',
      'last_3_months': '3 tháng gần nhất',
      'this_year': 'Năm nay',
      'filter': 'Bộ lọc',
      'filter_categories': 'Lọc theo danh mục',
      'all_categories': 'Tất cả danh mục',
      'no_report_data': 'Chưa có dữ liệu báo cáo',
      'add_transaction_for_analysis': 'Thêm giao dịch mới để xem phân tích chi tiết theo danh mục nhé!',
      'no_income_data': 'Chưa có nguồn thu nào',
      'add_income_for_analysis': 'Thêm giao dịch thu nhập mới để xem phân tích nguồn thu nhé!',
      'avg_per_month': 'TB / tháng',
      'recent_months': '{n} tháng gần nhất',
      'saved_amount': 'đã tiết kiệm',
      'no_balance_data': 'Chưa có dữ liệu số dư. Bắt đầu tích lũy tài chính ngay hôm nay nhé!',
      'no_financial_period_data': 'Chưa có dữ liệu kỳ tài chính',
      'mousey_savings_badge': 'MỤC TIÊU TIẾT KIỆM · MOUSEY',
      'mousey_friend': 'Mousey, Người bạn ngân sách thân thiện của bạn',
      'mousey_quote_home': '"Tích tiểu thành đại! Hãy tạo các mục tiêu tiết kiệm để Mousey giúp bạn chạm tới ước mơ nhé!"',
      'mousey_quote_no_expense': '"Chưa có dữ liệu phân tích chi tiêu. Hãy ghi chép giao dịch đầu tiên để Mousey giúp bạn theo dõi tài chính nhé!"',
      'mousey_quote_no_income': '"Chưa có dữ liệu thu nhập. Hãy ghi nhận khoản thu đầu tiên để Mousey giúp bạn theo dõi tài chính nhé!"',
      'full_name': 'Họ và tên',
      'email_or_phone': 'Email / Số điện thoại',
      'choose_avatar': 'Chọn Avatar đại diện',
      'upload_from_device': 'Tải ảnh từ máy / Thư viện',
      'income_expense_categories': 'Danh mục Thu & Chi',
      'ledger_settings_title': 'Cài đặt Sổ sách',
      'in_use': 'Đang dùng',
      'add_new_ledger': 'Thêm sổ mới (Nâng cấp PRO)',
      'export_report_title': 'Xuất file báo cáo (Pro)',
      'export_report_subtitle': 'Chọn định dạng file xuất dữ liệu thu chi cá nhân:',
      'export_csv_title': 'Xuất file CSV (.csv)',
      'export_csv_sub': 'Phù hợp cho Google Sheets & hệ thống dữ liệu',
      'export_excel_title': 'Xuất file Excel (.xlsx)',
      'export_excel_sub': 'Đầy đủ định dạng & công thức Microsoft Excel',
      'rate_message': 'Cảm ơn bạn đã sử dụng Mousey! Hãy để lại đánh giá 5 sao trên cửa hàng ứng dụng nhé ⭐⭐⭐⭐⭐',
      'support_message': 'Hỗ trợ khách hàng Mousey:\n• Email: support@mousey.com\n• Hotline: 1900-MOUSEY\n• Giờ làm việc: 8:00 - 20:00 (T2 - T7)',
      'export_csv_success': 'Đã xuất file Mousey_Report.csv vào thư mục Tải về!',
      'export_excel_success': 'Đã xuất file Mousey_Report.xlsx vào thư mục Tải về!',
      'balance_subtitle': 'Hiển thị số dư sau mỗi lần giao dịch',
      'reminder_subtitle': 'Lời nhắc từ Mousey khi bạn quên ghi chép',
      'categories_count_subtitle': '23 danh mục mặc định',
      'notifications': 'Thông báo',
      'notification_center': 'Trung tâm thông báo',
      'mark_all_read': 'Đọc tất cả',
      'pending_confirmation': 'Chờ xác nhận',
      'today': 'Hôm nay',
      'today_section': 'HÔM NAY',
      'earlier': 'Trước đó',
      'earlier_section': 'TRƯỚC ĐÓ',
      'no_notifications': 'Chưa có thông báo nào',
      'no_notifications_subtitle': 'Khi có biến động số dư hoặc cảnh báo ngân sách, Mousey sẽ hiển thị thông báo ở đây.',
      'clear_all': 'Xóa tất cả',
      'just_now': 'Vừa xong',
      'minutes_ago': 'phút trước',
      'hours_ago': 'giờ trước',
      'days_ago': 'ngày trước',
      'pending_drafts_count': 'bản nháp',
      'enter_note_title': 'Nhập ghi chú giao dịch',
      'note_hint': 'Giao dịch này có ghi chú gì?...',
      'recent_suggestions': 'GỢI Ý GẦN ĐÂY',
      'clear': 'Xóa',
      'save': 'Lưu',
      'budget_overview': 'Ngân sách',
      'auto_finance_banking': 'TỰ ĐỘNG THU CHI & NGÂN HÀNG',
      'approve_bank_tx_sub': 'Duyệt giao dịch ngân hàng đọc tự động',
      'bank_notification_settings': 'Cài đặt đọc thông báo ngân hàng',
      'bank_list_subtitle': 'Vietcombank, MB, Techcombank, MoMo,...',
      'cloud_sync_section': 'ĐỒNG BỘ DỮ LIỆU ĐÁM MÂY',
      'sync_status_title': 'Trạng thái đồng bộ',
      'sync_now': 'Đồng bộ ngay',
      'account_security_section': 'QUẢN LÝ TÀI KHOẢN & BẢO MẬT',
      'delete_all_data': 'Xoá toàn bộ dữ liệu',
      'delete_all_data_sub': 'Xoá giao dịch, tài khoản & danh mục tuỳ chỉnh',
      'add_ledger_btn': 'Thêm sổ mới',
      'last_sync_label': 'Lần cuối',
      'synced_status': 'Đã đồng bộ',
      'not_synced_status': 'Chưa đồng bộ',
      'sync_state_synced': 'Đã đồng bộ',
      'sync_state_syncing': 'Đang đồng bộ...',
      'sync_state_error': 'Lỗi đồng bộ',
      'never': 'Chưa',
      'welcome_back': 'Chào mừng bạn trở lại',
      'sync_status_label': 'Trạng thái',
      'budget_alerts_toggle': 'Cảnh báo ngân sách',
      'budget_alerts_subtitle': 'Nhắc nhở thân thiện khi chi tiêu vượt hạn mức',
      'upgrade_pro_title': 'Nâng cấp Mousey PRO 👑',
      'upgrade_pro_desc': 'Mở khóa sổ sách không giới hạn, xuất Excel...',
      'upgrade': 'Nâng cấp',
      'no_recent_transactions': 'Không có giao dịch gần đây',
      'total_savings': 'TỔNG TIỀN ĐÃ TIẾT KIỆM',
      'add_savings_goal': 'Thêm mục tiêu tiết kiệm',
      'goal_name': 'Tên mục tiêu',
      'target_amount': 'Số tiền cần đạt (đ)',
      'initial_amount': 'Số tiền đã có sẵn ban đầu (đ)',
      'deadline_optional': 'Hạn hoàn thành (Tùy chọn)',
      'choose_icon': 'Chọn Icon:',
      'create_goal_btn': 'TẠO MỤC TIÊU',
      'edit_savings_goal': 'Sửa mục tiêu tiết kiệm',
      'pro_upgrade_title': 'Nâng Cấp Mousey PRO',
      'pro_upgrade_subtitle': 'Trải nghiệm trọn vẹn sức mạnh quản lý tài chính thông minh',
      'pro_benefits': 'Quyền lợi độc quyền PRO',
      'benefit_1_title': 'Thêm không giới hạn Sổ sách quản lý',
      'benefit_1_sub': 'Quản lý riêng biệt quỹ cá nhân, gia đình, công việc',
      'benefit_2_title': 'Xuất báo cáo Excel (.xlsx) & CSV',
      'benefit_2_sub': 'Dễ dàng lưu trữ và phân tích dữ liệu chuyên sâu',
      'benefit_3_title': 'Lời nhắc ghi chép thông minh',
      'benefit_3_sub': 'Tự động nhắc khi có thông báo số dư ngân hàng',
      'benefit_4_title': 'Sao lưu và đồng bộ Cloud an toàn',
      'benefit_4_sub': 'Đồng bộ dữ liệu thời gian thực giữa các thiết bị',
      'choose_plan': 'Chọn gói đăng ký phù hợp',
      'yearly_plan': 'Gói Năm (Khuyên dùng)',
      'best_value': 'TIẾT KIỆM NHẤT',
      'yearly_saving': 'Tiết kiệm 17% (~16.600đ/tháng)',
      'monthly_plan': 'Gói Tháng',
      'start_trial_btn': 'Dùng thử miễn phí 7 ngày',
      'subscribe_now': 'Đăng ký ngay',
    },
    'en': {
      'home': 'Home',
      'savings': 'Savings',
      'budgets': 'Budgets',
      'reports': 'Reports',
      'profile': 'Profile',
      'total_balance': 'Total Balance',
      'income': 'Income',
      'expense': 'Expenses',
      'recent_transactions': 'Recent Transactions',
      'view_all': 'View all',
      'no_transactions': 'No transactions this month',
      'add_first_transaction': 'Tap Income/Expense above or (+) below to add your first transaction!',
      'add_transaction': 'Add New Transaction',
      'add_expense': 'Add Expense',
      'add_income': 'Add Income',
      'transaction_title': 'Note / Transaction Name',
      'amount': 'Amount',
      'category': 'Category',
      'save_transaction': 'SAVE TRANSACTION',
      'savings_management': 'Savings Management',
      'savings_goals': 'SAVINGS GOALS',
      'create_goal': 'Create Goal',
      'no_savings_goals': 'No savings goals yet',
      'net_income': 'Net Income',
      'total_spent': 'TOTAL SPENT',
      'total_earned': 'TOTAL EARNED',
      'details': 'DETAILS',
      'trend': 'TREND',
      'income_sources': 'INCOME SOURCES',
      'personal_account': 'PERSONAL ACCOUNT',
      'personal_info': 'Personal Information',
      'upgrade_account': 'Upgrade Account',
      'upgrade_account_subtitle': 'Upgrade to PRO to unlock all features',
      'ledger_settings': 'LEDGER SETTINGS',
      'ledger_book': 'Ledger Book',
      'categories_manager': 'Income & Expense Categories',
      'export_files': 'Export CSV, XLSX Files',
      'app_settings': 'APP SETTINGS',
      'language': 'Language',
      'balance_toggle': 'Balance',
      'daily_reminder': 'Daily Reminder',
      'about': 'ABOUT',
      'rate_app': 'Rate Mousey',
      'contact_support': 'Contact Support',
      'version': 'Version',
      'logout': 'Log Out',
      'logout_subtitle': 'Log out account from this device',
      'cancel': 'Cancel',
      'save_changes': 'SAVE CHANGES',
      'all_time': 'All Time',
      'this_month': 'This Month',
      'last_month': 'Last Month',
      'last_3_months': 'Last 3 Months',
      'this_year': 'This Year',
      'filter': 'Filter',
      'filter_categories': 'Filter by Category',
      'all_categories': 'All Categories',
      'no_report_data': 'No report data yet',
      'add_transaction_for_analysis': 'Add new transactions to view category analysis!',
      'no_income_data': 'No income sources yet',
      'add_income_for_analysis': 'Add new income transactions to view income analysis!',
      'avg_per_month': 'Avg / month',
      'recent_months': 'last {n} months',
      'saved_amount': 'saved',
      'no_balance_data': 'No balance data yet. Start building your savings today!',
      'no_financial_period_data': 'No financial period data yet',
      'mousey_savings_badge': 'MOUSEY SAVINGS · MOUSEY',
      'mousey_friend': 'Mousey, Your friendly budget companion',
      'mousey_quote_home': '"Many a little makes a mickle! Create savings goals and let Mousey help you reach your dreams!"',
      'mousey_quote_no_expense': '"No expense data yet. Record your first transaction to let Mousey help track your finances!"',
      'mousey_quote_no_income': '"No income data yet. Record your first income to let Mousey help track your finances!"',
      'full_name': 'Full Name',
      'email_or_phone': 'Email / Phone Number',
      'choose_avatar': 'Choose Avatar',
      'upload_from_device': 'Upload from Device / Library',
      'income_expense_categories': 'Income & Expense Categories',
      'ledger_settings_title': 'Ledger Settings',
      'in_use': 'In Use',
      'add_new_ledger': 'Add Ledger (PRO Upgrade)',
      'export_report_title': 'Export Report (Pro)',
      'export_report_subtitle': 'Select file format to export personal expense data:',
      'export_csv_title': 'Export CSV (.csv)',
      'export_csv_sub': 'Suitable for Google Sheets & data systems',
      'export_excel_title': 'Export Excel (.xlsx)',
      'export_excel_sub': 'Full formatting & formulas for Microsoft Excel',
      'rate_message': 'Thank you for using Mousey! Please leave a 5-star rating on the app store ⭐⭐⭐⭐⭐',
      'support_message': 'Mousey Customer Support:\n• Email: support@mousey.com\n• Hotline: 1900-MOUSEY\n• Working Hours: 8:00 AM - 8:00 PM (Mon - Sat)',
      'export_csv_success': 'Exported Mousey_Report.csv to Downloads folder successfully!',
      'export_excel_success': 'Exported Mousey_Report.xlsx to Downloads folder successfully!',
      'balance_subtitle': 'Display balance after transactions',
      'reminder_subtitle': 'Daily reminder from Mousey',
      'categories_count_subtitle': '23 default categories',
      'notifications': 'Notifications',
      'notification_center': 'Notification Center',
      'mark_all_read': 'Mark all as read',
      'pending_confirmation': 'Pending confirmation',
      'today': 'Today',
      'today_section': 'TODAY',
      'earlier': 'Earlier',
      'earlier_section': 'EARLIER',
      'no_notifications': 'No notifications yet',
      'no_notifications_subtitle': 'When balance changes or budget alerts happen, Mousey will show notifications here.',
      'clear_all': 'Clear all',
      'just_now': 'Just now',
      'minutes_ago': 'm ago',
      'hours_ago': 'h ago',
      'days_ago': 'd ago',
      'pending_drafts_count': 'drafts',
      'enter_note_title': 'Enter transaction note',
      'note_hint': 'Any notes for this transaction?...',
      'recent_suggestions': 'RECENT SUGGESTIONS',
      'clear': 'Clear',
      'save': 'Save',
      'budget_overview': 'Budgets',
      'auto_finance_banking': 'AUTO FINANCE & BANKING',
      'approve_bank_tx_sub': 'Approve auto-read bank transactions',
      'bank_notification_settings': 'Bank Notification Settings',
      'bank_list_subtitle': 'Vietcombank, MB, Techcombank, MoMo,...',
      'cloud_sync_section': 'CLOUD DATA SYNC',
      'sync_status_title': 'Sync Status',
      'sync_now': 'Sync Now',
      'account_security_section': 'ACCOUNT & SECURITY',
      'delete_all_data': 'Delete All Data',
      'delete_all_data_sub': 'Delete transactions, accounts & custom categories',
      'add_ledger_btn': 'Add New Ledger',
      'last_sync_label': 'Last sync',
      'synced_status': 'Synced',
      'not_synced_status': 'Not synced',
      'sync_state_synced': 'Synced',
      'sync_state_syncing': 'Syncing...',
      'sync_state_error': 'Sync error',
      'never': 'Never',
      'welcome_back': 'Welcome back',
      'sync_status_label': 'Status',
      'budget_alerts_toggle': 'Budget alerts',
      'budget_alerts_subtitle': 'Friendly reminders when spending goes over the limit',
      'upgrade_pro_title': 'Upgrade to Mousey PRO 👑',
      'upgrade_pro_desc': 'Unlock unlimited ledgers, export Excel...',
      'upgrade': 'Upgrade',
      'no_recent_transactions': 'No recent transactions',
      'total_savings': 'TOTAL SAVINGS',
      'add_savings_goal': 'Add Savings Goal',
      'goal_name': 'Goal Name',
      'target_amount': 'Target Amount',
      'initial_amount': 'Initial Amount',
      'deadline_optional': 'Deadline (Optional)',
      'choose_icon': 'Choose Icon:',
      'create_goal_btn': 'CREATE GOAL',
      'edit_savings_goal': 'Edit Savings Goal',
      'pro_upgrade_title': 'Upgrade to Mousey PRO',
      'pro_upgrade_subtitle': 'Experience the full power of smart financial management',
      'pro_benefits': 'Exclusive PRO Benefits',
      'benefit_1_title': 'Add Unlimited Ledgers',
      'benefit_1_sub': 'Manage personal, family, and work funds separately',
      'benefit_2_title': 'Export Excel (.xlsx) & CSV Reports',
      'benefit_2_sub': 'Easily store and analyze in-depth data',
      'benefit_3_title': 'Smart Note Reminders',
      'benefit_3_sub': 'Automatically remind when bank balance notifications arrive',
      'benefit_4_title': 'Secure Cloud Backup & Sync',
      'benefit_4_sub': 'Real-time data sync across devices',
      'choose_plan': 'Choose Suitable Plan',
      'yearly_plan': 'Yearly Plan (Recommended)',
      'best_value': 'BEST VALUE',
      'yearly_saving': 'Save 17% (~16,600 VND/month)',
      'monthly_plan': 'Monthly Plan',
      'start_trial_btn': 'Start 7-Day Free Trial',
      'subscribe_now': 'Subscribe Now',
    },
    'ja': {
      'home': 'ホーム',
      'savings': '貯金',
      'budgets': '予算',
      'reports': 'レポート',
      'profile': 'マイページ',
      'total_balance': '総残高',
      'income': '収入',
      'expense': '支出',
      'recent_transactions': '最近の取引',
      'view_all': 'すべて見る',
      'no_transactions': '今月の取引はありません',
      'add_first_transaction': '上の「収入/支出」または下の(+)ボタンをタップして最初の取引を追加してください！',
      'add_transaction': '新規取引を追加',
      'add_expense': '支出を入力',
      'add_income': '収入を入力',
      'transaction_title': 'メモ / 取引名',
      'amount': '金額',
      'category': 'カテゴリー',
      'save_transaction': '取引を保存',
      'savings_management': '貯金管理',
      'savings_goals': '貯金目標',
      'create_goal': '目標作成',
      'no_savings_goals': '貯金目標はまだありません',
      'net_income': '純収入',
      'total_spent': '総支出',
      'total_earned': '総収入',
      'details': '詳細',
      'trend': 'トレンド',
      'income_sources': '収入源',
      'personal_account': '個人アカウント',
      'personal_info': '個人情報',
      'upgrade_account': 'アカウントのアップグレード',
      'upgrade_account_subtitle': 'PROにアップグレードしてすべての機能を解放',
      'ledger_settings': '帳簿設定',
      'ledger_book': '家計簿',
      'categories_manager': '収支カテゴリー',
      'export_files': 'CSV, XLSX出力',
      'app_settings': 'アプリ設定',
      'language': '言語',
      'balance_toggle': '残高表示',
      'daily_reminder': '毎日のリマインダー',
      'about': 'アプリについて',
      'rate_app': 'Mouseyを評価',
      'contact_support': 'サポートへ連絡',
      'version': 'バージョン',
      'logout': 'ログアウト',
      'logout_subtitle': 'このデバイスからログアウト',
      'cancel': 'キャンセル',
      'save_changes': '変更を保存',
      'all_time': '全期間',
      'this_month': '今月',
      'last_month': '先月',
      'last_3_months': '直近3ヶ月',
      'this_year': '今年',
      'filter': 'フィルター',
      'filter_categories': 'カテゴリーで絞り込み',
      'all_categories': 'すべてのカテゴリー',
      'no_report_data': 'レポートデータがありません',
      'add_transaction_for_analysis': '新しい取引を追加してカテゴリー分析を表示します',
      'no_income_data': '収入源がまだありません',
      'add_income_for_analysis': '新しい収入取引を追加して収入分析を表示します',
      'avg_per_month': '平均 / 月',
      'recent_months': '直近{n}か月',
      'saved_amount': '貯金済み',
      'no_balance_data': '残高データがまだありません。今日から貯金を始めましょう！',
      'no_financial_period_data': '財務期間データがありません',
      'mousey_savings_badge': 'MOUSEY SAVINGS · MOUSEY',
      'mousey_friend': 'Mousey, あなたのフレンドリーな予算の友達',
      'mousey_quote_home': '「塵も積もれば山となる！Mouseyと一緒に貯金目標を設定して夢を叶えましょう！」',
      'mousey_quote_no_expense': '「支出データはまだありません。Mouseyと一緒に最初の取引を記録しましょう！」',
      'mousey_quote_no_income': '「収入データはまだありません。最初の収入を記録しましょう！」',
      'full_name': '氏名',
      'email_or_phone': 'メール / 電話番号',
      'choose_avatar': 'アバターを選択',
      'upload_from_device': '端末から画像をアップロード',
      'income_expense_categories': '収支カテゴリー',
      'ledger_settings_title': '帳簿設定',
      'in_use': '使用中',
      'add_new_ledger': '新しい帳簿を追加 (PRO)',
      'export_report_title': 'レポート出力 (Pro)',
      'export_report_subtitle': 'エクスポートするファイル形式を選択してください：',
      'export_csv_title': 'CSV出力 (.csv)',
      'export_csv_sub': 'Googleスプレッドシートやデータシステムに最適',
      'export_excel_title': 'Excel出力 (.xlsx)',
      'export_excel_sub': 'Microsoft Excelの完全なフォーマットと数式',
      'rate_message': 'Mouseyをご利用いただきありがとうございます！ストアで5つ星の評価をお願いします ⭐⭐⭐⭐⭐',
      'support_message': 'Mouseyカスタマーサポート：\n• メール: support@mousey.com\n• ホットライン: 1900-MOUSEY\n• 営業時間: 8:00 - 20:00 (月〜土)',
      'export_csv_success': 'Mousey_Report.csv をダウンロードフォルダーに正常に出力しました！',
      'export_excel_success': 'Mousey_Report.xlsx をダウンロードフォルダーに正常に出力しました！',
      'balance_subtitle': '取引後に残高を表示する',
      'reminder_subtitle': 'Mouseyからの毎日のリマインダー',
      'categories_count_subtitle': 'デフォルト23カテゴリ',
      'notifications': '通知',
      'notification_center': '通知センター',
      'mark_all_read': 'すべて既読',
      'pending_confirmation': '確認待ち',
      'today': '今日',
      'today_section': '今日',
      'earlier': '以前',
      'earlier_section': '以前',
      'no_notifications': '通知はまだありません',
      'no_notifications_subtitle': '残高の変動や予算アラートが発生すると、Mouseyはここに通知を表示します。',
      'clear_all': 'すべて消去',
      'just_now': 'たった今',
      'minutes_ago': '分前',
      'hours_ago': '時間前',
      'days_ago': '日前',
      'pending_drafts_count': '件の下書き',
      'enter_note_title': '取引メモの入力',
      'note_hint': 'この取引のメモはありますか？...',
      'recent_suggestions': '最近の候補',
      'clear': 'クリア',
      'save': '保存',
      'budget_overview': '予算',
      'auto_finance_banking': '自動家計 & 銀行',
      'approve_bank_tx_sub': '自動読み取り銀行取引の承認',
      'bank_notification_settings': '銀行通知設定',
      'bank_list_subtitle': 'Vietcombank, MB, Techcombank, MoMo,...',
      'cloud_sync_section': 'クラウドデータ同期',
      'sync_status_title': '同期ステータス',
      'sync_now': '今すぐ同期',
      'account_security_section': 'アカウント & セキュリティ',
      'delete_all_data': 'すべてのデータを削除',
      'delete_all_data_sub': '取引、口座、カスタムカテゴリーを削除',
      'upgrade_pro_title': 'Mousey PROにアップグレード 👑',
      'upgrade_pro_desc': '無制限の帳簿のロック解除、Excelエクスポート...',
      'upgrade': 'アップグレード',
      'no_recent_transactions': '最近の取引はありません',
      'total_savings': '総貯蓄額',
      'add_savings_goal': '貯金目標を追加',
      'goal_name': '目標名',
      'target_amount': '目標金額',
      'initial_amount': '初期金額',
      'deadline_optional': '期限 (任意)',
      'choose_icon': 'アイコンを選択:',
      'create_goal_btn': '目標作成',
      'edit_savings_goal': '貯金目標を編集',
      'pro_upgrade_title': 'Mousey PROにアップグレード',
      'pro_upgrade_subtitle': 'スマートな財務管理の全パワーを体験',
      'pro_benefits': 'PRO限定特典',
      'benefit_1_title': '無制限の帳簿を追加',
      'benefit_1_sub': '個人、家族、仕事の資金を個別に管理',
      'benefit_2_title': 'Excel (.xlsx) & CSVレポート出力',
      'benefit_2_sub': '詳細データの保存と分析が簡単',
      'benefit_3_title': 'スマート通知リマインダー',
      'benefit_3_sub': '銀行残高通知時に自動リマインド',
      'benefit_4_title': '安全なクラウドバックアップ & 同期',
      'benefit_4_sub': 'デバイス間でのリアルタイムデータ同期',
      'choose_plan': '適切なプランを選択',
      'yearly_plan': '年間プラン (おすすめ)',
      'best_value': '最得',
      'yearly_saving': '17% OFF (~16,600ドン/月)',
      'monthly_plan': '月間プラン',
      'start_trial_btn': '7日間無料トライアルを開始',
      'subscribe_now': '今すぐ登録',
      'add_ledger_btn': '新しい帳簿を追加',
      'last_sync_label': '最終同期',
      'synced_status': '同期済み',
      'not_synced_status': '未同期',
      'never': 'なし',
      'welcome_back': 'おかえりなさい',
      'sync_status_label': '状態',
      'budget_alerts_toggle': '予算アラート',
      'budget_alerts_subtitle': '支出が上限を超えたときにお知らせします',
      'sync_state_synced': '同期済み',
      'sync_state_syncing': '同期中...',
      'sync_state_error': '同期エラー',
    },
    'zh': {
      'home': '首页',
      'savings': '储蓄',
      'budgets': '预算',
      'reports': '报表',
      'profile': '个人中心',
      'total_balance': '总余额',
      'income': '收入',
      'expense': '支出',
      'recent_transactions': '近期交易',
      'view_all': '查看全部',
      'no_transactions': '本月暂无交易记录',
      'add_first_transaction': '点击上方的收入/支出或下方的(+)添加第一笔交易吧！',
      'add_transaction': '添加新交易',
      'add_expense': '记录支出',
      'add_income': '记录收入',
      'transaction_title': '备注 / 交易名称',
      'amount': '金额',
      'category': '分类',
      'save_transaction': '保存交易',
      'savings_management': '储蓄管理',
      'savings_goals': '储蓄目标',
      'create_goal': '创建目标',
      'no_savings_goals': '暂无储蓄目标',
      'net_income': '净收入',
      'total_spent': '总支出',
      'total_earned': '总收入',
      'details': '明细',
      'trend': '趋势',
      'income_sources': '收入来源',
      'personal_account': '个人账户',
      'personal_info': '个人信息',
      'upgrade_account': '升级账户',
      'upgrade_account_subtitle': '升级到 PRO 解锁所有功能',
      'ledger_settings': '账本设置',
      'ledger_book': '账本',
      'categories_manager': '收支分类',
      'export_files': '导出 CSV, XLSX',
      'app_settings': '应用设置',
      'language': '语言',
      'balance_toggle': '余额显示',
      'daily_reminder': '每日提醒',
      'about': '关于',
      'rate_app': '评价 Mousey',
      'contact_support': '联系客服',
      'version': '版本',
      'logout': '退出登录',
      'logout_subtitle': '从本设备退出登录',
      'cancel': '取消',
      'save_changes': '保存修改',
      'all_time': '全时间',
      'this_month': '本月',
      'last_month': '上月',
      'last_3_months': '近3个月',
      'this_year': '今年',
      'filter': '筛选',
      'filter_categories': '按分类筛选',
      'all_categories': '所有分类',
      'no_report_data': '暂无报表数据',
      'add_transaction_for_analysis': '添加新交易查看分类分析',
      'no_income_data': '暂无收入来源',
      'add_income_for_analysis': '添加新收入交易查看收入分析',
      'avg_per_month': '月均',
      'recent_months': '近{n}个月',
      'saved_amount': '已储蓄',
      'no_balance_data': '暂无余额数据。从今天开始积累财富吧！',
      'no_financial_period_data': '暂无财务周期数据',
      'mousey_savings_badge': 'MOUSEY SAVINGS · MOUSEY',
      'mousey_friend': 'Mousey，您亲切的预算伙伴',
      'mousey_quote_home': '“积少成多！创建储蓄目标，让Mousey助你实现梦想！”',
      'mousey_quote_no_expense': '“暂无支出数据。记录第一笔交易，让Mousey帮您管理财务吧！”',
      'mousey_quote_no_income': '“暂无收入数据。记录第一笔收入，让Mousey帮您管理财务吧！”',
      'full_name': '姓名',
      'email_or_phone': '邮箱 / 手机号',
      'choose_avatar': '选择头像',
      'upload_from_device': '从设备/相册上传',
      'income_expense_categories': '收支分类',
      'ledger_settings_title': '账本设置',
      'in_use': '使用中',
      'add_new_ledger': '添加新账本 (PRO)',
      'export_report_title': '导出报表 (Pro)',
      'export_report_subtitle': '请选择要导出的文件格式：',
      'export_csv_title': '导出 CSV (.csv)',
      'export_csv_sub': '适合 Google 表格和数据系统',
      'export_excel_title': '导出 Excel (.xlsx)',
      'export_excel_sub': '包含完整的 Microsoft Excel 格式和公式',
      'rate_message': '感谢您使用 Mousey！请在应用商店留下5星好评 ⭐⭐⭐⭐⭐',
      'support_message': 'Mousey 客户支持：\n• 邮箱: support@mousey.com\n• 热线: 1900-MOUSEY\n• 工作时间: 8:00 - 20:00 (周一至周六)',
      'export_csv_success': '成功将 Mousey_Report.csv 导出到下载文件夹！',
      'export_excel_success': '成功将 Mousey_Report.xlsx 导出到下载文件夹！',
      'balance_subtitle': '交易后显示余额',
      'reminder_subtitle': '来自 Mousey 的每日提醒',
      'categories_count_subtitle': '23个默认分类',
      'notifications': '通知',
      'notification_center': '通知中心',
      'mark_all_read': '全部已读',
      'pending_confirmation': '待确认',
      'today': '今天',
      'today_section': '今天',
      'earlier': '更早',
      'earlier_section': '更早',
      'no_notifications': '暂无通知',
      'no_notifications_subtitle': '当余额变动或预算提醒发生时，Mousey 会在此显示通知。',
      'clear_all': '清除全部',
      'just_now': '刚刚',
      'minutes_ago': '分钟前',
      'hours_ago': '小时前',
      'days_ago': '天前',
      'pending_drafts_count': '个草稿',
      'enter_note_title': '输入交易备注',
      'note_hint': '此交易有什么备注？...',
      'recent_suggestions': '最近建议',
      'clear': '清空',
      'save': '保存',
      'budget_overview': '预算',
      'auto_finance_banking': '自动财务与银行',
      'approve_bank_tx_sub': '批准自动读取的银行交易',
      'bank_notification_settings': '银行通知设置',
      'bank_list_subtitle': 'Vietcombank, MB, Techcombank, MoMo,...',
      'cloud_sync_section': '云数据同步',
      'sync_status_title': '同步状态',
      'sync_now': '立即同步',
      'account_security_section': '账户与安全',
      'delete_all_data': '删除所有数据',
      'delete_all_data_sub': '删除交易、账户和自定义分类',
      'upgrade_pro_title': '升级到 Mousey PRO 👑',
      'upgrade_pro_desc': '解锁无限账本，导出Excel...',
      'upgrade': '升级',
      'no_recent_transactions': '近期无交易',
      'total_savings': '总储蓄',
      'add_savings_goal': '添加储蓄目标',
      'goal_name': '目标名称',
      'target_amount': '目标金额',
      'initial_amount': '初始金额',
      'deadline_optional': '截止日期 (可选)',
      'choose_icon': '选择图标:',
      'create_goal_btn': '创建目标',
      'edit_savings_goal': '编辑储蓄目标',
      'pro_upgrade_title': '升级到 Mousey PRO',
      'pro_upgrade_subtitle': '体验智能财务管理的全部功能',
      'pro_benefits': 'PRO 专属权益',
      'benefit_1_title': '添加无限账本',
      'benefit_1_sub': '分别管理个人、家庭和工作资金',
      'benefit_2_title': '导出 Excel (.xlsx) & CSV 报表',
      'benefit_2_sub': '轻松存储和深度分析数据',
      'benefit_3_title': '智能提醒',
      'benefit_3_sub': '银行余额通知时自动提醒',
      'benefit_4_title': '安全云备份与同步',
      'benefit_4_sub': '设备间实时数据同步',
      'choose_plan': '选择合适方案',
      'yearly_plan': '年付方案 (推荐)',
      'best_value': '最划算',
      'yearly_saving': '省 17% (~16,600盾/月)',
      'monthly_plan': '月付方案',
      'start_trial_btn': '开始 7 天免费试用',
      'subscribe_now': '立即订阅',
      'add_ledger_btn': '添加新账本',
      'last_sync_label': '最后同步',
      'synced_status': '已同步',
      'not_synced_status': '未同步',
      'never': '从未',
      'welcome_back': '欢迎回来',
      'sync_status_label': '状态',
      'budget_alerts_toggle': '预算提醒',
      'budget_alerts_subtitle': '支出超出限额时友好提醒',
      'sync_state_synced': '已同步',
      'sync_state_syncing': '正在同步...',
      'sync_state_error': '同步错误',
    },
    'ko': {
      'home': '홈',
      'savings': '저축',
      'budgets': '예산',
      'reports': '보고서',
      'profile': '마이페이지',
      'total_balance': '총 잔액',
      'income': '수입',
      'expense': '지출',
      'recent_transactions': '최근 거래 내역',
      'view_all': '전체 보기',
      'no_transactions': '이번 달 거래 내역이 없습니다',
      'add_first_transaction': '상단의 수입/지출 또는 하단의 (+) 버튼을 눌러 첫 거래를 등록하세요!',
      'add_transaction': '새 거래 추가',
      'add_expense': '지출 입력',
      'add_income': '수입 입력',
      'transaction_title': '메모 / 거래명',
      'amount': '금액',
      'category': '카테고리',
      'save_transaction': '거래 저장',
      'savings_management': '저축 관리',
      'savings_goals': '저축 목표',
      'create_goal': '목표 생성',
      'no_savings_goals': '아직 저축 목표가 없습니다',
      'net_income': '순수입',
      'total_spent': '총 지출',
      'total_earned': '총 수입',
      'details': '상세 내역',
      'trend': '트렌드',
      'income_sources': '수입원',
      'personal_account': '개인 계정',
      'personal_info': '개인 정보',
      'upgrade_account': '계정 업그레이드',
      'upgrade_account_subtitle': 'PRO로 업그레이드하여 모든 기능 해제',
      'ledger_settings': '가계부 설정',
      'ledger_book': '가계부',
      'categories_manager': '수입 및 지출 카테고리',
      'export_files': 'CSV, XLSX 파일 내보내기',
      'app_settings': 'APP SETTINGS',
      'language': '언어',
      'balance_toggle': '잔액 표시',
      'daily_reminder': '매일 알림',
      'about': '앱 정보',
      'rate_app': 'Mousey 평가하기',
      'contact_support': '고객 지원 문의',
      'version': '버전',
      'logout': '로그아웃',
      'logout_subtitle': '이 기기에서 로그아웃',
      'cancel': '취소',
      'save_changes': '변경 사항 저장',
      'all_time': '전체 기간',
      'this_month': '이번 달',
      'last_month': '지난달',
      'last_3_months': '최근 3개월',
      'this_year': '올해',
      'filter': '필터',
      'filter_categories': '카테고리별 필터',
      'all_categories': '모든 카테고리',
      'no_report_data': '보고서 데이터 없음',
      'add_transaction_for_analysis': '새 거래를 추가하여 카테고리 분석을 확인하세요!',
      'no_income_data': '수입원이 아직 없습니다',
      'add_income_for_analysis': '새 수입 거래를 추가하여 수입 분석을 확인하세요!',
      'avg_per_month': '월 평균',
      'recent_months': '최근 {n}개월',
      'saved_amount': '저축됨',
      'no_balance_data': '잔액 데이터가 없습니다. 오늘부터 저축을 시작해 보세요!',
      'no_financial_period_data': '재정 기간 데이터가 없습니다',
      'mousey_savings_badge': 'MOUSEY SAVINGS · MOUSEY',
      'mousey_friend': 'Mousey, 당신의 친근한 예산 친구',
      'mousey_quote_home': '"티끌 모아 태산! 저축 목표를 세우고 Mousey와 함께 꿈을 이뤄보세요!"',
      'mousey_quote_no_expense': '"지출 데이터가 없습니다. 첫 거래를 기록하여 Mousey가 재정을 추적하도록 도와주세요!"',
      'mousey_quote_no_income': '"수입 데이터가 없습니다. 첫 수입을 기록해 보세요!"',
      'full_name': '성명',
      'email_or_phone': '이메일 / 전화번호',
      'choose_avatar': '아바타 선택',
      'upload_from_device': '기기/갤러리에서 업로드',
      'income_expense_categories': '수입 및 지출 카테고리',
      'ledger_settings_title': '가계부 설정',
      'in_use': '사용 중',
      'add_new_ledger': '새 가계부 추가 (PRO)',
      'export_report_title': '보고서 내보내기 (Pro)',
      'export_report_subtitle': '내보낼 파일 형식을 선택하세요:',
      'export_csv_title': 'CSV 내보내기 (.csv)',
      'export_csv_sub': 'Google 스프레드시트 및 데이터 시스템에 적합',
      'export_excel_title': 'Excel 내보내기 (.xlsx)',
      'export_excel_sub': 'Microsoft Excel 서식 및 수식 포함',
      'rate_message': 'Mousey를 이용해 주셔서 감사합니다! 앱스토어에 5점 만점 평가를 남겨주세요 ⭐⭐⭐⭐⭐',
      'support_message': 'Mousey 고객 지원:\n• 이메일: support@mousey.com\n• Hotline: 1900-MOUSEY\n• 운영 시간: 08:00 - 20:00 (월~토)',
      'export_csv_success': 'Mousey_Report.csv를 다운로드 폴더에 성공적으로 내보냈습니다!',
      'export_excel_success': 'Mousey_Report.xlsx를 다운로드 폴더에 성공적으로 내보냈습니다!',
      'balance_subtitle': '거래 후 잔액 표시',
      'reminder_subtitle': 'Mousey의 매일 알림',
      'categories_count_subtitle': '기본 23개 카테고리',
      'notifications': '알림',
      'notification_center': '알림 센터',
      'mark_all_read': '모두 읽음',
      'pending_confirmation': '확인 대기',
      'today': '오늘',
      'today_section': '오늘',
      'earlier': '이전',
      'earlier_section': '이전',
      'no_notifications': '알림이 없습니다',
      'no_notifications_subtitle': '잔액 변동이나 예산 알림이 발생하면 Mousey가 여기에 알림을 표시합니다.',
      'clear_all': '모두 삭제',
      'just_now': '방금 전',
      'minutes_ago': '분 전',
      'hours_ago': '시간 전',
      'days_ago': '일 전',
      'pending_drafts_count': '개의 임시저장',
      'enter_note_title': '거래 메모 입력',
      'note_hint': '이 거래에 대한 메모가 있나요?...',
      'recent_suggestions': '최근 추천',
      'clear': '지우기',
      'save': '저장',
      'budget_overview': '예산',
      'auto_finance_banking': '자동 가계부 및 은행',
      'approve_bank_tx_sub': '자동 읽기 은행 거래 승인',
      'bank_notification_settings': '은행 알림 설정',
      'bank_list_subtitle': 'Vietcombank, MB, Techcombank, MoMo,...',
      'cloud_sync_section': '클라우드 데이터 동기화',
      'sync_status_title': '동기화 상태',
      'sync_now': '지금 동기화',
      'account_security_section': '계정 및 보안',
      'delete_all_data': '모든 데이터 삭제',
      'delete_all_data_sub': '거래, 계정 및 사용자 정의 카테고리 삭제',
      'upgrade_pro_title': 'Mousey PRO로 업그레이드 👑',
      'upgrade_pro_desc': '무제한 장부 잠금 해제, Excel 내보내기...',
      'upgrade': '업그레이드',
      'no_recent_transactions': '최근 거래 없음',
      'total_savings': '총 저축액',
      'add_savings_goal': '저축 목표 추가',
      'goal_name': '목표 이름',
      'target_amount': '목표 금액',
      'initial_amount': '초기 금액',
      'deadline_optional': '마감일 (선택 사항)',
      'choose_icon': '아이콘 선택:',
      'create_goal_btn': '목표 생성',
      'edit_savings_goal': '저축 목표 편집',
      'pro_upgrade_title': 'Mousey PRO 업그레이드',
      'pro_upgrade_subtitle': '스마트한 자산 관리의 모든 기능을 경험하세요',
      'pro_benefits': 'PRO 전용 혜택',
      'benefit_1_title': '무제한 장부 추가',
      'benefit_1_sub': '개인, 가족, 업무 자금을 분리하여 관리',
      'benefit_2_title': 'Excel (.xlsx) & CSV 보고서 내보내기',
      'benefit_2_sub': '심층 데이터 저장 및 분석 용이',
      'benefit_3_title': '스마트 알림',
      'benefit_3_sub': '은행 잔액 알림 시 자동 알림',
      'benefit_4_title': '안전한 클라우드 백업 및 동기화',
      'benefit_4_sub': '기기 간 실시간 데이터 동기화',
      'choose_plan': '적합한 플랜 선택',
      'yearly_plan': '연간 플랜 (추천)',
      'best_value': '최고 가치',
      'yearly_saving': '17% 절약 (~16,600동/월)',
      'monthly_plan': '월간 플랜',
      'start_trial_btn': '7일 무료 체험 시작',
      'subscribe_now': '지금 구독',
      'add_ledger_btn': '새 장부 추가',
      'last_sync_label': '마지막 동기화',
      'synced_status': '동기화됨',
      'not_synced_status': '동기화 안 됨',
      'never': '없음',
      'welcome_back': '다시 오신 것을 환영합니다',
      'sync_status_label': '상태',
      'budget_alerts_toggle': '예산 알림',
      'budget_alerts_subtitle': '지출이 한도를 넘으면 알려드려요',
      'sync_state_synced': '동기화됨',
      'sync_state_syncing': '동기화 중...',
      'sync_state_error': '동기화 오류',
    },
  };

  static const Map<String, Map<String, String>> _categories = {
    'en': {
      'Ăn uống': 'Food & Drinks',
      'Hóa đơn': 'Bills',
      'Di chuyển': 'Transport',
      'Mua sắm': 'Shopping',
      'Giải trí': 'Entertainment',
      'Sức khoẻ': 'Health',
      'Làm đẹp': 'Beauty',
      'Quần áo': 'Clothing',
      'Học tập': 'Education',
      'Thú cưng': 'Pets',
      'Con cái': 'Children',
      'Hỗ trợ gia đình': 'Family support',
      'Bảo hiểm': 'Insurance',
      'Thuế': 'Taxes',
      'Công việc': 'Work',
      'Nhà ở': 'Housing',
      'Tiền nợ': 'Debt',
      'Khác': 'Other',
      'Lương': 'Salary',
      'Thưởng': 'Bonus',
      'Bán hàng': 'Sales',
      'Đầu tư': 'Investment',
      'Chuyển tiền': 'Transfer',
      'Tiết kiệm': 'Savings',
      'Tất cả': 'All',
    },
    'ja': {
      'Ăn uống': '飲食',
      'Hóa đơn': '請求書',
      'Di chuyển': '交通',
      'Mua sắm': 'ショッピング',
      'Giải trí': '娯楽',
      'Sức khoẻ': '健康',
      'Làm đẹp': '美容',
      'Quần áo': '衣服',
      'Học tập': '学習',
      'Thú cưng': 'ペット',
      'Con cái': '子ども',
      'Hỗ trợ gia đình': '家族支援',
      'Bảo hiểm': '保険',
      'Thuế': '税金',
      'Công việc': '仕事',
      'Nhà ở': '住居',
      'Tiền nợ': '借金',
      'Khác': 'その他',
      'Lương': '給料',
      'Thưởng': 'ボーナス',
      'Bán hàng': '販売',
      'Đầu tư': '投資',
      'Chuyển tiền': '送金',
      'Tiết kiệm': '貯金',
      'Tất cả': 'すべて',
    },
    'zh': {
      'Ăn uống': '餐饮',
      'Hóa đơn': '账单',
      'Di chuyển': '交通',
      'Mua sắm': '购物',
      'Giải trí': '娱乐',
      'Sức khoẻ': '健康',
      'Làm đẹp': '美容',
      'Quần áo': '服装',
      'Học tập': '学习',
      'Thú cưng': '宠物',
      'Con cái': '子女',
      'Hỗ trợ gia đình': '家庭支持',
      'Bảo hiểm': '保险',
      'Thuế': '税费',
      'Công việc': '工作',
      'Nhà ở': '住房',
      'Tiền nợ': '债务',
      'Khác': '其他',
      'Lương': '工资',
      'Thưởng': '奖金',
      'Bán hàng': '销售',
      'Đầu tư': '投资',
      'Chuyển tiền': '转账',
      'Tiết kiệm': '储蓄',
      'Tất cả': '全部',
    },
    'ko': {
      'Ăn uống': '식비',
      'Hóa đơn': '공과금',
      'Di chuyển': '교통',
      'Mua sắm': '쇼핑',
      'Giải trí': '여가',
      'Sức khoẻ': '건강',
      'Làm đẹp': '미용',
      'Quần áo': '의류',
      'Học tập': '교육',
      'Thú cưng': '반려동물',
      'Con cái': '자녀',
      'Hỗ trợ gia đình': '가족 지원',
      'Bảo hiểm': '보험',
      'Thuế': '세금',
      'Công việc': '업무',
      'Nhà ở': '주거',
      'Tiền nợ': '부채',
      'Khác': '기타',
      'Lương': '급여',
      'Thưởng': '보너스',
      'Bán hàng': '판매',
      'Đầu tư': '투자',
      'Chuyển tiền': '이체',
      'Tiết kiệm': '저축',
      'Tất cả': '전체',
    },
  };

  static String tr(String langCode, String key) {
    final code = _mapLanguageToCode(langCode);
    return _keys[code]?[key] ?? _keys['vi']![key] ?? text(langCode, key);
  }

  /// Danh mục được lưu bằng tên tiếng Việt; danh mục người dùng tự tạo giữ nguyên tên.
  static String trCategory(String langCode, String category) {
    final code = _mapLanguageToCode(langCode);
    return _categories[code]?[category] ??
        _categories[code]?[_categoryAliases[category]] ??
        category;
  }

  static const Map<String, String> _categoryAliases = {
    'Tiền Nợ': 'Tiền nợ',
    'Sức khỏe': 'Sức khoẻ',
  };

  /// Dịch câu tiếng Việt [viText] (bảng ở app_texts.dart). Không có bản dịch thì giữ tiếng Việt.
  /// Tham số dạng `{name}` được thay bằng giá trị trong [params].
  static String text(String langCode, String viText, [Map<String, Object?>? params]) {
    final code = _mapLanguageToCode(langCode);
    var result = viText;
    if (code != 'vi') {
      final row = appTexts[viText];
      final index = const ['en', 'ja', 'zh', 'ko'].indexOf(code);
      if (row != null && index >= 0 && index < row.length) result = row[index];
    }
    params?.forEach((key, value) {
      result = result.replaceAll('{$key}', '$value');
    });
    return result;
  }

  static String languageCode(String lang) => _mapLanguageToCode(lang);

  static String formatDate(String langCode, DateTime date) {
    final code = _mapLanguageToCode(langCode);
    if (code == 'en') {
      return '${date.month}/${date.day}/${date.year}';
    } else if (code == 'ja') {
      return '${date.year}年${date.month}月${date.day}日';
    } else if (code == 'zh') {
      return '${date.year}年${date.month}月${date.day}日';
    } else if (code == 'ko') {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    } else if (date.year == DateTime.now().year) {
      return 'Ngày ${date.day} tháng ${date.month}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatMonthYear(String langCode, DateTime date) {
    final code = _mapLanguageToCode(langCode);
    if (code == 'en') {
      return '${_getMonthNameEn(date.month)} ${date.year}';
    } else if (code == 'ja') {
      return '${date.year}年${date.month}月';
    } else if (code == 'zh') {
      return '${date.year}年${date.month}月';
    } else if (code == 'ko') {
      return '${date.year}년 ${date.month}월';
    }
    return 'Tháng ${date.month}/${date.year}';
  }

  /// Tên tháng ngắn cho nhãn trục biểu đồ (T10, Oct, 10月, 10월).
  static String formatMonthShort(String langCode, DateTime date) {
    final code = _mapLanguageToCode(langCode);
    if (code == 'en') {
      return _getMonthNameEn(date.month).substring(0, 3);
    } else if (code == 'ja' || code == 'zh') {
      return '${date.month}月';
    } else if (code == 'ko') {
      return '${date.month}월';
    }
    return 'T${date.month}';
  }

  static String _getMonthNameEn(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Sổ mặc định được lưu với tên 'Sổ cá nhân 1'; sổ người dùng tự đặt tên giữ nguyên.
  static String trLedger(String langCode, String ledger) {
    if (ledger == 'Sổ cá nhân 1' || ledger == 'default_ledger') {
      return text(langCode, 'Sổ cá nhân 1');
    }
    return ledger;
  }

  static String formatBudgetAlertMessage(String langCode, String type, Map<String, dynamic> params, String dedupeKey) {
    final code = _mapLanguageToCode(langCode);
    final categoryKey = params['categoryKey'] ?? 'total';
    final isTotal = categoryKey == 'total';
    final categoryName = isTotal
        ? (code == 'en' ? 'Total monthly spending' : (code == 'ja' ? '今月の総支出' : (code == 'zh' ? '本月总支出' : (code == 'ko' ? '이번 달 총 지출' : 'Tổng chi tháng này'))))
        : trCategory(langCode, categoryKey);

    final percent = params['percent'] ?? 80;
    final remaining = formatMoney(params['remaining'] ?? 0);
    final over = formatMoney(params['over'] ?? 0);
    final daysLeft = params['daysLeft'] ?? 1;
    final perDay = formatMoney(params['perDay'] ?? 0);

    final hash = dedupeKey.hashCode.abs();
    final variant = hash % 2;

    if (type == 'budget_warning') {
      if (code == 'en') {
        return variant == 0
            ? '$categoryName has used $percent% of its limit. You have $remaining left for $daysLeft days, about $perDay per day.'
            : 'Heads up! $categoryName has reached $percent% of your monthly budget.';
      } else if (code == 'ja') {
        return variant == 0
            ? '$categoryNameの予算の$percent%を使用しました。あと$daysLeft日分で$remaining円残っています（1日約$perDay円）。'
            : 'ご注意ください、$categoryNameは今月の予算の$percent%に達しました。';
      } else if (code == 'zh') {
        return variant == 0
            ? '$categoryName 已使用了 $percent% 的额度。还剩 $remaining 持续 $daysLeft 天，每天约 $perDay。'
            : '注意啦，$categoryName 已达到本月预算的 $percent%。';
      } else if (code == 'ko') {
        return variant == 0
            ? '$categoryName 예산의 $percent%를 사용하셨습니다. $daysLeft일 동안 $remaining원 남았습니다 (하루 약 $perDay원).'
            : '참고하세요, $categoryName이(가) 이번 달 예산의 $percent%에 도달했습니다.';
      } else {
        return variant == 0
            ? '$categoryName đã dùng $percent% hạn mức rồi nè. Còn $remaining cho $daysLeft ngày, khoảng $perDay mỗi ngày.'
            : 'Cẩn thận nha, $categoryName đã cán mốc $percent% ngân sách tháng rồi đó.';
      }
    } else if (type == 'budget_reached') {
      if (code == 'en') {
        return variant == 0
            ? '$categoryName has reached its limit for this month. Let\'s slow down a bit!'
            : 'Your $categoryName budget is fully used. Time to be mindful!';
      } else if (code == 'ja') {
        return variant == 0
            ? '$categoryNameは今月の予算上限に達しました。少しペースを落とししょう！'
            : '$categoryNameの予算を使い切りました。少し気をつけましょう。';
      } else if (code == 'zh') {
        return variant == 0
            ? '$categoryName 已达到本月限额。让我们稍微放慢脚步吧！'
            : '$categoryName 预算已用完，请注意控制开支哦！';
      } else if (code == 'ko') {
        return variant == 0
            ? '$categoryName 이번 달 예산 한도에 도달했습니다. 조금만 속도를 줄여볼까요?'
            : '$categoryName 예산이 모두 소진되었습니다. 주의해 주세요!';
      } else {
        return variant == 0
            ? '$categoryName đã chạm hạn mức tháng này rồi. Mình cùng chậm lại một chút nhé!'
            : 'Hạn mức $categoryName tháng này đã đầy rồi nè, giữ ví chặt nha!';
      }
    } else if (type == 'budget_exceeded') {
      if (code == 'en') {
        return variant == 0
            ? '$categoryName has exceeded its budget by $over. No worries, review your expenses or adjust the limit as needed.'
            : 'Oops! $categoryName is over budget by $over. Let\'s adjust our spending or budget limit next time.';
      } else if (code == 'ja') {
        return variant == 0
            ? '$categoryNameの予算を$overオーバーしました。支出を見直すか、予算を調整してみてください。'
            : 'おっと、$categoryNameが予算を$over超過しました。次は調整しましょう。';
      } else if (code == 'zh') {
        return variant == 0
            ? '$categoryName 超支了 $over。没关系，检查一下支出或适当调整预算吧。'
            : '哎呀，$categoryName 超预算 $over 了。下次注意调整哦！';
      } else if (code == 'ko') {
        return variant == 0
            ? '$categoryName 예산이 $over 초과되었습니다. 지출을 검토하거나 필요시 예산을 조정해보세요.'
            : '이런, $categoryName 예산이 $over 초과되었습니다. 다음에는 조금 더 신경 써봐요!';
      } else {
        return variant == 0
            ? '$categoryName đã vượt hạn mức $over rồi. Không sao đâu, xem lại các khoản chi hoặc điều chỉnh hạn mức cho phù hợp nhé.'
            : 'Ơ kìa, $categoryName đã vượt ngân sách $over mất tiêu rồi. Lần sau mình căn chỉnh lại nghen!';
      }
    }
    return jsonEncode(params);
  }

  static String formatBudgetAlertTitle(String langCode, String type, Map<String, dynamic> params) {
    final code = _mapLanguageToCode(langCode);
    final categoryKey = params['categoryKey'] ?? 'total';
    final isTotal = categoryKey == 'total';
    final percent = params['percent'] ?? 80;

    if (code == 'en') {
      final name = isTotal ? 'Total budget' : trCategory(langCode, categoryKey);
      if (type == 'budget_exceeded') return '$name is over budget ($percent%)';
      if (type == 'budget_reached') return '$name reached its limit ($percent%)';
      return '$name at $percent% of budget';
    } else if (code == 'ja') {
      final name = isTotal ? '総予算' : trCategory(langCode, categoryKey);
      if (type == 'budget_exceeded') return '$nameが予算超過（$percent%）';
      if (type == 'budget_reached') return '$nameが上限に到達（$percent%）';
      return '$nameが予算の$percent%に到達';
    } else if (code == 'zh') {
      final name = isTotal ? '总预算' : trCategory(langCode, categoryKey);
      if (type == 'budget_exceeded') return '$name 已超支（$percent%）';
      if (type == 'budget_reached') return '$name 已达上限（$percent%）';
      return '$name 已用 $percent% 预算';
    } else if (code == 'ko') {
      final name = isTotal ? '총 예산' : trCategory(langCode, categoryKey);
      if (type == 'budget_exceeded') return '$name 예산 초과 ($percent%)';
      if (type == 'budget_reached') return '$name 한도 도달 ($percent%)';
      return '$name 예산 $percent% 사용';
    }
    final name = isTotal ? 'Ngân sách tổng' : trCategory(langCode, categoryKey);
    if (type == 'budget_exceeded') return '$name đã vượt hạn mức ($percent%)';
    if (type == 'budget_reached') return '$name đã chạm hạn mức ($percent%)';
    return '$name đã dùng $percent% ngân sách';
  }

  static String _mapLanguageToCode(String lang) {
    if (lang.contains('English')) return 'en';
    if (lang.contains('日本語') || lang.contains('Nhật')) return 'ja';
    if (lang.contains('中文') || lang.contains('Trung')) return 'zh';
    if (lang.contains('한국어') || lang.contains('Hàn')) return 'ko';
    return 'vi';
  }
}

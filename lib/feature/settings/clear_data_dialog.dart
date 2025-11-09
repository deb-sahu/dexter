import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:password_vault/constants/common_exports.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';

class ClearAllDataNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void update(bool value) => state = value;
}

final clearAllDataNotifierProvider = NotifierProvider<ClearAllDataNotifier, bool>(
  ClearAllDataNotifier.new,
);

class ClearDataDialog extends ConsumerWidget {
  const ClearDataDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isPortrait = AppStyles.isPortraitMode(context);

    return AlertDialog(
      backgroundColor: ThemeChangeService().getThemeChangeValue() ? AppColor.grey_800 : AppColor.grey_200,
      surfaceTintColor: ThemeChangeService().getThemeChangeValue() ? AppColor.grey_400 : AppColor.grey_100,
      title: Text(
        'Clear All Data',
        style: AppStyles.primaryBoldText(context, isPortrait),
      ),
      content: Text(
        'Are you sure you want to clear all data? This action cannot be undone.',
        style: AppStyles.customText(context, color: ThemeChangeService().getThemeChangeValue() ? AppColor.whiteColor : AppColor.blackColor),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: AppStyles.customText(
              context,
              color: AppColor.whiteColor,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            bool success = await CacheService().clearAllData();
            if (success) {
              ref.read(clearAllDataNotifierProvider.notifier).update(true);
              // Data cleared successfully
              if (context.mounted) {
                AppStyles.showSuccess(context, 'Data cleared successfully');
              }
            } else {
              // Failed to clear data
              if (context.mounted) {
                AppStyles.showError(context, 'Failed to clear data');
              }
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(
            'Clear All',
            style: AppStyles.customText(
              context,
              color: AppColor.whiteColor,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:password_vault/constants/common_exports.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';

class DeleteConfirmationDialog extends ConsumerWidget {
  final String passwordId;
  final VoidCallback onDelete;

  const DeleteConfirmationDialog({
    required this.passwordId,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isPortrait = AppStyles.isPortraitMode(context);

    return AlertDialog(
      backgroundColor: ThemeChangeService().getThemeChangeValue() ? AppColor.grey_800 : AppColor.grey_200,
      surfaceTintColor: ThemeChangeService().getThemeChangeValue() ? AppColor.grey_400 : AppColor.grey_100,
      title: Text('Delete Password', style: AppStyles.primaryBoldText(context, isPortrait)),
      content: Text('Are you sure you want to delete this password?',
          style: AppStyles.customText(context, color: ThemeChangeService().getThemeChangeValue() ? AppColor.whiteColor : AppColor.blackColor)),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel',
              style: AppStyles.customText(
                context,
                color: AppColor.whiteColor,
                weight: FontWeight.bold,
              )),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            onDelete(); // Proceed with deleting the password
          },
          child: Text(
            'Delete',
            style: AppStyles.customText(
              context,
              color: AppColor.whiteColor,
              weight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

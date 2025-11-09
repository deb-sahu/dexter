import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:password_vault/app_container.dart';
import 'package:password_vault/cache/hive_models/folder_model.dart';
import 'package:password_vault/constants/common_exports.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';
import 'package:uuid/uuid.dart';

class AddFolderDialog extends ConsumerStatefulWidget {
   final FolderModel? folderModel; // For future extension if you want to edit a folder
   final Function onSuccess; // Callback function

  const AddFolderDialog({super.key, this.folderModel, required this.onSuccess});

  @override
  // ignore: library_private_types_in_public_api
  _AddFolderDialogState createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends ConsumerState<AddFolderDialog> {
  late TextEditingController folderNameController;
  late String _folderId;
  late bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    folderNameController = TextEditingController();
    if (widget.folderModel != null) {
      _isEditMode = true;
      folderNameController.text = widget.folderModel!.folderName;
    }
    _folderId = widget.folderModel?.folderId ?? '';
  }

  @override
  void dispose() {
    folderNameController.dispose();
    super.dispose();
  }

  void _saveFolder(BuildContext context) async {
    if (folderNameController.text.isEmpty) {
      AppStyles.showError(context, 'Please enter a folder name.');
      return;
    }

    try {
      var folderId = _folderId;
      FolderModel folderModel;

      // Check if folder id exists
      var folderExists = await CacheService().checkFolderIdExists(folderId);
      
      // Create or update folder id
      folderModel = FolderModel(
        folderId: folderExists ? folderId : const Uuid().v4(),
        folderName: folderNameController.text,
        createdAt: folderExists ? widget.folderModel?.createdAt ?? DateTime.now() : DateTime.now(),
        passwordIds: folderExists ? widget.folderModel?.passwordIds ?? [] : [],
      );

      // Save the FolderModel instance using Hive
      bool success = await CacheService().addEditFolder(folderModel);
      if (context.mounted) {
        if (success) {
          AppStyles.showSuccess(context, folderExists ? 'Folder updated successfully.' : 'Folder added successfully.');
          widget.onSuccess(); // Callback function
         // ref.read(updateFolderProvider.notifier).update((state) => true); // Update provider
          Navigator.pop(context);
        } else {
          AppStyles.showError(context, 'Failed to add folder. Please try again.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppStyles.showError(context, 'An error occurred. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = AppStyles.viewHeight(context);
    var width = AppStyles.viewWidth(context);
    var themeChange = ref.watch(themeChangeProvider);
    ThemeChangeService().initializeThemeChange(ref, themeChange);

    return SizedBox(
      height: height * 0.78, // Consistent height across all bottom sheets
      child: Padding(
        padding: EdgeInsets.all(width * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: ThemeChangeService().getThemeChangeValue()
                      ? AppStyles.onlyTextButtonDark
                      : AppStyles.onlyTextButtonLight,
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppStyles.customText(context,
                        color: AppColor.primaryColor, 
                        sizeFactor: 0.04,
                        weight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  style: ThemeChangeService().getThemeChangeValue()
                      ? AppStyles.onlyTextButtonDark
                      : AppStyles.onlyTextButtonLight,
                  onPressed: () async => _saveFolder(context),
                  child: _isEditMode
                      ? Text(
                          'Update',
                          style: AppStyles.customText(context,
                              color: AppColor.primaryColor,
                              sizeFactor: 0.04,
                              weight: FontWeight.bold),
                        )
                      : Text(
                          'Create',
                          style: AppStyles.customText(context,
                              color: AppColor.primaryColor,
                              sizeFactor: 0.04,
                              weight: FontWeight.bold),
                        ),
                ),
              ],
            ),
            SizedBox(height: height * 0.03),
            TextField(
              controller: folderNameController,
              style: AppStyles.customText(context,
                  sizeFactor: 0.035,
                  color: ThemeChangeService().getThemeChangeValue()
                      ? AppColor.whiteColor
                      : AppColor.blackColor),
              decoration: InputDecoration(
                labelText: 'Folder Name*',
                hintText: 'Enter folder name',
                hintStyle: AppStyles.customText(context,
                    sizeFactor: 0.035,
                    color: ThemeChangeService().getThemeChangeValue()
                        ? AppColor.whiteColor
                        : AppColor.darkGrey),
                labelStyle: AppStyles.customText(context,
                    sizeFactor: 0.035,
                    color: ThemeChangeService().getThemeChangeValue()
                        ? AppColor.whiteColor
                        : AppColor.blackColor),
              ),
            ),
            SizedBox(height: height * 0.045),
            Center(
              child: Text(
                'Note: Folders are stored securely in your device.',
                style: AppStyles.customText(
                  context,
                  sizeFactor: 0.03,
                  color: AppColor.primaryColor,
                ),
              ),
            ),
            SizedBox(height: height * 0.035),
            Center(
              child: Icon(
                size: width * 0.09,
                Icons.folder,
                color: AppColor.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

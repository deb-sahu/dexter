import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:password_vault/app_container.dart';
import 'package:password_vault/cache/hive_models/folder_model.dart';
import 'package:password_vault/cache/hive_models/passwords_model.dart';
import 'package:password_vault/constants/common_exports.dart';
import 'package:password_vault/feature/passwords/password_generation_algorithm.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';
import 'package:uuid/uuid.dart';

class UpdatePasswordNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void update(bool value) => state = value;
}

final updatePasswordProvider = NotifierProvider<UpdatePasswordNotifier, bool>(
  UpdatePasswordNotifier.new,
);

class AddPasswordDialog extends ConsumerStatefulWidget {
  final PasswordModel? passwordModel;
  final FolderModel? folderModel;
  final Function onSuccess; // Callback function

  const AddPasswordDialog(
      {super.key, this.passwordModel, this.folderModel, required this.onSuccess});

  @override
  // ignore: library_private_types_in_public_api
  _AddPasswordDialogState createState() => _AddPasswordDialogState();
}

class _AddPasswordDialogState extends ConsumerState<AddPasswordDialog> {
  late TextEditingController _titleController;
  late TextEditingController _linkController;
  late TextEditingController _passwordController;
  late TextEditingController _descriptionController;
  late String _passwordId;
  late bool _isObscured = true;
  late bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.passwordModel?.passwordTitle ?? '');
    _linkController = TextEditingController(text: widget.passwordModel?.siteLink ?? '');
    _passwordController = TextEditingController(text: widget.passwordModel?.savedPassword ?? '');
    _descriptionController =
        TextEditingController(text: widget.passwordModel?.passwordDescription ?? '');
    _passwordId = widget.passwordModel?.passwordId ?? '';
    _isEditMode = widget.passwordModel != null;

    // Check password strength on initialization if there's already a password
    if (_passwordController.text.isNotEmpty) {
      _checkPasswordStrength(_passwordController.text);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  void _savePassword(BuildContext context) async {
    // Validate fields
    if (_titleController.text.isEmpty || _passwordController.text.isEmpty) {
      AppStyles.showError(context, 'Please fill all the required fields.');
      return;
    }

    try {
      final passwordExists = await CacheService().checkPasswordIdExists(_passwordId);
      final newPasswordId = const Uuid().v4();
      final passwordId =
          passwordExists ? _passwordId : newPasswordId; // Correctly assign passwordId

      // Create or update PasswordModel instance
      final passwordModel = PasswordModel(
        passwordId: passwordId,
        passwordTitle: _titleController.text,
        siteLink: _linkController.text,
        savedPassword: _passwordController.text,
        passwordDescription: _descriptionController.text,
        createdAt:
            passwordExists ? widget.passwordModel?.createdAt ?? DateTime.now() : DateTime.now(),
        modifiedAt: DateTime.now(),
        folderId: passwordExists
            ? widget.passwordModel?.folderId ?? ''
            : widget.folderModel?.folderId ?? '',
      );

      // Log password history
      await CacheService().logPasswordHistory(passwordModel, passwordExists ? 'updated' : 'added');

      // Add passwordId to folder if new password and folder exists
      if (!passwordExists && widget.folderModel != null) {
        final folder = widget.folderModel!;
        folder.passwordIds.add(newPasswordId);
        await CacheService().addEditFolder(folder);
      }

      // Save the PasswordModel instance using Hive
      final success = await CacheService().addEditPassword(passwordModel);

      // Handle UI interaction only if the context is still mounted
      if (context.mounted) {
        if (success) {
          AppStyles.showSuccess(context,
              passwordExists ? 'Password updated successfully.' : 'Password added successfully.');
          widget.onSuccess(); // Callback function
          ref.read(updatePasswordProvider.notifier).update(true);
          Navigator.pop(context);
        } else {
          AppStyles.showError(context, 'Failed to add password. Please try again.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppStyles.showError(context, 'An error occurred. Please try again.');
      }
    }
  }

  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;

  void _checkPasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength++;

    setState(() {
      if (strength < 3) {
        _passwordStrengthText = 'Very Weak';
        _passwordStrengthColor = Colors.red;
      } else if (strength == 3) {
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.orange;
      } else if (strength == 4) {
        _passwordStrengthText = 'Medium';
        _passwordStrengthColor = Colors.amber;
      } else if (strength == 5) {
        _passwordStrengthText = 'Strong';
        _passwordStrengthColor = Colors.lightGreen;
      } else {
        _passwordStrengthText = 'Very Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = AppStyles.viewHeight(context);
    var width = AppStyles.viewWidth(context);
    var themeChange = ref.watch(themeChangeProvider);
    ThemeChangeService().initializeThemeChange(ref, themeChange);

    return SizedBox(
      height: height * 0.78,
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
                  onPressed: () async => _savePassword(context),
                  child: _isEditMode
                      ? Text(
                          'Update',
                          style: AppStyles.customText(context,
                              color: AppColor.primaryColor,
                              sizeFactor: 0.04,
                              weight: FontWeight.bold),
                        )
                      : Text(
                          'Save',
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
              style: AppStyles.customText(context,
                  sizeFactor: 0.035,
                  color: ThemeChangeService().getThemeChangeValue()
                      ? AppColor.whiteColor
                      : AppColor.blackColor),
              controller: _titleController,
              spellCheckConfiguration:
                  SpellCheckConfiguration(spellCheckService: DefaultSpellCheckService()),
              decoration: InputDecoration(
                  labelText: 'Title*',
                  hintText: 'Enter title e.g. Facebook, Google, etc.',
                  hintStyle: AppStyles.customText(context,
                      sizeFactor: 0.035,
                      color: ThemeChangeService().getThemeChangeValue()
                          ? AppColor.whiteColor
                          : AppColor.darkGrey),
                  labelStyle: AppStyles.customText(context,
                      sizeFactor: 0.035,
                      color: ThemeChangeService().getThemeChangeValue()
                          ? AppColor.whiteColor
                          : AppColor.blackColor)),
            ),
            SizedBox(height: height * 0.02),
            TextField(
              style: AppStyles.customText(context,
                  sizeFactor: 0.035,
                  color: ThemeChangeService().getThemeChangeValue()
                      ? AppColor.whiteColor
                      : AppColor.blackColor),
              spellCheckConfiguration:
                  SpellCheckConfiguration(spellCheckService: DefaultSpellCheckService()),
              controller: _linkController,
              decoration: InputDecoration(
                labelText: 'Website',
                hintText: 'Enter website link e.g. www.example.com',
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
            SizedBox(height: height * 0.02),
            TextField(
              style: AppStyles.customText(context,
                  sizeFactor: 0.035,
                  color: ThemeChangeService().getThemeChangeValue()
                      ? AppColor.whiteColor
                      : AppColor.blackColor),
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password*',
                hintText: 'Enter password',
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
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _togglePasswordVisibility,
                      icon: _isObscured
                          ? const Icon(Icons.visibility)
                          : const Icon(Icons.visibility_off),
                    ),
                    IconButton(
                      onPressed: () {
                        String newPassword = generateStrongPassword();
                        _passwordController.text = newPassword;
                        _checkPasswordStrength(newPassword);
                      },
                      tooltip: 'Generate strong password',
                      icon: const Icon(Icons.auto_mode_rounded), // Auto-generate icon
                    ),
                  ],
                ),
              ),
              obscureText: _isObscured,
              onChanged: (password) {
                _checkPasswordStrength(password);
              },
            ),
            SizedBox(height: height * 0.01),
            Text(
              'Select the right icon to autofill with a suggested strong password.',
              style: AppStyles.customText(context,
                  sizeFactor: 0.025,
                  color: ThemeChangeService().getThemeChangeValue()
                      ? AppColor.whiteColor
                      : AppColor.blackColor),
            ),
            SizedBox(height: height * 0.01),
            Text(
              'Password Strength: $_passwordStrengthText',
              style: AppStyles.customText(context,
                  sizeFactor: 0.028, color: _passwordStrengthColor, weight: FontWeight.bold),
            ),
            SizedBox(height: height * 0.02),
            TextField(
              style: AppStyles.customText(context,
                  sizeFactor: 0.035,
                  color: ThemeChangeService().getThemeChangeValue()
                      ? AppColor.whiteColor
                      : AppColor.blackColor),
              spellCheckConfiguration:
                  SpellCheckConfiguration(spellCheckService: DefaultSpellCheckService()),
              controller: _descriptionController,
              decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter description',
                  hintStyle: AppStyles.customText(context,
                      sizeFactor: 0.035,
                      color: ThemeChangeService().getThemeChangeValue()
                          ? AppColor.whiteColor
                          : AppColor.darkGrey),
                  labelStyle: AppStyles.customText(context,
                      sizeFactor: 0.035,
                      color: ThemeChangeService().getThemeChangeValue()
                          ? AppColor.whiteColor
                          : AppColor.blackColor)),
            ),
            SizedBox(height: height * 0.045),
            Center(
              child: Text(
                'Note: Passwords are stored securely in your device.',
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
                Icons.lock,
                color: AppColor.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

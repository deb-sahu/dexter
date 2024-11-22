import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:password_vault/app_container.dart';
import 'package:password_vault/cache/hive_models/folder_model.dart';
import 'package:password_vault/feature/passwords/add_folder_dialog.dart';
import 'package:password_vault/feature/passwords/add_password_dialog.dart';
import 'package:password_vault/cache/hive_models/passwords_model.dart';
import 'package:password_vault/feature/passwords/delete_confirmation_dialog.dart';
import 'package:password_vault/feature/settings/clear_data_dialog.dart';
import 'package:password_vault/feature/settings/settings.dart';
import 'package:password_vault/feature/widget_utils/custom_empty_state_illustartion.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/common_exports.dart';

final deletePasswordNotifierProvider = StateProvider<bool>((ref) {
  return false;
});

class Passwords extends ConsumerStatefulWidget {
  const Passwords({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PasswordsState createState() => _PasswordsState();
}

class _PasswordsState extends ConsumerState<Passwords> {
  late TextEditingController _passwordController;
  late TextEditingController _titleController;
  late TextEditingController _linkController;
  late TextEditingController _descriptionController;
  late bool _isObscured = true;
  late List<PasswordModel> _passwords = [];
  List<FolderModel> _folders = []; // Each folder can have a list of passwords
  final Map<String, bool> _folderExpansionState = {}; // Track the expansion state per folder
  bool isOrganizeMode = false; // New variable to track organize mode

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _titleController = TextEditingController();
    _linkController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadPasswords();
    _loadFolders();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _titleController.dispose();
    _linkController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    try {
      _folders =
          await CacheService().getFoldersData(); // Assuming _folders is a list to hold folder data
      ref.read(clearAllDataNotifierProvider.notifier).update((state) => false);
      ref.read(importChangeProvider.notifier).update((state) => false);
    } catch (e) {
      _folders = []; // In case of error, return an empty list
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPasswords() async {
    try {
      _passwords = await CacheService().getPasswordsData();
      ref.read(clearAllDataNotifierProvider.notifier).update((state) => false);
      ref.read(importChangeProvider.notifier).update((state) => false);
    } catch (e) {
      _passwords = [];
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<PasswordModel?> _getPasswordModelById(String passwordId) async {
    try {
      return await CacheService().getPasswordByPasswordId(passwordId);
    } catch (e) {
      return null;
    }
  }

  void _deletePassword(String passwordId) {
    CacheService().deletePasswordRecord(passwordId).then((success) {
      if (success) {
        setState(() {
          _passwords.removeWhere((password) => password.passwordId == passwordId);
          ref.read(deletePasswordNotifierProvider.notifier).update((state) => true);
        });
        AppStyles.showSuccess(context, 'Password deleted successfully');
      } else {
        AppStyles.showError(context, 'Error deleting password');
      }
    });
  }

  void _showDeleteConfirmation(String passwordId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(
          passwordId: passwordId,
          onDelete: () => _deletePassword(passwordId),
        );
      },
    );
  }

  void _editPassword(PasswordModel password) {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AddPasswordDialog(
          passwordModel: password,
          onSuccess: _reloadPasswords,
        );
      },
    );
  }

  void _reloadPasswords() {
    _loadPasswords();
  }

  void _reloadFolders() {
    _loadFolders();
  }

  void _reloadAllData() {
    _loadPasswords();
    _loadFolders();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  bool _copyToClipboard(String password) {
    try {
      Clipboard.setData(ClipboardData(text: password));
      return true;
    } catch (e) {
      return false;
    }
  }

  void _openWebPage(String url) async {
    String formattedUrl = url.startsWith('http') ? url : 'https://$url';
    var uri = Uri.parse(formattedUrl); // Convert string to Uri
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode: LaunchMode.inAppWebView,
          webViewConfiguration: const WebViewConfiguration(enableJavaScript: true));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = AppStyles.viewHeight(context);
    var width = AppStyles.viewWidth(context);
    bool isPortrait = AppStyles.isPortraitMode(context);

    if (ref.watch(clearAllDataNotifierProvider) || ref.watch(importChangeProvider)) {
      _loadPasswords();
      _loadFolders();
    }

    var themeChange = ref.watch(themeChangeProvider);
    ThemeChangeService().initializeThemeChange(ref, themeChange);

    // Filter passwords to show only those not inside folders
    var passwordsOutsideFolders = _passwords
        .where((password) => password.folderId == null || password.folderId == "")
        .toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppStyles.appBarHeight(context),
        automaticallyImplyLeading: false,
        title: Text(
          'Passwords',
          style: AppStyles.appHeaderTextStyle(context, isPortrait),
        ),
        actions: [
          IconButton(
            tooltip: 'Organize',
            icon: Icon(
              isOrganizeMode ? Icons.space_dashboard_rounded : Icons.space_dashboard_outlined,
              color: AppColor.primaryColor,
              size: AppStyles.appIconSize(context),
            ),
            onPressed: () {
              setState(() {
                isOrganizeMode = !isOrganizeMode;
              });
            },
          ),
        ],
      ),
      floatingActionButton: isOrganizeMode
          ? null
          : SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: AppColor.appColor,
              children: [
                SpeedDialChild(
                  child: const Icon(CupertinoIcons.padlock),
                  label: 'Add Password',
                  onTap: () {
                    showModalBottomSheet(
                      isDismissible: false,
                      context: context,
                      useSafeArea: true,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return AddPasswordDialog(
                          onSuccess: _reloadPasswords,
                        );
                      },
                    );
                  },
                ),
                SpeedDialChild(
                  child: const Icon(CupertinoIcons.folder),
                  label: 'Add Folder',
                  onTap: () {
                    showModalBottomSheet(
                      isDismissible: false,
                      context: context,
                      useSafeArea: true,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return AddFolderDialog(
                          onSuccess: _reloadFolders,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
      body: SafeArea(
        minimum: EdgeInsets.all(width * 0.02),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: height * 0.015),
            Expanded(
              child: _folders.isEmpty && passwordsOutsideFolders.isEmpty
                  ? const EmptyStateIllustration(
                      svgAsset: 'assets/images/svg/illustration3.svg',
                      text: 'Uh oh! No folders or passwords saved yet',
                    )
                  : Column(
                      children: [
                        // Parent-level DragTarget to drop passwords out of folders
                        if (isOrganizeMode && _folders.isNotEmpty) ...{
                          DragTarget<PasswordModel>(
                            builder: (context, candidateItems, rejectedItems) {
                              return Container(
                                width: double.infinity,
                                height:
                                    height * 0.08, // Area for dropping passwords outside folders
                                color: candidateItems.isNotEmpty
                                    ? Colors.grey[300] // Highlight when dragging over
                                    : Colors.transparent,
                                child: Center(
                                  child: Text(
                                    'Drop here to move out of folder',
                                    style: AppStyles.customText(
                                      context,
                                      sizeFactor: 0.03,
                                      color: ThemeChangeService().getThemeChangeValue()
                                          ? AppColor.whiteColor
                                          : AppColor.grey_600,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                            onAcceptWithDetails: (details) async {
                              PasswordModel password = details.data;

                              // Move password out of folder
                              if (password.folderId != null) {
                                // Remove from previous folder
                                var oldFolder =
                                    _folders.firstWhere((f) => f.folderId == password.folderId);
                                if (oldFolder.passwordIds.contains(password.passwordId)) {
                                  oldFolder.passwordIds.remove(password.passwordId);
                                  await CacheService().updateFolderRecord(oldFolder);
                                }

                                // Update password to have no folder
                                password.folderId = null;
                                await CacheService().updatePasswordRecord(password);

                                // Reload passwords and folders
                                setState(() {
                                  _loadPasswords();
                                  _loadFolders();
                                });
                              }
                            },
                            onWillAcceptWithDetails: (details) =>
                                true, // Allow accepting the dragged item
                          ),
                        },
                        // Main ListView for folders and passwords outside folders
                        Expanded(
                          child: ListView.builder(
                            itemCount:
                                _folders.length + passwordsOutsideFolders.length, // Combined count
                            itemBuilder: (context, index) {
                              if (index < _folders.length) {
                                // Render Folder
                                var folder = _folders[index];
                                bool isExpanded = _folderExpansionState[folder.folderId] ?? false;

                                return DragTarget<PasswordModel>(
                                  builder: (context, candidateItems, rejectedItems) {
                                    return Card(
                                      child: ExpansionTile(
                                        maintainState: true,
                                        onExpansionChanged: (expanded) {
                                          setState(() {
                                            _folderExpansionState[folder.folderId] = expanded;
                                          });
                                        },
                                        shape: BeveledRectangleBorder(
                                          borderRadius: BorderRadius.circular(5.0),
                                        ),
                                        leading: Icon(
                                          CupertinoIcons.folder_solid,
                                          size: width * 0.05,
                                        ),
                                        title: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            GestureDetector(
                                              onDoubleTap: () {
                                                // Open the rename folder modal
                                                showModalBottomSheet(
                                                  isDismissible: false,
                                                  context: context,
                                                  useSafeArea: true,
                                                  isScrollControlled: true,
                                                  builder: (BuildContext context) {
                                                    return AddFolderDialog(
                                                      folderModel: folder,
                                                      onSuccess: _reloadFolders,
                                                    );
                                                  },
                                                );
                                              },
                                              child: Text(
                                                folder.folderName,
                                                style: AppStyles.customText(
                                                  context,
                                                  sizeFactor: 0.04,
                                                  color: ThemeChangeService().getThemeChangeValue()
                                                      ? AppColor.whiteColor
                                                      : AppColor.grey_800,
                                                  weight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            // Adding plus icons at folder level
                                            if (isExpanded && !isOrganizeMode) ...{
                                              IconButton(
                                                icon: Icon(Icons.add, size: width * 0.05),
                                                onPressed: () {
                                                  // Open the add password modal for this folder
                                                  showModalBottomSheet(
                                                    isDismissible: false,
                                                    context: context,
                                                    useSafeArea: true,
                                                    isScrollControlled: true,
                                                    builder: (BuildContext context) {
                                                      return AddPasswordDialog(
                                                        folderModel: folder, // Pass the folder
                                                        onSuccess: _reloadAllData,
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            },
                                          ],
                                        ),
                                        children: folder.passwordIds.map((passwordId) {
                                          return FutureBuilder<PasswordModel?>(
                                            future: _getPasswordModelById(passwordId),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Center(
                                                    child: CircularProgressIndicator());
                                              } else if (snapshot.hasError) {
                                                return const Center(
                                                    child: Text('Error loading password'));
                                              } else if (snapshot.hasData) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                      left: width * 0.05), // Indentation
                                                  child: _buildPasswordCard(snapshot.data!),
                                                );
                                              } else {
                                                return const SizedBox();
                                              }
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                  onAcceptWithDetails: (details) async {
                                    PasswordModel password = details.data;
                                    // Check if an outside password is moved to a folder
                                    if (password.folderId == null || password.folderId == '') {
                                      // Update the password to the folder
                                      password.folderId = folder.folderId;
                                      folder.passwordIds.add(password.passwordId);

                                      // Save the updated password and folder
                                      await CacheService().updatePasswordRecord(password);
                                      await CacheService().updateFolderRecord(folder);

                                      // Reload the passwords and folders
                                      setState(() {
                                        _loadPasswords();
                                        _loadFolders();
                                      });
                                    }

                                    // Check if the password is moved to a different folder
                                    if (password.folderId != folder.folderId &&
                                        password.folderId != null &&
                                        password.folderId != '') {
                                      if (password.folderId != null) {
                                        // Remove password from previous folder
                                        var oldFolder = _folders
                                            .firstWhere((f) => f.folderId == password.folderId);
                                        if (oldFolder.passwordIds.contains(password.passwordId)) {
                                          oldFolder.passwordIds.remove(password.passwordId);
                                          await CacheService().updateFolderRecord(oldFolder);
                                        }
                                      }

                                      // Update the password to the new folder
                                      password.folderId = folder.folderId;
                                      folder.passwordIds.add(password.passwordId);

                                      // Save the updated password and folder
                                      await CacheService().updatePasswordRecord(password);
                                      await CacheService().updateFolderRecord(folder);

                                      // Reload the passwords and folders
                                      setState(() {
                                        _loadPasswords();
                                        _loadFolders();
                                      });
                                    }
                                  },
                                  onWillAcceptWithDetails: (details) =>
                                      true, // Allow accepting the dragged item
                                );
                              } else {
                                // Render individual password (not in a folder)
                                var passwordIndex = index - _folders.length;
                                var password = passwordsOutsideFolders[passwordIndex];
                                return _buildPasswordCard(password); // Render password card
                              }
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(PasswordModel password) {
    var height = AppStyles.viewHeight(context);
    var width = AppStyles.viewWidth(context);

    return LongPressDraggable<PasswordModel>(
      data: password,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: width * 0.9, // Width of the draggable item
          padding: const EdgeInsets.all(16.0), // Increased padding for better visuals
          decoration: BoxDecoration(
            color: AppColor.primaryColor,
            borderRadius: BorderRadius.circular(8.0), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2), // Shadow effect
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.shield_lefthalf_fill,
                size: 24.0,
                color: AppColor.whiteColor,
              ),
              const SizedBox(width: 8.0), // Spacing between icon and text
              Expanded(
                child: Text(
                  password.passwordTitle,
                  style: AppStyles.customText(
                    context,
                    sizeFactor: 0.04,
                    color: AppColor.whiteColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(), // Optionally show something else while dragging
      child: Card(
        child: ExpansionTile(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
          leading: Icon(
            CupertinoIcons.shield_lefthalf_fill,
            size: width * 0.06,
          ),
          title: Text(
            password.passwordTitle,
            style: AppStyles.customText(
              context,
              sizeFactor: 0.04,
              color: ThemeChangeService().getThemeChangeValue()
                  ? AppColor.whiteColor
                  : AppColor.grey_800,
              weight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(width * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (password.siteLink != null && password.siteLink!.isNotEmpty) ...{
                    GestureDetector(
                        onTap: () => _openWebPage(password.siteLink ?? ''),
                        child: Row(
                          children: [
                            Text(
                              password.siteLink ?? '',
                              style: AppStyles.customText(
                                context,
                                sizeFactor: 0.038,
                                weight: FontWeight.w600,
                                color: ThemeChangeService().getThemeChangeValue()
                                    ? AppColor.primaryColor
                                    : AppColor.themeBlueMid, // Color to indicate it's a link
                              ),
                            ),
                            SizedBox(width: width * 0.02),
                            Icon(
                              Icons.open_in_new,
                              size: width * 0.04,
                              color: ThemeChangeService().getThemeChangeValue()
                                  ? AppColor.whiteColor
                                  : AppColor.themeBlueMid,
                            ),
                          ],
                        )),
                  } else ...{
                    const SizedBox(),
                  },
                  SizedBox(height: height * 0.02),
                  TextField(
                    style: AppStyles.customText(
                      context,
                      sizeFactor: 0.03,
                      color: ThemeChangeService().getThemeChangeValue()
                          ? AppColor.whiteColor
                          : AppColor.blackColor,
                    ),
                    controller: TextEditingController(text: password.savedPassword),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              bool res = _copyToClipboard(password.savedPassword);
                              if (res) {
                                AppStyles.showSuccess(
                                  context,
                                  'Password copied to clipboard',
                                );
                              } else {
                                AppStyles.showError(
                                  context,
                                  'Error copying password to clipboard',
                                );
                              }
                            },
                            icon: const Icon(Icons.copy),
                          ),
                          IconButton(
                            onPressed: _togglePasswordVisibility,
                            icon: _isObscured
                                ? const Icon(Icons.visibility)
                                : const Icon(Icons.visibility_off),
                          ),
                        ],
                      ),
                    ),
                    obscureText: _isObscured,
                    readOnly: true,
                  ),
                  SizedBox(height: height * 0.02),
                  TextField(
                    controller: TextEditingController(text: password.passwordDescription),
                    style: AppStyles.customText(
                      context,
                      sizeFactor: 0.03,
                      color: ThemeChangeService().getThemeChangeValue()
                          ? AppColor.whiteColor
                          : AppColor.blackColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: AppStyles.customText(
                        context,
                        sizeFactor: 0.03,
                        color: AppColor.grey_600,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: width * 0.051,
                        ),
                        onPressed: () => _showDeleteConfirmation(
                            password.passwordId), // Show confirmation before deleting
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: width * 0.05,
                        ),
                        onPressed: () => _editPassword(password),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
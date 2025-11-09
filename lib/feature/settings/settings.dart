import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:password_vault/app_container.dart';
import 'package:password_vault/constants/common_exports.dart';
import 'package:password_vault/feature/settings/clear_data_dialog.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class ImportChangeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void update(bool value) => state = value;
}

final importChangeProvider = NotifierProvider<ImportChangeNotifier, bool>(
  ImportChangeNotifier.new,
);

class Settings extends ConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var height = AppStyles.viewHeight(context);
    var width = AppStyles.viewWidth(context);
    bool isPortrait = AppStyles.isPortraitMode(context);
    final themeChange = ref.watch(themeChangeProvider);
    ThemeChangeService().initializeThemeChange(ref, themeChange);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppStyles.appBarHeight(context),
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: AppStyles.appHeaderTextStyle(context, isPortrait),
        ),
        actions: [
          IconButton(
            tooltip: 'Organize',
            icon: Icon(
              Icons.headset_mic_outlined,
              color: AppColor.primaryColor,
              size: AppStyles.appIconSize(context),
            ),
            onPressed: () async {
              // Direct to my website for support
              var uri = Uri.parse('https://www.theadarsh.dev');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  AppStyles.showError(context, 'Could not launch the url');
                }
              }
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
            SizedBox(height: height * 0.02),
            ListTile(
              tileColor: ThemeChangeService().getThemeChangeValue()
                  ? AppColor.grey_800
                  : AppColor.grey_200,
              title: Text(
                'Dark Mode',
                style: AppStyles.customText(context,
                    sizeFactor: 0.038,
                    color: ThemeChangeService().getThemeChangeValue()
                        ? AppColor.whiteColor
                        : AppColor.blackColor),
              ),
              trailing: Switch(
                value: ThemeChangeService().getThemeChangeValue(),
                onChanged: (value) async {
                  await CacheService().updateThemeMode(value);
                  ref.read(themeChangeProvider.notifier).update(value);
                },
              ),
            ),
            SizedBox(height: height * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: ThemeChangeService().getThemeChangeValue()
                      ? AppStyles.onlyTextButtonDark
                      : AppStyles.onlyTextButtonLight,
                  onPressed: () async {
                    var bool = await CacheService().exportAllData();
                    if (context.mounted) {
                      if (bool) {
                        AppStyles.showSuccess(context, 'Data exported successfully');
                        if (Platform.isAndroid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Check your downloads folder for the exported data file'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        } else if (Platform.isIOS) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Check your application directory for the exported data file'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      } else {
                        AppStyles.showError(context, 'Error in exporting data');
                      }
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        'Export Data',
                        style: AppStyles.customText(
                          context,
                          color: ThemeChangeService().getThemeChangeValue()
                              ? AppColor.whiteColor
                              : AppColor.blackColor,
                          sizeFactor: 0.038,
                        ),
                      ),
                      SizedBox(width: width * 0.6),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: ThemeChangeService().getThemeChangeValue()
                      ? AppStyles.onlyTextButtonDark
                      : AppStyles.onlyTextButtonLight,
                  onPressed: () async {
                    // Import data from file
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      String filePath = result.files.single.path!;
                      var bool = await CacheService().importDataFromFile(filePath);
                      if (context.mounted) {
                        if (bool) {
                          ref.read(importChangeProvider.notifier).update(true);
                          AppStyles.showSuccess(context, 'Data imported successfully');
                        } else {
                          AppStyles.showError(context, 'Error in importing data');
                        }
                      }
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        'Import Data',
                        style: AppStyles.customText(
                          context,
                          color: ThemeChangeService().getThemeChangeValue()
                              ? AppColor.whiteColor
                              : AppColor.blackColor,
                          sizeFactor: 0.038,
                        ),
                      ),
                      SizedBox(width: width * 0.6),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.03),
            SizedBox(
              width: double.infinity,
              height: height * 0.06,
              child: CupertinoButton(
                borderRadius: BorderRadius.circular(10),
                color: AppColor.appColor,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ClearDataDialog(),
                  );
                },
                child: Text(
                  'Clear All Data',
                  style: AppStyles.customText(
                    context,
                    color: AppColor.whiteColor,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

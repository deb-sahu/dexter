import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:password_vault/app_container.dart';
import 'package:password_vault/cache/hive_models/history_model.dart';
import 'package:password_vault/constants/common_exports.dart';
import 'package:password_vault/feature/passwords/add_password_dialog.dart';
import 'package:password_vault/feature/passwords/passwords.dart';
import 'package:password_vault/feature/settings/clear_data_dialog.dart';
import 'package:password_vault/feature/settings/settings.dart';
import 'package:password_vault/feature/widget_utils/custom_empty_state_illustartion.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';

final passwordHistoryProvider = FutureProvider<List<HistoryModel>>((ref) async {
  return await CacheService().getPasswordHistory();
});

class History extends ConsumerWidget {
  const History({super.key});

  void _loadHistory(WidgetRef ref) {
    //ref.refresh(passwordHistoryProvider);
    ref.invalidate(passwordHistoryProvider);
    ref.read(passwordHistoryProvider);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMMM yyyy, hh:mm:ss a').format(dateTime);
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var width = AppStyles.viewWidth(context);
    bool isPortrait = AppStyles.isPortraitMode(context);
    final themeChange = ref.watch(themeChangeProvider);

    if (ref.watch(deletePasswordNotifierProvider) ||
        ref.watch(clearAllDataNotifierProvider) ||
        ref.watch(importChangeProvider) ||
        ref.watch(updatePasswordProvider)) {
      _loadHistory(ref);
    }
    ThemeChangeService().initializeThemeChange(ref, themeChange);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppStyles.appBarHeight(context),
        automaticallyImplyLeading: false,
        title: Text(
          'History',
          style: AppStyles.appHeaderTextStyle(context, isPortrait),
        ),
      ),
      body: ref.watch(passwordHistoryProvider).when(
            data: (historyList) {
              if (historyList.isEmpty) {
                return const EmptyStateIllustration(
                  svgAsset: 'assets/images/svg/illustration5.svg',
                  text: 'No history available',
                );
              }

              return SafeArea(
                minimum: EdgeInsets.all(width * 0.02),
                child: ListView.builder(
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    var history = historyList[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ExpansionTile(
                        backgroundColor: ThemeChangeService().getThemeChangeValue()
                            ? AppColor.grey_800
                            : AppColor.whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        title: Text(
                          '${_capitalizeFirstLetter(history.action)} - ${history.passwordTitle}',
                          style: AppStyles.customText(
                            context,
                            sizeFactor: 0.036,
                            weight: FontWeight.w600,
                            color: ThemeChangeService().getThemeChangeValue()
                                ? AppColor.grey_500
                                : AppColor.grey_600,
                          ),
                        ),
                        subtitle: Text(
                          _formatDateTime(history.timestamp),
                          style: AppStyles.customText(
                            context,
                            sizeFactor: 0.031,
                            weight: FontWeight.w400,
                            color: ThemeChangeService().getThemeChangeValue()
                                ? AppColor.primaryColor
                                : AppColor.themeBlueMid,
                          ),
                        ),
                        children: [
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            title: Text(
                              'Password Details',
                              style: AppStyles.customText(
                                context,
                                sizeFactor: 0.0315,
                                weight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                color: ThemeChangeService().getThemeChangeValue()
                                    ? AppColor.whiteColor
                                    : AppColor.ultraDarkGrey,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Title: ${history.passwordTitle}',
                                    style: AppStyles.customText(context,
                                        sizeFactor: 0.031,
                                        color: ThemeChangeService().getThemeChangeValue()
                                            ? AppColor.whiteColor
                                            : AppColor.blackColor)),
                                Text('Site Link: ${history.siteLink}',
                                    style: AppStyles.customText(context,
                                        sizeFactor: 0.031,
                                        color: ThemeChangeService().getThemeChangeValue()
                                            ? AppColor.whiteColor
                                            : AppColor.blackColor)),
                                Text('Saved Password: ${history.savedPassword}',
                                    style: AppStyles.customText(context,
                                        sizeFactor: 0.031,
                                        color: ThemeChangeService().getThemeChangeValue()
                                            ? AppColor.whiteColor
                                            : AppColor.blackColor)),
                                Text('Description: ${history.passwordDescription}',
                                    style: AppStyles.customText(context,
                                        sizeFactor: 0.031,
                                        color: ThemeChangeService().getThemeChangeValue()
                                            ? AppColor.whiteColor
                                            : AppColor.blackColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(child: Text('Error loading history')),
          ),
    );
  }
}

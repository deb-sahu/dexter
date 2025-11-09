import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:password_vault/app_container.dart';
import 'package:password_vault/cache/hive_models/passwords_model.dart';
import 'package:password_vault/constants/common_exports.dart';
import 'package:password_vault/feature/home/favourites_dialog.dart';
import 'package:password_vault/feature/passwords/add_password_dialog.dart';
import 'package:password_vault/feature/passwords/passwords.dart';
import 'package:password_vault/feature/settings/clear_data_dialog.dart';
import 'package:password_vault/feature/settings/settings.dart';
import 'package:password_vault/feature/widget_utils/custom_empty_state_illustartion.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';

class Home extends ConsumerStatefulWidget {
  final List<PasswordModel>? favoritePasswords;
  const Home({super.key, this.favoritePasswords});

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  List<PasswordModel> favoritePasswords = [];
  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFavourites() async {
    try {
      await CacheService().updateFirstLogin(false); // Update first login to false after first login
      favoritePasswords = await CacheService().getFavouritesData();
      ref.read(deletePasswordNotifierProvider.notifier).update(false);
      ref.read(changeFavoritesdNotifierProvider.notifier).update(false);
      ref.read(clearAllDataNotifierProvider.notifier).update(false);
      ref.read(importChangeProvider.notifier).update(false);
      ref.read(updatePasswordProvider.notifier).update(false);
    } catch (e) {
      favoritePasswords = [];
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = AppStyles.viewHeight(context);
    var width = AppStyles.viewWidth(context);
    bool isPortrait = AppStyles.isPortraitMode(context);
    final themeChange = ref.watch(themeChangeProvider);
    if (ref.watch(deletePasswordNotifierProvider) ||
        ref.watch(changeFavoritesdNotifierProvider) ||
        ref.watch(clearAllDataNotifierProvider) ||
        ref.watch(importChangeProvider) || ref.watch(updatePasswordProvider)) {
      _loadFavourites();
    }
    ThemeChangeService().initializeThemeChange(ref, themeChange);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppStyles.appBarHeight(context),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                isDismissible: false,
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                builder: (context) => const FavoritesDialog(),
              );
            },
            icon: Icon(
              favoritePasswords.isNotEmpty
                  ? Icons.favorite_rounded
                  :
              Icons.favorite_outline_rounded,
              size: AppStyles.appIconSize(context),
              color: AppColor.primaryColor,
            ),
          )
        ],
        title: Text(
          'Home',
          style: AppStyles.appHeaderTextStyle(context, isPortrait),
        ),
      ),
      body: SafeArea(
        minimum: EdgeInsets.all(width * 0.02),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favoritePasswords.isNotEmpty) ...{
              SizedBox(height: height * 0.015),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Favorites',
                        style: AppStyles.customText(
                          context,
                          sizeFactor: 0.038,
                          weight: FontWeight.w600,
                          color: ThemeChangeService().getThemeChangeValue()
                              ? AppColor.whiteColor
                              : AppColor.blackColor,
                        ),
                      ),
                      SizedBox(
                        width: width * 0.02,
                      ),
                      SizedBox(
                        height: height * 0.025,
                        width: width * 0.055,
                        child: Badge.count(
                          count: favoritePasswords.length,
                          backgroundColor: ThemeChangeService().getThemeChangeValue()
                              ? AppColor.primaryColor
                              : AppColor.darkBlue,
                          textColor: AppColor.whiteColor,
                          textStyle: AppStyles.customText(
                            context,
                            sizeFactor: 0.025,
                            weight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              Text(
                'Tap on the cards to copy password',
                textAlign: TextAlign.start,
                style: AppStyles.customText(
                  context,
                  sizeFactor: 0.03,
                  weight: FontWeight.w500,
                  color: ThemeChangeService().getThemeChangeValue()
                      ? AppColor.primaryColor
                      : AppColor.blue_900,
                ),
              ),
              SizedBox(height: height * 0.015),
              SizedBox(
                width: width,
                height: isPortrait ? height * 0.5 : height * 0.2,
                child: ListView.builder(
                  itemCount: favoritePasswords.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: favoritePasswords[index].savedPassword));
                        AppStyles.showSuccess(context, 'Password copied to clipboard');
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: height * 0.01),
                        width: width * 0.5,
                        decoration: BoxDecoration(
                          color: ThemeChangeService().getThemeChangeValue()
                              ? AppColor.grey_800
                              : Colors.white, // Background color of the container
                          borderRadius: BorderRadius.circular(8.0),
                          backgroundBlendMode: BlendMode.srcOver,
                          boxShadow: [
                            BoxShadow(
                              color: ThemeChangeService().getThemeChangeValue()
                                  ? AppColor.blackColor
                                  : AppColor.midGrey.withOpacity(0.5), // Color of the shadow
                              spreadRadius: 0.5,
                              blurRadius: 1.5,
                              offset: Offset.fromDirection(2, 1),
                              blurStyle: BlurStyle.solid,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                favoritePasswords[index].passwordTitle,
                                style: AppStyles.customText(context,
                                    weight: FontWeight.bold,
                                    color: ThemeChangeService().getThemeChangeValue()
                                        ? AppColor.whiteColor
                                        : AppColor.blackColor),
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                                favoritePasswords[index].passwordDescription ?? '',
                                style: AppStyles.customText(context,
                                    color: ThemeChangeService().getThemeChangeValue()
                                        ? AppColor.whiteColor
                                        : AppColor.blackColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            },
            if (favoritePasswords.isEmpty) ...{
              const Expanded(
                child: Center(
                  child: EmptyStateIllustration(
                    svgAsset: 'assets/images/svg/illustration4.svg',
                    text: 'Add some favorites, eh?',
                  ),
                ),
              ),
            },
          ],
        ),
      ),
    );
  }
}

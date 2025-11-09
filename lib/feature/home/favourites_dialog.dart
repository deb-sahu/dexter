// ignore_for_file: use_build_context_synchronously
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:password_vault/cache/hive_models/passwords_model.dart';
import 'package:password_vault/constants/common_exports.dart';
import 'package:password_vault/feature/widget_utils/custom_empty_state_illustartion.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';

class ChangeFavoritesNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void update(bool value) => state = value;
}

final changeFavoritesdNotifierProvider = NotifierProvider<ChangeFavoritesNotifier, bool>(
  ChangeFavoritesNotifier.new,
);

class FavoritesDialog extends ConsumerStatefulWidget {
  const FavoritesDialog({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FavoritesDialogState createState() => _FavoritesDialogState();
}

class _FavoritesDialogState extends ConsumerState<FavoritesDialog> {
  List<PasswordModel> passwords = [];
  List<bool> isPasswordInFavorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPasswordsData();
  }

  void loadPasswordsData() async {
    try {
      List<PasswordModel> loadedPasswords = await CacheService().getPasswordsData();
      
      // Use Future.wait to load all favorites in parallel instead of sequentially
      List<bool> initialIsPasswordInFavorites = await Future.wait(
        loadedPasswords.map((password) async {
          return await CacheService().isPasswordInFavoritesByPasswordId(password.passwordId);
        }).toList(),
      );

      if (mounted) {
        setState(() {
          passwords = loadedPasswords;
          isPasswordInFavorites = initialIsPasswordInFavorites;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          passwords = [];
          isPasswordInFavorites = [];
          isLoading = false;
        });
      }
    }
  }

  void toggleFavorite(PasswordModel password, bool newValue) async {
    ref.read(changeFavoritesdNotifierProvider.notifier).update(true);
    if (newValue) {
      // Add password to favorites
      bool success = await CacheService().addPasswordsToFavourites(password);
      if (success) {
        // Password added to favorites successfully
        AppStyles.showSuccess(context, 'Password added to favorites');
      } else {
        // Failed to add password to favorites
        AppStyles.showError(context, 'Failed to add password to favorites');
      }
    } else {
      // Remove password from favorites
      bool success =
          await CacheService().removePasswordFromFavouritesByPasswordId(password.passwordId);
      if (success) {
        // Password removed from favorites successfully
        AppStyles.showSuccess(context, 'Password removed from favorites');
      } else {
        // Failed to remove password from favorites
        AppStyles.showError(context, 'Failed to remove password from favorites');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = AppStyles.viewHeight(context);
    var width = AppStyles.viewWidth(context);
    var isPortrait = AppStyles.isPortraitMode(context);

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
                Text(
                  'Manage Favorites',
                  style: AppStyles.primaryBoldText(context, isPortrait),
                ),
                TextButton(
                  style: ThemeChangeService().getThemeChangeValue()
                      ? AppStyles.onlyTextButtonDark
                      : AppStyles.onlyTextButtonLight,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Done',
                    style: AppStyles.customText(
                      context,
                      color: AppColor.primaryColor,
                      sizeFactor: 0.04,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.02),
            Text(
              'Select passwords to add to your home screen',
              style: AppStyles.customText(
                context,
                sizeFactor: 0.032,
                color: ThemeChangeService().getThemeChangeValue()
                    ? AppColor.grey_400
                    : AppColor.grey_600,
              ),
            ),
            SizedBox(height: height * 0.02),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColor.primaryColor,
                      ),
                    )
                  : passwords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const EmptyStateIllustration(
                                svgAsset: 'assets/images/svg/illustration1.svg',
                                text: 'Did you add any passwords?',
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: passwords.length,
                          itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(bottom: height * 0.01),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.012,
                                    horizontal: width * 0.04,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ThemeChangeService().getThemeChangeValue()
                                        ? AppColor.grey_600.withOpacity(0.5)
                                        : AppColor.whiteColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isPasswordInFavorites[index]
                                          ? AppColor.primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 20,
                                        color: ThemeChangeService().getThemeChangeValue()
                                            ? AppColor.grey_400
                                            : AppColor.grey_600,
                                      ),
                                      SizedBox(width: width * 0.03),
                                      Expanded(
                                        child: Text(
                                          passwords[index].passwordTitle,
                                          style: AppStyles.customText(
                                            context,
                                            sizeFactor: 0.038,
                                            color: ThemeChangeService().getThemeChangeValue()
                                                ? AppColor.whiteColor
                                                : AppColor.blackColor,
                                          ),
                                        ),
                                      ),
                                      Checkbox(
                                        checkColor: AppColor.whiteColor,
                                        activeColor: AppColor.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        value: isPasswordInFavorites[index],
                                        onChanged: (newValue) {
                                          setState(() {
                                            isPasswordInFavorites[index] = newValue!;
                                          });
                                          toggleFavorite(passwords[index], newValue!);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
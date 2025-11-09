import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:password_vault/app_container.dart';
import 'package:password_vault/constants/common_exports.dart';
import 'package:password_vault/feature/home/home.dart';
import 'package:password_vault/feature/passwords/passwords.dart';
import 'package:password_vault/feature/settings/settings.dart';
import 'package:password_vault/feature/history/history.dart';
import 'package:password_vault/feature/widget_utils/custom_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';

class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void update(int value) => state = value;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(
  BottomNavIndexNotifier.new,
);
class NavRoute extends ConsumerWidget {
 const NavRoute({super.key});
  
  static final List<Widget> _widgetOptions = <Widget>[
    const Home(),
    const Passwords(),
    const History(),
    const Settings()
    // Add your other page widgets here
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final themeChange = ref.watch(themeChangeProvider);
    ThemeChangeService().initializeThemeChange(ref, themeChange);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: CustomIcon(
            selectedIcon: CupertinoIcons.house_alt_fill,
            unselectedIcon: CupertinoIcons.house_alt,
            isSelected: currentIndex == 0,
          ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: CustomIcon(
            selectedIcon: CupertinoIcons.checkmark_shield_fill,
            unselectedIcon: CupertinoIcons.checkmark_shield,
            isSelected: currentIndex==1
            ),
            label: 'Passwords',
          ),
          BottomNavigationBarItem(
            icon: CustomIcon(
            selectedIcon: CupertinoIcons.timer_fill,
            unselectedIcon: CupertinoIcons.timer,
            isSelected: currentIndex==2
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: CustomIcon(
            selectedIcon: CupertinoIcons.gear_alt_fill,
            unselectedIcon: CupertinoIcons.gear_alt,
            isSelected: currentIndex==3
            ),
            label: 'Settings',
          ),
        ],
        currentIndex: currentIndex,
        selectedItemColor: AppColor.appColor,
        unselectedItemColor: ThemeChangeService().getThemeChangeValue() ? AppColor.whiteColor : AppColor.blackColor,
        showUnselectedLabels: true,
        showSelectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppStyles.bottomNavSelectedText(context), 
        unselectedLabelStyle: AppStyles.bottomNavUnselectedText(context), 
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).update(index);
        },
      ),
    );
  }
}

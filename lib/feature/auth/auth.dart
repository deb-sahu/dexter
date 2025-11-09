import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:password_vault/cache/hive_models/passwords_model.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';
import 'package:password_vault/theme/app_color.dart';
import 'package:password_vault/theme/app_style.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _isDeviceSupported = false;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _checkData();
    await _checkDeviceSupport();
  }

  Future<void> _checkDeviceSupport() async {
    bool isSupported = await auth.isDeviceSupported();
    if (isSupported) {
      await _checkBiometrics();
    } else {
      await _promptBiometricSetup();
    }
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _isDeviceSupported = canCheckBiometrics;
    });

    if (_isDeviceSupported) {
      await _authenticate();
    } else {
      _handleNoBiometricSupport();
    }
  }

  Future<void> _promptBiometricSetup() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        var isPortrait = AppStyles.isPortraitMode(context);
        return AlertDialog(
          backgroundColor: ThemeChangeService().getThemeChangeValue()
              ? AppColor.grey_800
              : AppColor.grey_200,
          surfaceTintColor: ThemeChangeService().getThemeChangeValue()
              ? AppColor.grey_400
              : AppColor.grey_100,
          title: Row(
            children: [
              Icon(
                Icons.security,
                color: AppColor.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Secure Your Passwords',
                    style: AppStyles.primaryBoldText(context, isPortrait)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Secure your passwords with biometric authentication for quick and safe access.',
                style: AppStyles.customText(context,
                    sizeFactor: 0.035,
                    color: ThemeChangeService().getThemeChangeValue()
                        ? AppColor.whiteColor
                        : AppColor.blackColor),
              ),
              const SizedBox(height: 12),
              Text(
                '• Unlock instantly\n• Enhanced security\n• Passcode backup available',
                style: AppStyles.customText(context,
                    sizeFactor: 0.032,
                    color: ThemeChangeService().getThemeChangeValue()
                        ? AppColor.grey_400
                        : AppColor.grey_600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColor.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recommended for password managers',
                        style: AppStyles.customText(context,
                            sizeFactor: 0.03,
                            color: AppColor.primaryColor,
                            weight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User chose to skip
              },
              child: Text('Use Passcode Only',
                  style: AppStyles.customText(
                    context,
                    color: ThemeChangeService().getThemeChangeValue()
                        ? AppColor.grey_400
                        : AppColor.grey_600,
                  )),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User chose to set up
              },
              child: Text('Set Up Now',
                  style: AppStyles.customText(
                    context,
                    color: AppColor.whiteColor,
                    weight: FontWeight.bold,
                  )),
            ),
          ],
        );
      },
    );

    // If user chose to set up biometrics
    if (result == true) {
      await _openBiometricSettings();
    } else {
      // User chose to skip - proceed with passcode only
      await _checkBiometrics(); // Will handle proceeding without biometrics
    }
  }

  Future<void> _openBiometricSettings() async {
    if (Platform.isAndroid) {
      // Show guidance snackbar for Android
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Setting up biometric authentication...'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColor.primaryColor,
          ),
        );
      }
      
      // Open Android biometric enrollment
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      final intent = sdkInt >= 30
          ? const AndroidIntent(
              action: 'android.settings.BIOMETRIC_ENROLL',
            )
          : const AndroidIntent(
              action: 'android.settings.SECURITY_SETTINGS',
            );
      
      try {
        await intent.launch();
      } catch (e) {
        if (kDebugMode) {
          print('Error launching biometric settings: $e');
        }
      }
      
      // Give user time to set up biometrics
      await Future.delayed(const Duration(seconds: 2));
      
      // Show completion message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please complete the biometric setup and return to the app'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Done',
              onPressed: () {},
            ),
          ),
        );
      }
    } else if (Platform.isIOS) {
      // iOS doesn't have direct settings access
      // Guide user to Settings app
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Go to Settings to enroll biometric authentication'),
            duration: const Duration(seconds: 5),
            backgroundColor: AppColor.primaryColor,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
              textColor: AppColor.whiteColor,
            ),
          ),
        );
      }
      
      // Wait for user to acknowledge
      await Future.delayed(const Duration(seconds: 2));
      
      // Prompt for authentication to verify if biometrics are now available
      try {
        await auth.authenticate(
          localizedReason: 'Verify biometric or passcode authentication',
          authMessages: <AuthMessages>[
            const IOSAuthMessages(
              localizedFallbackTitle: 'Use Passcode',
              cancelButton: 'Cancel',
            ),
          ],
        );
      } catch (e) {
        if (kDebugMode) {
          print('Authentication verification error: $e');
        }
      }
    }

    // After setup attempt, recheck biometrics to verify enrollment
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if biometrics are now available
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometrics: $e');
      }
    }
    
    if (mounted) {
      if (canCheckBiometrics) {
        // Success - biometrics are now set up
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColor.whiteColor),
                const SizedBox(width: 8),
                const Expanded(child: Text('Biometric authentication is now active!')),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Still not set up - show reminder
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometrics not detected. You can set them up later in device Settings.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
    // Proceed with authentication check
    await _checkBiometrics();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });

      // Authenticate using biometrics or device passcode
      authenticated = await auth.authenticate(
        localizedReason: 'Unlock to access your passwords',
        authMessages: <AuthMessages>[
          const AndroidAuthMessages(
            signInTitle: 'Authentication required!',
            cancelButton: 'No thanks',
          ),
          const IOSAuthMessages(
            localizedFallbackTitle: 'Use Passcode',
            cancelButton: 'Cancel',
          ),
        ],
      );
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Authentication error: $e');
      }
      setState(() {
        _isAuthenticating = false;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    if (authenticated) {
      if (_hasData) {
        GoRouter.of(context).go('/homePage');
      } else {
        GoRouter.of(context).go('/login');
      }
    }
  }

  void _handleNoBiometricSupport() {
    if (_hasData) {
      GoRouter.of(context).go('/homePage');
    } else {
      GoRouter.of(context).go('/login');
    }
  }

  Future<void> _checkData() async {
    List<PasswordModel> passwords = [];
    passwords = await CacheService().getPasswordsData();
    setState(() {
      _hasData = passwords.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isAuthenticating ? const CircularProgressIndicator() : null,
      ),
    );
  }
}
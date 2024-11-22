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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        var isPortrait = AppStyles.isPortraitMode(context);
        return AlertDialog(
          backgroundColor: ThemeChangeService().getThemeChangeValue()
              ? AppColor.grey_800
              : AppColor.grey_200,
          surfaceTintColor: ThemeChangeService().getThemeChangeValue()
              ? AppColor.grey_400
              : AppColor.grey_100,
          title: Text('Setup Biometrics',
              style: AppStyles.primaryBoldText(context, isPortrait)),
          content: Text(
              'Biometrics are supported on your device. Please set up biometrics to proceed.',
              style: AppStyles.customText(context,
                  color: ThemeChangeService().getThemeChangeValue()
                      ? AppColor.whiteColor
                      : AppColor.blackColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openBiometricSettings();
              },
              child: Text('Setup Now',
                  style: AppStyles.customText(
                    context,
                    color: AppColor.whiteColor,
                  )),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openBiometricSettings() async {
    if (Platform.isAndroid) {
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
      await intent.launch();
    } else if (Platform.isIOS) {
      // There is no direct way to open biometric settings on iOS
      // We can use the local_auth package to prompt for biometric setup
      await auth.authenticate(
        localizedReason: 'Please set up biometrics to proceed',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    }

    // After setup, recheck biometrics
    await _checkBiometrics();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });

      // Authenticate using biometrics, prioritize Face ID if available
      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        authMessages: <AuthMessages>[
          const AndroidAuthMessages(
            signInTitle: 'Authentication required!',
            cancelButton: 'No thanks',
          ),
          const IOSAuthMessages(
            localizedFallbackTitle: 'Use your Face ID',
            cancelButton: 'Cancel',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Force biometrics only (no passcode fallback)
        ),
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
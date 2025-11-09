import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:password_vault/constants/common_exports.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginState createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isGifPlaying = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);
    _controller.forward();

    // Initialize the timer to navigate after the GIF finishes
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isGifPlaying = false;
        });
        GoRouter.of(context).go('/homePage');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var height = AppStyles.viewHeight(context);
    var width = AppStyles.viewWidth(context);

    return FadeTransition(
      opacity: _animation,
      child: Stack(
        children: [
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.9),
                  BlendMode.dstIn,
                ),
                child: SvgPicture.asset(
                  'assets/images/svg/illustration2.svg',
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
            ),
            body: SafeArea(
              minimum: EdgeInsets.all(width * 0.04),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Dexter-Password Manager',
                        style: AppStyles.headline1(context, true),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'All your passwords, securely offline',
                        style: AppStyles.greyText(context, true),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SizedBox(height: height * 0.8),
                  ),
                  Center(
                    child: _isGifPlaying
                        ? Image.asset(
                            'assets/gifs/padlock.gif',
                            width: width * 0.2,
                            height: height * 0.2,
                          )
                        : Container(),
                  ),
                  Text(
                    'Simple, Safe, Secure',
                    style: AppStyles.customText(context, sizeFactor: 0.039, family: 'OpenSans'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
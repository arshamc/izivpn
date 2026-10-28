import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';
import '../drawer/animated_drawer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  String _statusText = "Initializing Xray core...";
  bool _isFadingOutContent = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      setState(() {
        double v = _progressController.value;
        if (v > 0.65) {
          _statusText = "Ready";
        } else if (v > 0.25) {
          _statusText = "Securing connection tunnels...";
        } else {
          _statusText = "Initializing Xray core...";
        }
      });
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateWithCinematicAscent();
      }
    });

    // Start progress
    _progressController.forward();
  }

  void _navigateWithCinematicAscent() {
    setState(() {
      _isFadingOutContent = true;
    });

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 750),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const AnimatedDrawerScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background: clean splash artwork
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_splash_clean.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Bottom Content
          Positioned(
            left: 0,
            right: 0,
            bottom: 50.h,
            child: AnimatedOpacity(
              opacity: _isFadingOutContent ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Title
                  Text(
                    'izi vpn',
                    style: TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeadingLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Dynamic Status Message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _statusText,
                      key: ValueKey<String>(_statusText),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSubtitleLight,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Minimalist Capsule Progress Bar
                  Container(
                    width: 200.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 200.w * _progressAnimation.value,
                            height: 5.h,
                            decoration: BoxDecoration(
                              color: AppColors.obsidianBlack,
                              borderRadius: BorderRadius.circular(3.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandCoral.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(2, 0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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

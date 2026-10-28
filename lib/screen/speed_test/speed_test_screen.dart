import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';
import '../../widget/cyber_arc_painter.dart';
import '../../widget/frosted_card.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({Key? key}) : super(key: key);

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen>
    with SingleTickerProviderStateMixin {
  bool _isTesting = false;
  double _currentSpeed = 0.0;
  double _progress = 0.0;
  double _downloadSpeed = 84.6;
  double _uploadSpeed = 24.2;
  int _pingMs = 38;
  String _serverInfo = "Germany • VLESS";

  Timer? _testTimer;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _loadCurrentServer();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  Future<void> _loadCurrentServer() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString('country') ?? 'Germany';
    setState(() {
      _serverInfo = "$country • VLESS";
    });
  }

  void _startTest() {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _currentSpeed = 0.0;
      _progress = 0.0;
      _downloadSpeed = 0.0;
      _uploadSpeed = 0.0;
    });

    int step = 0;
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      step++;
      double targetSpeed;
      if (step < 30) {
        // Download phase ramping up
        targetSpeed = (step / 30) * 88.5;
        _progress = (step / 60);
      } else if (step < 60) {
        // Upload phase
        targetSpeed = 20.0 + ((step % 10) * 0.8);
        _progress = (step / 60);
        _downloadSpeed = 84.6;
      } else {
        // Complete
        timer.cancel();
        setState(() {
          _isTesting = false;
          _progress = 1.0;
          _currentSpeed = 84.6;
          _downloadSpeed = 84.6;
          _uploadSpeed = 24.2;
          _pingMs = 38;
        });
        return;
      }

      setState(() {
        _currentSpeed = targetSpeed;
      });
    });
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background: Misty atmospheric artwork for inner screens
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_inner_screens_mist.jpg',
              fit: BoxFit.cover,
            ),
          ),

          if (isDark)
            Positioned.fill(
              child: Container(
                color: AppColors.obsidianBlack.withOpacity(0.55),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'izi vpn',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              'Speed Test',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 40.w), // Balance back button
                    ],
                  ),
                ),

                const Spacer(),

                // Center: Cyber-Arc Speedometer
                CyberArcSpeedometer(
                  progress: _isTesting ? _progress : 0.85,
                  speedMbps: _isTesting ? _currentSpeed : 84.6,
                  size: 270.w,
                ),

                SizedBox(height: 18.h),

                // Frosted Info Pills (Ping & Server)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.15 : 0.35),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            color: AppColors.brandCoral,
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Ping $_pingMs ms',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.headingText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.15 : 0.35),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.public_rounded,
                            color: AppColors.cyberCyan,
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _serverInfo,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.headingText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Lower Metrics Grid (Download & Upload Frosted Cards)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      // Download Card
                      Expanded(
                        child: FrostedCard(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          borderRadius: 22.r,
                          child: Row(
                            children: [
                              Container(
                                width: 38.w,
                                height: 38.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0).withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Color(0xFF334155),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Download',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.subtitleText(context),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '${_downloadSpeed.toStringAsFixed(1)} MB/s',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.headingText(context),
                                      ),
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // Upload Card
                      Expanded(
                        child: FrostedCard(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          borderRadius: 22.r,
                          child: Row(
                            children: [
                              Container(
                                width: 38.w,
                                height: 38.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0).withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Color(0xFF334155),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upload',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.subtitleText(context),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '${_uploadSpeed.toStringAsFixed(1)} MB/s',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.headingText(context),
                                      ),
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Bottom Action Pill Button
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 30.h),
                  child: GestureDetector(
                    onTap: _startTest,
                    child: Container(
                      width: double.infinity,
                      height: 58.h,
                      decoration: BoxDecoration(
                        color: AppColors.obsidianBlack,
                        borderRadius: BorderRadius.circular(29.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isTesting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    'Testing Speed...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Start Speed Test',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

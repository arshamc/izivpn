import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../widget/frosted_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'New VLESS Nodes Added',
      'desc': 'Added 16 high-speed VLESS & Trojan nodes across US, DE, FR, UK, NL, TR.',
      'time': '2h ago',
      'icon': Icons.layers_outlined,
      'isUnread': true,
    },
    {
      'id': '2',
      'title': 'Germany Server Upgraded',
      'desc': 'Bandwidth increased to 10 Gbps with lower latency routing.',
      'time': '1d ago',
      'icon': Icons.dns_outlined,
      'isUnread': true,
    },
    {
      'id': '3',
      'title': 'Speed Optimization Complete',
      'desc': 'Xray core 1.8.24 update deployed for enhanced tunnel stability.',
      'time': '3d ago',
      'icon': Icons.speed_rounded,
      'isUnread': false,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item['isUnread'] = false;
      }
    });
    Fluttertoast.showToast(msg: "All notifications marked as read");
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background misty artwork
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
                              'Notifications',
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
                SizedBox(height: 12.h),

                // Feed
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final bool isUnread = item['isUnread'] ?? false;

                      return FrostedCard(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        borderRadius: 22.r,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Coral unread indicator dot
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnread
                                    ? AppColors.brandCoral
                                    : Colors.transparent,
                              ),
                            ),
                            SizedBox(width: 10.w),

                            // Squircle Icon container
                            Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: AppColors.headingText(context),
                                size: 22.sp,
                              ),
                            ),
                            SizedBox(width: 14.w),

                            // Text details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.headingText(context),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        item['time'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.mutedText(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    item['desc'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.subtitleText(context),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Action Button: Mark All as Read
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 30.h),
                  child: GestureDetector(
                    onTap: _markAllAsRead,
                    child: Container(
                      width: double.infinity,
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: AppColors.obsidianBlack,
                        borderRadius: BorderRadius.circular(28.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Mark All as Read',
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

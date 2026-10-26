import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../ads/ads_service.dart';
import '../../controller/notification_controller.dart';
import '../../utils/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void initState() {
    // TODO: implement initState
    _loadBannerAd();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationController>(
      builder: (notificationController) {
        return Scaffold(
          backgroundColor: AppColors.appBgColor,
          appBar: AppBar(
            backgroundColor: AppColors.appBgColor,
            elevation: 1,
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: (){
                Get.back();
              },
              icon: Icon(Icons.arrow_back_ios,color: Colors.white,),
            ),
            title: Text("Notifications",style: GoogleFonts.inika(
                color: Colors.white,
                fontSize: 16.sp
            ),),

          ),

          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/map.png"),
                fit: BoxFit.cover,
              ),),
            child: ListView(
              children: [

                SizedBox(height: 16.h,),

                if (_isBannerAdReady)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: _bannerAd.size.width.toDouble(),
                      height: _bannerAd.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd),
                    ),
                  ),
                SizedBox(height: 12.h,),

                Column(
                  children: [
                    notificationController.isLoading==false?
                    ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: notificationController.notifications.length,
                      itemBuilder: (context,index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
                          child: Container(
                            height: 65.h,
                            decoration: BoxDecoration(
                                color: AppColors.appButtonColor,
                                borderRadius: BorderRadius.circular(10)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                          backgroundColor: AppColors.appButtonColor,
                                          child: Image.asset("assets/images/notification.png",height: 22.h,width: 24.w,color: Colors.white,)),
                                      SizedBox(width: 8.w,),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("${notificationController.notifications[index]["title"]}",style: GoogleFonts.inika(
                                              fontSize: 14.sp,
                                              color: Colors.white
                                          ),),
                                          Text("${notificationController.notifications[index]["message"]}",style: GoogleFonts.inika(
                                              fontSize: 14.sp,
                                              color: Colors.white
                                          ),),
                                        ],
                                      ),

                                    ],
                                  ),

                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    ):
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 24
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          ),
                        )
                  ],
                )
              ],
            ),
          ),

        );
      }
    );
  }
}

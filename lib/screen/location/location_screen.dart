import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gamers_shield_vpn/screen/drawer/animated_drawer.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ads/ads_service.dart';
import '../../controller/server_controller.dart';
import '../../utils/app_colors.dart';



class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {

  TextEditingController searchCtrl = TextEditingController();

  bool searchSubmit = false;

  // Function to save server data to SharedPreferences
  Future<dynamic> saveServerData(dynamic serverName, dynamic config) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('serverName', serverName);
    prefs.setString('config', config);

  }

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
    return GetBuilder<ServerController>(
        builder: (serverController) {
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
                icon: const Icon(Icons.arrow_back_ios,color: Colors.white,),
              ),
              title: Text("Vpn Location",style: GoogleFonts.inika(
                  color: Colors.white,
                  fontSize: 16.sp
              ),),

            ),

            resizeToAvoidBottomInset: false,
            body:Container(

              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/map.png"), // Replace with your actual image path
                ),

              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h,),
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


                      SizedBox(height: 16.h,),
                      TextFormField(
                        controller: searchCtrl,
                        textInputAction: TextInputAction.search,
                        onChanged: (value){
                          setState(() {
                            if(value.isNotEmpty){
                              searchSubmit = true;
                            }else{
                              searchSubmit = false;
                            }
                          });
                          serverController.searchServers(searchCtrl.text.toString());
                        },
                        style: GoogleFonts.roboto(
                            color: Colors.white
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(
                              left: 12.r
                          ),
                          prefixIcon: Icon(Icons.search,size: 18.h,color: Colors.white70,),
                          hintText: "Type here",
                          hintStyle: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.7)
                          ),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                          ),
                        ),
                      ),

                      SizedBox(height: 12,),

                      // if (_isBannerAdReady)
                      //   Align(
                      //     alignment: Alignment.bottomCenter,
                      //     child: Container(
                      //       width: _bannerAd.size.width.toDouble(),
                      //       height: _bannerAd.size.height.toDouble(),
                      //       child: AdWidget(ad: _bannerAd),
                      //     ),
                      //   ),

                      if(searchSubmit==true)...{
                        ListView.builder(
                            itemCount: serverController.filteredServerData.length,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context,index) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: GestureDetector(
                                  onTap: (){
                                   saveServerData(
                                       serverController.filteredServerData[index]["serverName"],
                                       serverController.filteredServerData[index]["config"],
                                   );
                                    Get.offAll(()=> AnimatedDrawerScreen());
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                ClipOval(
                                                  child: Image.memory( Uint8List.fromList(
                                                    Base64Decoder().convert(serverController.filteredServerData[index]['imagePath']!.split(',').last),
                                                  ),
                                                    height: 35.h,
                                                    width: 35.w,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                SizedBox(width: 10.w,),
                                                Text("${serverController.filteredServerData[index]["serverName"]}",style: GoogleFonts.roboto(
                                                    color: Colors.white,
                                                    fontSize: 15.sp,
                                                    fontWeight: FontWeight.w400
                                                ),)
                                              ],
                                            ),
                                            Image.asset("assets/images/network.png",
                                              height: 28.h,
                                              width: 28.w,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                        ),
                      }
                      else...{
                        serverController.isLoading==false?
                        ListView.builder(
                            itemCount: serverController.serverData.length,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context,index) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: GestureDetector(
                                  onTap: (){
                                    saveServerData(
                                      serverController.filteredServerData[index]["serverName"],
                                      serverController.filteredServerData[index]["config"],
                                    );
                                    Get.offAll(()=> AnimatedDrawerScreen());
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                serverController.serverData[index]['imagePath']!=null?
                                                ClipOval(
                                                  child: Image.memory( Uint8List.fromList(
                                                    Base64Decoder().convert(serverController.serverData[index]['imagePath']!.split(',').last),
                                                  ),
                                                    height: 35.h,
                                                    width: 35.w,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ):
                                                ClipOval(
                                                  child: Icon(Icons.image_outlined,
                                                    color: Colors.white70,
                                                    size: 35.h,
                                                  ),
                                                ),
                                                SizedBox(width: 10.w,),
                                                Text("${serverController.serverData[index]["serverName"]}",style: GoogleFonts.roboto(
                                                    color: Colors.white,
                                                    fontSize: 15.sp,
                                                    fontWeight: FontWeight.w400
                                                ),)
                                              ],
                                            ),
                                            Image.asset("assets/images/network.png",
                                              height: 28.h,
                                              width: 28.w,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                        ):
                        const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        )
                      }


                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }
}

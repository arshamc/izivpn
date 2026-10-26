import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ads/ads_service.dart';
import '../../utils/app_constant.dart';
import '../../widget/custom_clipper.dart';
import '../location/location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  dynamic serverName;
  dynamic config;

  loadConfigData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      serverName = prefs.getString('serverName');
      config = prefs.getString('config');
    });
    if (kDebugMode) {
      print(serverName);
      print(config);
    }

  }

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: AdHelper.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < 3) {
              _createRewardedAd();
            }
          },
        ));
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      print('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
        });
    _rewardedAd = null;
  }


  @override
  void dispose() {
    _rewardedAd!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    _createRewardedAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadConfigData();
      flutterV2ray.initializeV2Ray().then((value) async {
        coreVersion = await flutterV2ray.getCoreVersion();
        setState(() {});
      });
    });

    super.initState();
  }

  late final FlutterV2ray flutterV2ray = FlutterV2ray(
    onStatusChanged: (status) {
      v2rayStatus.value = status;
    },
  );
  List<String> bypassSubnets = [];
  final bypassSubnetController = TextEditingController();
  var v2rayStatus = ValueNotifier<V2RayStatus>(V2RayStatus());
  String? coreVersion;

  void bypassSubnet() {
    bypassSubnetController.text = bypassSubnets.join("\n");
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Subnets:',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: bypassSubnetController,
                maxLines: 5,
                minLines: 5,
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  bypassSubnets =
                      bypassSubnetController.text.trim().split('\n');
                  if (bypassSubnets.first.isEmpty) {
                    bypassSubnets = [];
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: bgColor,
        body: ListView(
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: <Widget>[
                ClipPath(
                  clipper: MyCustomClipper(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    height: 180,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: <Color>[
                            Color(0xffF57D1F),
                            Color(0xffF57D1F),
                          ],
                          focalRadius: 16,
                        )
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ValueListenableBuilder(
                        valueListenable: v2rayStatus,
                        builder: (context, value, child) {
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () async{
                                 if(config!=null){
                                   if (value.state == "DISCONNECTED") {
                                     V2RayURL parser = FlutterV2ray.parseFromURL(config);
                                     if(await flutterV2ray.requestPermission()){
                                  flutterV2ray.startV2Ray(
                                  remark: parser.remark,
                                  config: parser.getFullConfiguration(),
                                    proxyOnly: false,
                                    bypassSubnets: bypassSubnets,
                                  );
                                  setState(() {

                                  });
                                  }
                                   } else {
                                     _showRewardedAd();
                                     flutterV2ray.stopV2Ray();
                                   }
                                 }
                                 else{
                                   Fluttertoast.showToast(
                                       msg: "Please select a location",
                                       toastLength: Toast.LENGTH_SHORT,
                                       gravity: ToastGravity.BOTTOM,
                                       timeInSecForIosWeb: 1,
                                       backgroundColor: Colors.red,
                                       textColor: Colors.white,
                                       fontSize: 16.0
                                   );
                                 }

                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    Container(
                                      height: width * 0.51,
                                      width: width * 0.51,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: <Color>[
                                              Color(0xffF57D1F),
                                              Color(0xffF57D1F),
                                            ],
                                            focalRadius: 16,
                                          )
                                        // color: Colors.red,
                                      ),
                                      child: Center(
                                        child: Container(
                                          height: width * 0.5,
                                          width: width * 0.5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: bgColor,
                                          ),
                                          child: Center(
                                            child: Container(
                                              height: width * 0.43,
                                              width: width * 0.43,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient:
                                                  value.state == "DISCONNECTED"
                                                      ? LinearGradient(
                                                    colors: <Color>[
                                                      Colors.red,
                                                      Colors.blue,
                                                    ],
                                                  )
                                                      : LinearGradient(
                                                    colors: <Color>[
                                                      Color(0XFFFFB534),
                                                      Color(0XFF00C2A0),
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0XFF00D58D)
                                                          .withOpacity(.2),
                                                      spreadRadius: 15,
                                                      blurRadius: 15,
                                                    ),
                                                  ]),
                                              child: Center(
                                                child: Icon(Icons.power_settings_new,
                                                    color: Colors.white, size: 50),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                        bottom: 50,
                                        child: value.state == "DISCONNECTED"
                                            ? Text(
                                          "Tap to Connect",
                                          style: TextStyle(color: Colors.white),
                                        )
                                            : Text(
                                          "Tap to Disconnect",
                                          style: TextStyle(color: Colors.white),
                                        ))
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 24,
                              ),
                              Text(
                                value.state,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Duration: ${value.duration}',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Traffic:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${value.upload}↑ ${value.download}↓',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 34),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.upload_outlined,
                                          color: Colors.yellow,
                                        ),
                                        Text(
                                          'Upload ${value.uploadSpeed}',
                                          style: txtSpeedStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.download_outlined,
                                          color: Colors.green,
                                        ),
                                        Text(
                                          'Download ${value.downloadSpeed}',
                                          style: txtSpeedStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 30,),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30
                                ),
                                child: GestureDetector(
                                  onTap: (){
                                  Get.to(()=>LocationScreen(),transition: Transition.rightToLeft);
                                  },
                                  child: Container(
                                    height: 60,
                                    width: 300,
                                    decoration: BoxDecoration(
                                        color: Color(0xffF3887BE),
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 30),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.language_outlined,size: 30,),
                                              SizedBox(width: 12,),
                                              Text("Select Location",style: TextStyle(color: Colors.white,
                                                  fontSize: 16
                                              ),)
                                            ],
                                          ),
                                          Icon(Icons.arrow_forward_ios_rounded,color: Colors.white,size: 24,)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 20,),

                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import 'package:share_extend/share_extend.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_constant.dart';
import '../home/home_screen.dart';
import '../notification/notification_screen.dart';
import '../speed_test/speed_test_screen.dart';

class AnimatedDrawerScreen extends StatefulWidget {
  @override
  _AnimatedDrawerScreenState createState() => _AnimatedDrawerScreenState();
}

class _AnimatedDrawerScreenState extends State<AnimatedDrawerScreen> {
  final ZoomDrawerController zoomDrawerController = ZoomDrawerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xffF57D1F),
      appBar: AppBar(
        backgroundColor: Color(0xffF57D1F),
        leading: GestureDetector(
          onTap: (){
            zoomDrawerController.toggle!();
          },
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              height: 50,
              width: 80,
              decoration: BoxDecoration(
                color: bgColor,
              ),
              child: Icon(
                Icons.menu_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: (){
                    Get.to(()=> NotificationScreen());
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 20,
                    child: Icon(Icons.notifications,
                      color: Colors.white,size: 24,),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: ZoomDrawer(
        shadowLayer1Color: Colors.deepOrange.withOpacity(0.3),
        controller: zoomDrawerController,
        menuScreen: MenuScreen(),
        mainScreen: HomeScreen(),
        borderRadius: 12.0,
        showShadow: true,
        menuBackgroundColor: Color(0xffF57D1F),
        angle: -8.0,
        slideWidth: MediaQuery.of(context).size.width * 0.60,
      ),
    );
  }
}

final ZoomDrawerController zoomDrawerController = ZoomDrawerController();
class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xffF57D1F),
      child: ListView(
        padding: EdgeInsets.only(top: 10),
        children: [
          ListTile(
            leading: CircleAvatar(
                backgroundColor: buttonColor,
                child: Icon(Icons.home,color: Colors.white,)),
            title: Text('Home',style: TextStyle(
                color: Colors.white,fontSize: 16),),
            onTap: () {
              ZoomDrawer.of(context)?.close();
            },
          ),


          SizedBox(height: 4,),

          ListTile(
            leading: CircleAvatar(
                backgroundColor: buttonColor,
                child: Icon(Icons.speed,color: Colors.white,)),
            title: Text('Speed Test',style: TextStyle(color:
            Colors.white,fontSize: 16),),
            onTap: () {
               Get.to(()=>SpeedTestScreen(),transition: Transition.rightToLeft);
            },
          ),

          SizedBox(height: 4,),

          ListTile(
            leading: CircleAvatar(
                backgroundColor: buttonColor,
                child: Icon(Icons.star_rate_outlined,color: Colors.white,)),
            title: Text('Rate Us',style: TextStyle(color:
            Colors.white,fontSize: 16),),
            onTap: () async{
              const youtubeUrl = 'https://play.google.com/';  // Replace with your desired YouTube URL
              if (await canLaunch(youtubeUrl)) {
                await launch(youtubeUrl);
              } else {
                throw 'Could not launch $youtubeUrl';
              }
            },
          ),

          SizedBox(height: 4,),

          ListTile(
            leading: CircleAvatar(
                backgroundColor: buttonColor,
                child: Icon(Icons.share_outlined,color: Colors.white,)),
            title: Text('Share',style: TextStyle(color:
            Colors.white,fontSize: 16),),
            onTap: () {
              String textToShare = 'https://play.google.com/store/games';  // Replace with the text you want to share
              ShareExtend.share(textToShare, 'text');
            },
          ),

          SizedBox(height: 4,),

          ListTile(
            leading: CircleAvatar(
                backgroundColor: buttonColor,
                child: Icon(Icons.category_outlined,color: Colors.white,)),
            title: Text('More Apps',style: TextStyle(color:
            Colors.white,fontSize: 16),),
            onTap: () async{
              const youtubeUrl = 'https://play.google.com/';  // Replace with your desired YouTube URL
              if (await canLaunch(youtubeUrl)) {
                await launch(youtubeUrl);
              } else {
                throw 'Could not launch $youtubeUrl';
              }
            },
          ),



        ],
      ),
    );
  }
}


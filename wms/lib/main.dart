// ignore_for_file: prefer_typing_uninitialized_variables, must_be_immutable

import 'package:flutter/material.dart';
import 'package:wms/manager.dart';
import 'package:wms/vendor.dart';
import './login.dart';

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
   SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(token: prefs.getString('token'), user: prefs.getString('user'), designation: prefs.getString('designation')));
}

class MyApp extends StatelessWidget {

  final token;
  var user;
  var designation;

  MyApp({super.key, @required this.token, @required this.user, @required this.designation});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        
        // This is the theme of your application.
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),  
        useMaterial3: true,
      ),
      //  home: (token != null && JwtDecoder.isExpired(token) == false )? (designation == 'osm' ? Manager(token: token, manager: user): Vendor(token: token, vendor: user)): const LoginPage()
       initialRoute: (token != null && JwtDecoder.isExpired(token) == false )? (designation == 'osm' ? '/manager': '/vendor'): '/' ,
       routes: {
    // When navigating to the "/" route, build the FirstScreen widget.
    '/': (context) => const LoginPage(),
    // When navigating to the "/second" route, build the SecondScreen widget.
    '/manager': (context) =>  Manager(token: token, manager: user),
    '/vendor':(context) =>  Vendor(token: token, vendor: user)
  },

    );
  }
}
   


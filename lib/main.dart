// ignore_for_file: prefer_typing_uninitialized_variables, must_be_immutable

import 'package:flutter/material.dart';
import 'package:wmsapp/admin.dart';
import 'package:wmsapp/manager.dart';
import 'package:wmsapp/vendor.dart';
import './login.dart';
 // Import AdminHomePage

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(
      token: prefs.getString('token'),
      user: prefs.getString('user'),
      designation: prefs.getString('designation'),
      admin_status: prefs.getString('admin_status')));
}

class MyApp extends StatelessWidget {
  final token;
  var user;
  var designation;
  var admin_status;

  MyApp(
      {super.key,
      @required this.token,
      @required this.user,
      @required this.designation,
      @required this.admin_status});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: (token != null && JwtDecoder.isExpired(token) == false)
          ? (admin_status == 'true' // Compare as String
              ? '/admin'
              : (designation == 'osm' ? '/manager' : '/vendor'))
          : '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/manager': (context) => Manager(token: token, manager: user),
        '/vendor': (context) => Vendor(token: token, vendor: user),
        '/admin': (context) => const AdminHomePage(), // Define the /admin route
      },
    );
  }
}
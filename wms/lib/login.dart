// ignore_for_file: use_build_context_synchronously, prefer_typing_uninitialized_variables, must_be_immutable, empty_constructor_bodies, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:wms/manager.dart';
import 'package:wms/vendor.dart';



class LoginPage extends StatefulWidget {

  const LoginPage({super.key});

  

  @override
  // ignore: library_private_types_in_public_api
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // final TextEditingController usernameController = TextEditingController();
  // final TextEditingController passwordController = TextEditingController();

  // void _login() async {
  //   final String username = usernameController.text;
  //   final String password = passwordController.text;

  //   // Define your server URL for the POST request
  //   const String apiUrl = 'http://153.92.5.199:5000/applogin';

  //   final response = await http.post(
  //     Uri.parse(apiUrl),
  //     body: jsonEncode({'username': username, 'password': password}),
  //     headers: {'Content-Type': 'application/json'},
  //   );

  //   if (response.statusCode == 200) {
  //     // Login successful, navigate to home page
  //     Navigator.of(context).pushReplacement(MaterialPageRoute(
  //       builder: (context) => HomePage(),
  //     ));
  //   } else {
  //     // Handle login error (e.g., show an error message)
  //     // ignore: use_build_context_synchronously
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Login failed. Please try again.'),
  //       ),
  //     );
  //   }
  // }

  Future<void> _showMyDialog({String type = 'Alert', String message = 'Error occurred'}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title:  Text(type),
        content:  SingleChildScrollView(
          child: Text(message)
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

 Future<void> _showTrueDialog({String type = 'Alert', String message = 'Success'}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title:  Text(type),
        content:  SingleChildScrollView(
          child: Text(message)
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

 TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isNotValidate = false;
  late SharedPreferences prefs;


  @override
  void initState() {
    
    super.initState();
    initSharedPref();
  }

  void initSharedPref() async{
    
    prefs = await SharedPreferences.getInstance();
  }

   String login = 'http://153.92.5.199:5000/applogin';

  void loginUser() async{
    if(usernameController.text.isNotEmpty && passwordController.text.isNotEmpty){

      //_showTrueDialog();

      var reqBody = {
        "username":usernameController.text,
        "password":passwordController.text
      };
      
      print(reqBody);
      var response = await http.post(Uri.parse(login),
          headers: {"Content-Type":"application/json"},
          body: jsonEncode(reqBody)
      );
      //print(response);
      var jsonResponse = jsonDecode(response.body);
      if(jsonResponse['status'] && jsonResponse['designation'] == "osm"){

          var myToken = jsonResponse['token'];
          prefs.setString('token', myToken);
          prefs.setString('designation', jsonResponse['designation']);
          prefs.setString('user', jsonResponse['user']);
          

          
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> Manager(token: myToken, manager: jsonResponse['user'],)), (Route<dynamic> route) => false,);
      }else if(jsonResponse['status'] && jsonResponse['designation'] == "vendor"){
          var myToken = jsonResponse['token'];
          prefs.setString('token', myToken);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> Vendor(token: myToken, vendor: jsonResponse['user'])), (Route<dynamic> route) => false,);
      }
      
      
      
      else{
        _showMyDialog();
      }
    }else{
      setState(() {
        _isNotValidate = true;
      });
      }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username',  errorText: _isNotValidate ? "Enter Valid Info" : null,), 
            ),
            
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password',  errorText: _isNotValidate ? "Enter Valid Info" : null,),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginUser,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}



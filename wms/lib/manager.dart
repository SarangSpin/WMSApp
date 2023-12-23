// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wms/login.dart';
import 'package:wms/managerEvent.dart';

// ignore: must_be_immutable, duplicate_ignore
class Manager extends StatefulWidget{
  
  var token = "";

  
  
  
  
  var manager;
   Manager({super.key, required this.token, required this.manager});

  @override
  State<Manager> createState() => _ManagerState();
}

class _ManagerState extends State<Manager> with TickerProviderStateMixin{

  Future<void> _showDialog({String type = 'Alert', String message = 'Success'}) async {
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

  var mainData;
  late TabController _controller;
  //  late Map<String, dynamic> jsonResponse;
  List<dynamic> jsonResponse = [];

  @override
  void initState(){
    super.initState();
    initSharedPref();
    _controller = TabController(length: 2, vsync: this); 
    // managerDash();
  }

  void initSharedPref() async{
    
    mainData = await SharedPreferences.getInstance();
  }

 var response;
  Future<List<dynamic>> managerDash() async{
    var managerResponse = jsonDecode(widget.manager);
    String url = 'http://153.92.5.199:5000/managerDash?osm=${managerResponse['employee_id']}';


      response = await http.get(Uri.parse(url),
          headers: {"Content-Type":"application/json"},
      );

       jsonResponse = jsonDecode(response.body)['data'];
       log("${widget.manager}");
       log(managerResponse['employee_id']);
       
       return jsonResponse;
       
  }

  @override
  Widget build(BuildContext context){

    
    return(Scaffold(
     appBar: AppBar(
      centerTitle: true,
        title:  Text('Manager: ${jsonDecode(widget.manager)['first_name']} ${jsonDecode(widget.manager)['last_name']}'),
        actions: <Widget>[
          // TextButton(onPressed:() => Navigator.pop(context, ), child: const Text("Logout"))
          TextButton(onPressed: ()=> Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const LoginPage()), (Route<dynamic> route) => false,), child: const Text("Logout"))
        ],
        bottom:  TabBar(
          controller: _controller,
          tabs: const [
            Text("Assigned "),
             Text("Completed")
          ],
        )
      ),
      body:  FutureBuilder<List<dynamic>>(
        future: managerDash(), // function where you call your api
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {  // AsyncSnapshot<Your object type>
          if( snapshot.connectionState == ConnectionState.waiting){
            return  Center(child: CircularProgressIndicator());
          }else{
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));
            else{
              return  TabBarView(
        controller: _controller,
        children:  [
          ListView.builder(
      itemCount: jsonResponse.length,
      itemBuilder: (context, index) {
        return 
        Card(
          child: Visibility(
            visible: jsonResponse[index]['status'] == 'assigned',
          replacement: SizedBox(child: Center(child: Text('No Pending Assignments', style: TextStyle(fontSize: 30),)), height: MediaQuery.sizeOf(context).height, width: MediaQuery.sizeOf(context).width),
            child: 
          ListTile(
            title: Text('Event: ${jsonResponse[index]['event_']}'),
            subtitle: Text('Population: ${jsonResponse[index]['population']} '),
            trailing: Text('Deadline: ${jsonResponse[index]['start_date'].toString().substring(0,10)}', style: const TextStyle(color: Colors.red, fontSize: 18) ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=> ManagerEvent(event: jsonResponse[index]))),
          tileColor: Colors.orange[100],
          ),
          )
          
          
        );
        }),
          // const Text("Completed")
          ListView.builder(
      itemCount: jsonResponse.length,
      itemBuilder: (context, index) {
        return 
        Card(
          child: Visibility(
            visible: jsonResponse[index]['status'] == 'completed',
          replacement:  SizedBox(child: Center(child: Text('No Completed Assignments', style: TextStyle(fontSize: 30),)), height: MediaQuery.sizeOf(context).height, width: MediaQuery.sizeOf(context).width),
            child: 

          ListTile(
            title: Text('Event: ${jsonResponse[index]['event_']}'),
            subtitle: Text('Population: ${jsonResponse[index]['population']} '),
            trailing: Text('Deadline: ${jsonResponse[index]['start_date'].toString().substring(0,10)}', style: const TextStyle(color: Colors.black,  fontSize: 18),),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=> ManagerEvent(event: jsonResponse[index]))),
            tileColor: Colors.lightGreen,
          ),


          )
          
          
        );
        })
        ],
      );}}})

    ));
  }
}
import 'package:flutter/material.dart';
import 'package:wms/login.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:wms/tasksubmission.dart';
import 'package:wms/tasksubview.dart';


// ignore: must_be_immutable
class Vendor extends StatefulWidget{
  // ignore: prefer_typing_uninitialized_variables
  var token;
  // ignore: prefer_typing_uninitialized_variables
  var vendor;
  
   Vendor({super.key, @required this.token, @required this.vendor});

  @override
  State<Vendor> createState() => _VendorState();
}

class _VendorState extends State<Vendor> {
    List<dynamic> jsonRes = [];
  

  @override
  void initState(){
    super.initState();
    // taskDash();
  }

   var response;
   var vendorResponse;

  Future<List<dynamic>> taskDash() async{

     vendorResponse = jsonDecode(widget.vendor);
    String url = 'http://153.92.5.199:5000/vendorTask?id=${vendorResponse["vendor_id"]}';


      response = await http.get(Uri.parse(url),
          headers: {"Content-Type":"application/json"},
      );

       jsonRes = jsonDecode(response.body)['data'];
       log(response.body);
       
       
       return jsonRes;
       
  }

  @override
  Widget build(BuildContext context){

    return(Scaffold(
     appBar: AppBar(
      centerTitle: true,
        title:  Text('Vendor: ${jsonDecode(widget.vendor)['vendor_name']} '),
        actions: <Widget>[
          // TextButton(onPressed:() => Navigator.pop(context, ), child: const Text("Logout"))
          TextButton(onPressed: ()=> Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const LoginPage()), (Route<dynamic> route) => false,), child: const Text("Logout"))
        ],
       
      ),
      body:  FutureBuilder<List<dynamic>>(
        future: taskDash(), // function where you call your api
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {  // AsyncSnapshot<Your object type>
          if( snapshot.connectionState == ConnectionState.waiting){
            return  const Center(child: CircularProgressIndicator());
          }else{
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else{
              return ListView.builder(
      itemCount: jsonRes.length,
      itemBuilder: (context, index) {
        return 
        Card(
  child: Container(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
  
  Text('Task Name: ${jsonRes[index]["task_name"]}'),
  const SizedBox(height: 10.0),
  Text('Sub - Event: ${jsonRes[index]["name"]}'),
  const SizedBox(height: 8.0),
  Text('Description: ${jsonRes[index]["description_"] ?? "N/A"}'),
  const SizedBox(height: 8.0),
  Text('Deadline: ${jsonRes[index]["deadline"]}', style: const TextStyle(color: Colors.red)),
  const SizedBox(height: 8.0),
  Text('Type: ${jsonRes[index]["type"]  ?? "N/A"}'),
  const SizedBox(height: 8.0),
  Text('Name: ${jsonRes[index]["name"]}'),
  const SizedBox(height: 8.0),
  Text('Start Time: ${jsonRes[index]["start_time"]}' , style: const TextStyle(color: Colors.orangeAccent)),
  const SizedBox(height: 8.0),
  Text('End Time: ${jsonRes[index]["end_time"]}' , style: const TextStyle(color: Colors.orangeAccent)),
  const SizedBox(height: 8.0),
  Text('Event Date: ${jsonRes[index]["event_date"].toString().substring(0,10)}'),
  const SizedBox(height: 8.0),
  Row(
    children: [
      const Text('Status:'),
      Visibility(
        visible: jsonRes[index]["status"] == 'Completed' ,
        child: const Text('Completed', style: TextStyle(color: Colors.green),)),
        Visibility(
        visible: jsonRes[index]["status"] == 'Incomplete' ,
        child: const Text('Incomplete', style: TextStyle(color: Colors.red),)),
        
      
    ],
  ),
  const SizedBox(height: 8.0),
  Visibility(
    visible: jsonRes[index]["status"] == 'Incomplete',
    child: TextButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>  TaskSub( task_id: jsonRes[index]["task_id"], vendor_id: vendorResponse["vendor_id"]))), child: const Text("Make a Submission")))
  ,
  const SizedBox(height: 8.0),
  TextButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>  TaskSubView( task_id: jsonRes[index]["task_id"], vendor_id: vendorResponse["vendor_id"]))), child: const Text("View Previous Submissions"))

],
    ),
  ),
);

        });
            }
          }
        }
      )
      
      
      
      
      

    ));
  }
}
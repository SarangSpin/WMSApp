// ignore_for_file: use_build_context_synchronously, prefer_typing_uninitialized_variables, must_be_immutable, empty_constructor_bodies



import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wms/managerSubReview.dart';





class ManagerTasks extends StatefulWidget {
  var id;
  
  var event;


   ManagerTasks({super.key, required this.id, required this.event});

  

  @override
  // ignore: library_private_types_in_public_api
  State<ManagerTasks> createState() => _ManagerTasksState();
}

class _ManagerTasksState extends State<ManagerTasks> {

  List<dynamic> jsonRes = [];
  

  @override
  void initState(){
    super.initState();
    // taskDash();
  }

   var response;
  Future<List<dynamic>> taskDash() async{
    
    String url = 'http://153.92.5.199:5000/tasklist?id=${widget.id}';


      response = await http.get(Uri.parse(url),
          headers: {"Content-Type":"application/json"},
      );

       jsonRes = jsonDecode(response.body)['data'];
       log(response.body);
       
       
       return jsonRes;
       
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:  Text('${widget.event}: Tasks'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: taskDash(), // function where you call your api
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {  // AsyncSnapshot<Your object type>
          if( snapshot.connectionState == ConnectionState.waiting){
            return  Center(child: CircularProgressIndicator());
          }else{
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));
            else{
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
  SizedBox(height: 10.0),
  Text('Sub - Event: ${jsonRes[index]["name"]}'),
  SizedBox(height: 8.0),
  Text('Description: ${jsonRes[index]["description_"] ?? "N/A"}'),
  SizedBox(height: 8.0),
  Text('Deadline: ${jsonRes[index]["deadline"]}'),
  SizedBox(height: 8.0),
  Text('Type: ${jsonRes[index]["type"]  ?? "N/A"}'),
  SizedBox(height: 8.0),
  Text('Vendor: ${jsonRes[index]["vendor"]}'),
  SizedBox(height: 8.0),
  Text('Name: ${jsonRes[index]["name"]}'),
  SizedBox(height: 8.0),
  Text('Start Time: ${jsonRes[index]["start_time"]}'),
  SizedBox(height: 8.0),
  Text('End Time: ${jsonRes[index]["end_time"]}'),
  SizedBox(height: 8.0),
  Text('Event Date: ${jsonRes[index]["event_date"].toString().substring(0,10)}'),
  SizedBox(height: 8.0),
  Row(
    children: [
      Text('Status:'),
      Visibility(
        visible: jsonRes[index]["status"] == 'Completed' ,
        child: Text('Completed', style: TextStyle(color: Colors.green),)),
        Visibility(
        visible: jsonRes[index]["status"] == 'Incomplete' ,
        child: Text('Incomplete', style: TextStyle(color: Colors.red),)),
        
      
    ],
  ),
  SizedBox(height: 8.0),
  TextButton(onPressed: ()=>{Navigator.push(context, MaterialPageRoute(builder: (context)=>  ManagerSubView(task_id: jsonRes[index]["task_id"])))}, child: const Text("Check Submissions"))

],
    ),
  ),
);

        });
            }
          }
        }
      )





          
          
          
       
    );
  }
}





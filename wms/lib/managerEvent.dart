// ignore_for_file: use_build_context_synchronously, prefer_typing_uninitialized_variables, must_be_immutable, empty_constructor_bodies



import 'dart:convert';
import 'dart:developer';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:wms/managerTasks.dart';





class ManagerEvent extends StatefulWidget {
  var event;


   ManagerEvent({super.key, required this.event});

  

  @override
  // ignore: library_private_types_in_public_api
  State<ManagerEvent> createState() => _ManagerEventState();
}

class _ManagerEventState extends State<ManagerEvent> {

  List<dynamic> jsonRes = [];
  
  var images_length = [];
  

  @override
  void initState(){
    super.initState();
    // venue();
  }


   var response;
  Future<List<dynamic>> venue() async{
    
    String url = 'http://153.92.5.199:5000/venue?id=${widget.event['venue_id']}';


      response = await http.get(Uri.parse(url),
          headers: {"Content-Type":"application/json"},
      );

      jsonRes= jsonDecode(response.body)['data'];

      
  // ImagesSubView(jsonRes[i]["task_submission_id"]);
  String imgurl = 'http://153.92.5.199:5000/managerView?appl_id=${widget.event['appl_id']}';

    var imgResponse;
      imgResponse = await http.get(Uri.parse(imgurl),
          headers: {"Content-Type":"application/json"},
      );
      log(imgResponse.body.toString());

       images_length.add(jsonDecode(imgResponse.body)['data']); 
                                                     
       return images_length;
     
       
     
       
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:  Text('Event: ${widget.event['event_']} (${widget.event['start_date'].toString().substring(0,10)})'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: venue(), // function where you call your api
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
    padding: EdgeInsets.all(16.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Application Date: ${widget.event["appln_date"].toString().substring(0,10)}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        
        Visibility(
          visible: widget.event["description_"].toString() != 'null',
          child: Column(
            children: [
              SizedBox(height: 15.0),
              Text('Description: ${widget.event["description_"] ?? "N/A"}'),
            ],
          )),
        SizedBox(height: 10.0),
        Text('Start Date: ${widget.event["start_date"].toString().substring(0,10)}'),
        SizedBox(height: 10.0),
        Text('End Date: ${widget.event["end_date"].toString().substring(0,10)}'),
        SizedBox(height: 10.0),
        Text('Population: ${widget.event["population"]}'),
        SizedBox(height: 10.0),
        Visibility(
          visible: widget.event["budget"] == 'custom' ,
          child: Column(
            children: [
              Text('Custom Low Budget: ${widget.event["cus_low_budget"]}'),
              SizedBox(height: 10.0),
            ],
          )),
        
        
        Visibility(
          visible: widget.event["budget"] == 'custom' ,
          child: Column(
            children: [
              Text('Custom Event: ${widget.event["cus_event"] ?? "N/A"}'),
              SizedBox(height: 10.0),
            ],
          )),
        
        
        Text('Venue: ${jsonRes[index]['venues_name']}, ${jsonRes[index]['location']}'),
        SizedBox(height: 10.0),
        TextButton(onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>  ManagerTasks(id: widget.event["appl_id"], event: widget.event['event_']))), child: const Text("Check Tasks")),

        CarouselSlider.builder(
  options: CarouselOptions(height: 300.0),
  itemCount: images_length[0],
  itemBuilder: (BuildContext context, int i, int pageViewIndex) =>
  InstaImageViewer(child: 
  Image.network('http://153.92.5.199:5000/images/appln/${widget.event['appl_id']}/${widget.event['appl_id']}_${i+1}.png', width: MediaQuery.of(context).size.width, height: 200,
    errorBuilder: (context, error, stackTrace) {
    return Text('Error Loading');
  },
  frameBuilder: (BuildContext context, Widget child, int? frame, bool? wasSynchronouslyLoaded) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: child,
    );
  },
  loadingBuilder: (BuildContext ctx, Widget child, ImageChunkEvent? loadingProgress) {
    
        if (loadingProgress == null) {
          return child;
        }else {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          );
        }
      },   
     )
  )
  
  
    ,
),

        
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



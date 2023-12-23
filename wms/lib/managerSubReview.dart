
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:developer';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:wms/subreview.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'package:cloudinary_flutter/cloudinary_context.dart';
// import 'package:cloudinary_flutter/image/cld_image.dart';
// import 'package:cloudinary_url_gen/cloudinary.dart';



// ignore: must_be_immutable
class ManagerSubView extends StatefulWidget {
  var task_id;
  var finish = 'Incomplete';
  
 


   ManagerSubView({super.key, @required this.task_id});

  

  @override
  // ignore: library_private_types_in_public_api
  State<ManagerSubView> createState() => _ManagerSubViewState();
}

class _ManagerSubViewState extends State<ManagerSubView> {


List<dynamic> jsonRes = [];

  //  List<XFile> _image = [];
  final imagePicker = ImagePicker();
  TextEditingController reviewController = TextEditingController();
  


  // void pickImages() async{
  //  _image = await imagePicker.pickMultiImage(imageQuality: 70, requestFullMetadata: false);
  //  setState(() {
     
  //  });
   
  // }

  @override
  void initState() {
    
    super.initState();
    // taskSubViewDash();
    // ImagesSubView();
   
  }

  var response;
  var images_length = [];
  var color = [];


  Future<List<dynamic>>  managerSubViewDash() async{
    
    String url = 'http://153.92.5.199:5000/managersubview?task_id=${widget.task_id}';


      response = await http.get(Uri.parse(url),
          headers: {"Content-Type":"application/json"},
      );

       jsonRes = jsonDecode(response.body)['data'];
      //  log(response.body);

      

       for (var i = 0; i < jsonRes.length; i++) {

        if(jsonRes[i]["status"] == "Incomplete")
        {
          color.add(Colors.red);
          
        }
        else{
          color.add(Colors.green);
          widget.finish = 'Completed';
        }

        

  // ImagesSubView(jsonRes[i]["task_submission_id"]);
  String imgUrl = 'http://153.92.5.199:5000/imagesubview?task_submission_id=${jsonRes[i]["task_submission_id"]}';

    var imgResponse;
      imgResponse = await http.get(Uri.parse(imgUrl),
          headers: {"Content-Type":"application/json"},
      );

      images_length.add(jsonDecode(imgResponse.body)['data']); 

    }

    if(widget.finish == 'Completed')
    {
    String url2 = 'http://153.92.5.199:5000/taskfinish?task_id=${widget.task_id}';
    
     var response2 =  await http.get(Uri.parse(url2),
          headers: {"Content-Type":"application/json"},
      );
      log(response2.statusCode.toString());
    }

      log(images_length.toString());                                              
       return images_length;
       
  }

  

  // Future<void> ImagesSubView() async{
    
  //   for (var i = 0; i < jsonRes.length; i++) {
  // // ImagesSubView(jsonRes[i]["task_submission_id"]);
  // String imgurl = 'http://153.92.5.199:5000/imagesubview?task_submission_id=${jsonRes[i]["task_submission_id"]}';

  //   var imgResponse;
  //     imgResponse = await http.get(Uri.parse(imgurl),
  //         headers: {"Content-Type":"application/json"},
  //     );

  //      images_length.add(jsonDecode(imgResponse.body)['data']); 
  //       }
       
  //      setState(() {});

       
  // }


@override
  Widget build(BuildContext context) {
      
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Task Submissions'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: managerSubViewDash(), // function where you call your api
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {  // AsyncSnapshot<Your object type>
          if( snapshot.connectionState == ConnectionState.waiting){
            return  Center(child: CircularProgressIndicator());
          }else{
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));
            else
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
  
  Text('Review: ${jsonRes[index]["review"]}'),
  SizedBox(height: 10.0),
  Text('Time: ${jsonRes[index]["time"].toString().substring(0,10)}'),
  SizedBox(height: 8.0),
  Row(
    children: [
      Text('Status: '),
      Text('${jsonRes[index]["status"] ?? "N/A"}', style: TextStyle(color: color[index]),),
    ],
  ),
  SizedBox(height: 8.0),
  Visibility(
    visible: jsonRes[index]["status"] == 'Completed',
    child: Text('Manager Suggested Changes: ${jsonRes[index]["osm_changes"]}'))
  ,
  Visibility(
    visible: jsonRes[index]["status"] == 'Incomplete',
    child: Column(
      children: [
        Text('Manager Suggested Changes: ${jsonRes[index]["osm_changes"]}', style: TextStyle(color: Colors.orangeAccent),),
        TextButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (context)=>  SubReview(task_submission_id: jsonRes[index]['task_submission_id']))), child: const Text("Suggest Changes")),
      ],
    )
     ),
  
  
//   CarouselSlider(
//   options: CarouselOptions(height: 400.0),
//   items: [0].map((i) {
//     return Builder(
//       builder: (BuildContext context) {
//         return Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[i]["task_submission_id"]}/${jsonRes[i]["task_submission_id"]}_${i+1}.png', width: MediaQuery.of(context).size.width, height: 200,);
//       },
//     );
//   }).toList(),
// )


CarouselSlider.builder(
  options: CarouselOptions(height: 300.0),
  itemCount: images_length[index],
  itemBuilder: (BuildContext context, int i, int pageViewIndex) =>
  InstaImageViewer(child: 
  Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[index]["task_submission_id"]}/${jsonRes[index]["task_submission_id"]}_${i+1}.png', width: MediaQuery.of(context).size.width, height: 200,
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
)
  //SizedBox(height: 60, child:Image.network('http://153.92.5.199:5000/images/appln/03473b44-86d9-4f90-a5f4-dd1e56efb196/03473b44-86d9-4f90-a5f4-dd1e56efb196_1.png') )
   // SizedBox(height: 200, child:Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[0]["task_submission_id"]}/${jsonRes[0]["task_submission_id"]}_1.png') )
  // Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[0]["task_submission_id"]}/${jsonRes[0]["task_submission_id"]}_0.png')
  // ListView.builder(
  //   //itemCount: images_length[index],
  //   itemCount: 1,
  //   itemBuilder: (context, value){
  //     return Text('hi');
  //    //Image.network('http://153.92.5.199:5000/images/appln/03473b44-86d9-4f90-a5f4-dd1e56efb196/03473b44-86d9-4f90-a5f4-dd1e56efb196_1.png',  width: 200, height: 200,);
  //     //Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[value]["task_submission_id"]}/${jsonRes[value]["task_submission_id"]}_${value+1}.png', width: 200, height: 200,);
  //   },
  // ),
  //Image.network('http://153.92.5.199:5000/images/appln/03473b44-86d9-4f90-a5f4-dd1e56efb196/03473b44-86d9-4f90-a5f4-dd1e56efb196_1.png',  width: 200, height: 200,),
  // ListView(scrollDirection: Axis.horizontal, 
  //  children: [
  //   Image.network('http://153.92.5.199:5000/images/appln/03473b44-86d9-4f90-a5f4-dd1e56efb196/03473b44-86d9-4f90-a5f4-dd1e56efb196_1.png',  width: 200, height: 200,)
  //  ],
  // )
  

],
    ),
  ),
);

        });  // snapshot.data  :- get your object which is pass from your downloadData() function
          }
        },
      ),
    );
  }

//     @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Previous Submissions'),
//       ),
//       body: ListView.builder(
//       itemCount: jsonRes.length,
//       itemBuilder: (context, index) {
//         return 
//         Card(
//   child: Container(
//     padding: const EdgeInsets.all(16.0),
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
  
//   Text('Review: ${jsonRes[index]["review"]}'),
//   SizedBox(height: 10.0),
//   Text('Time: ${jsonRes[index]["time"]}'),
//   SizedBox(height: 8.0),
//   Text('Status: ${jsonRes[index]["status"] ?? "N/A"}'),
//   SizedBox(height: 8.0),
//   Text('Manager Suggested Changes: ${jsonRes[index]["osm_changes"]}'),
//   SizedBox(height: 8.0),
//   Text('${jsonRes[index].toString()}'),
// //   CarouselSlider(
// //   options: CarouselOptions(height: 400.0),
// //   items: [0].map((i) {
// //     return Builder(
// //       builder: (BuildContext context) {
// //         return Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[i]["task_submission_id"]}/${jsonRes[i]["task_submission_id"]}_${i+1}.png', width: MediaQuery.of(context).size.width, height: 200,);
// //       },
// //     );
// //   }).toList(),
// // )

// CarouselSlider.builder(
//   options: CarouselOptions(height: 300.0),
//   itemCount: images_length[index],
//   itemBuilder: (BuildContext context, int i, int pageViewIndex) =>
//     Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[index]["task_submission_id"]}/${jsonRes[index]["task_submission_id"]}_${i+1}.png', width: MediaQuery.of(context).size.width, height: 200,
//     errorBuilder: (context, error, stackTrace) {
//     return Text('Error Loading');
//   },
//   frameBuilder: (BuildContext context, Widget child, int? frame, bool? wasSynchronouslyLoaded) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: child,
//     );
//   },
//   loadingBuilder: (BuildContext ctx, Widget child, ImageChunkEvent? loadingProgress) {
//         if (loadingProgress == null) {
//           return child;
//         }else {
//           return Center(
//             child: CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
//             ),
//           );
//         }
//       },   
//      ),
// )
//   //SizedBox(height: 60, child:Image.network('http://153.92.5.199:5000/images/appln/03473b44-86d9-4f90-a5f4-dd1e56efb196/03473b44-86d9-4f90-a5f4-dd1e56efb196_1.png') )
//    // SizedBox(height: 200, child:Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[0]["task_submission_id"]}/${jsonRes[0]["task_submission_id"]}_1.png') )
//   // Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[0]["task_submission_id"]}/${jsonRes[0]["task_submission_id"]}_0.png')
//   // ListView.builder(
//   //   //itemCount: images_length[index],
//   //   itemCount: 1,
//   //   itemBuilder: (context, value){
//   //     return Text('hi');
//   //    //Image.network('http://153.92.5.199:5000/images/appln/03473b44-86d9-4f90-a5f4-dd1e56efb196/03473b44-86d9-4f90-a5f4-dd1e56efb196_1.png',  width: 200, height: 200,);
//   //     //Image.network('http://153.92.5.199:5000/images/appln/${jsonRes[value]["task_submission_id"]}/${jsonRes[value]["task_submission_id"]}_${value+1}.png', width: 200, height: 200,);
//   //   },
//   // ),
//   //Image.network('http://153.92.5.199:5000/images/appln/03473b44-86d9-4f90-a5f4-dd1e56efb196/03473b44-86d9-4f90-a5f4-dd1e56efb196_1.png',  width: 200, height: 200,),
//   // ListView(scrollDirection: Axis.horizontal, 
//   //  children: [
//   //   Image.network('http://153.92.5.199:5000/images/appln/03473b44-86d9-4f90-a5f4-dd1e56efb196/03473b44-86d9-4f90-a5f4-dd1e56efb196_1.png',  width: 200, height: 200,)
//   //  ],
//   // )
  

// ],
//     ),
//   ),
// );

//         })
//     );
//   }



}
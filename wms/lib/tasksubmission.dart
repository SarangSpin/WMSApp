


// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';
// import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';
// import 'package:cloudinary_flutter/cloudinary_context.dart';
// import 'package:cloudinary_flutter/image/cld_image.dart';
// import 'package:cloudinary_url_gen/cloudinary.dart';

var uuid = const Uuid();

// ignore: must_be_immutable
class TaskSub extends StatefulWidget {
  var task_id;
  
  var vendor_id;


   TaskSub({super.key, @required this.task_id, @required this.vendor_id});

  

  @override
  // ignore: library_private_types_in_public_api
  State<TaskSub> createState() => _TaskSubState();
}

class _TaskSubState extends State<TaskSub> {


   List<XFile> _image = [];
  
    
  final imagePicker = ImagePicker();
  TextEditingController reviewController = TextEditingController();
  


  void pickImages() async{
    try{
   _image = await imagePicker.pickMultiImage(imageQuality: 40, requestFullMetadata: false);
   
   setState(() {
     
   });
   // ignore: unnecessary_null_comparison
   if (_image == null) return;

 
    }
    catch(e){
      _showMyDialog();
    }
   
  }

  @override
  void initState() {
    
    super.initState();
   
  }

  // Future<void> _uploadImage(i) async{

  //   // final url = Uri.parse('https://api.cloudinary.com/v1_1/djclfq6ns/upload');
  //   // final request = http.MultipartRequest('POST', url)
  //   //                   ..fields['upload_preset'] = 'xmppnlzd'
  //   //                   ..files.add(await http.MultipartFile.fromPath('file', _image[i].path));
  //   //                   final response = await request.send();
  //   //                   log(response.statusCode);



  // }


//  Future<void> _showTrueDialog({String type = 'Alert', String message = 'Success'}) async {
//   return showDialog<void>(
//     context: context,
//     barrierDismissible: false, // user must tap button!
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title:  Text(type),
//         content:  SingleChildScrollView(
//           child: Text(message)
//         ),
//         actions: <Widget>[
//           TextButton(
//             child: const Text('Ok'),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//         ],
//       );
//     },
//   );
// }

Future<void> _showTrueDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Submitted Successfully'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(); // Pop the dialog
                Navigator.of(context).pop(); // Pop the current page
              },
            ),
          ],
        );
      },
    );
  }

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





String submiturl = 'http://153.92.5.199:5000/tasksubmission';
var successfulsubmit = false;

void submit() async{

  showDialog(
    context: context,
    barrierDismissible: false,  // set to false if you want to force a rating
    builder: (BuildContext context) {
      return Dialog(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
            Text("Submitting"),
          ],
        ),
      );
    },
  );
  

   var requestID = http.MultipartRequest('GET', Uri.parse('http://153.92.5.199:5000/images_id?id=${uuid.v4()}'));
      var responseID = await requestID.send();


    if(reviewController.text.isNotEmpty && _image.isNotEmpty && responseID.statusCode == 200){

     
      
      var request = http.MultipartRequest('POST', Uri.parse(submiturl));

         for(int i=0; i< _image.length; i++ ){

          request.files.add(http.MultipartFile('file',
          File(_image[i].path).readAsBytes().asStream(), File(_image[i].path).lengthSync(),
          filename: _image[i].path.split("/").last));
                    
                    }

        

      var reqBody = {
        "review":reviewController.text,
        "time": DateTime.now().toString(),
        "task_id": widget.task_id,
        "vendor_id": widget.vendor_id,
        
      };

      reqBody.forEach((key, value) {
          request.fields[key] = value.toString();
        });

      var response = await request.send();


      if (response.statusCode == 200) {
        Navigator.pop(context);
        _showTrueDialog();
        successfulsubmit = true;
        
        
      } else {
        Navigator.pop(context);
        _showMyDialog();
      }

      // var response = await http.post(Uri.parse(submiturl),
      //     headers: {"Content-Type":"application/json"},
      //     body: jsonEncode(reqBody)
      // );

      // var jsonResponse = jsonDecode(response.body);
      // if(jsonResponse['status']){
      //   // ignore: use_build_context_synchronously
      //   Navigator.of(context).pop();
      // }
      
      
      
      // else{
      //   _showMyDialog();
      // }
    }else{
      _showMyDialog();
      }
  }
  




    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Task Submission'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: reviewController,
              decoration: const InputDecoration(labelText: 'Review'), 
              validator: (value) {
              if (value == null || value.isEmpty) return 'Field is required.';
              return null;
            },
            ),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: (){pickImages();},
              child: const Text('Select Images'),
            ),
            SizedBox(height: 20),

            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        children: [
                          Image(image: FileImage(File(_image[index].path)),),
                        ],
                      );
                    },
                    itemCount: _image.length,
                  ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              submit();
              if(successfulsubmit){
                Navigator.of(context).pop();
              }
            }, child: const Text('Submit'))

          ],
        ),
      ),
    );
  }



}
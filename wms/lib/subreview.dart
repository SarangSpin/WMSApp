


// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



import 'package:uuid/uuid.dart';
// import 'package:cloudinary_flutter/cloudinary_context.dart';
// import 'package:cloudinary_flutter/image/cld_image.dart';
// import 'package:cloudinary_url_gen/cloudinary.dart';

var uuid = const Uuid();

// ignore: must_be_immutable
class SubReview extends StatefulWidget {
  var task_submission_id;
  
   SubReview({super.key, @required this.task_submission_id});

  @override
  // ignore: library_private_types_in_public_api
  State<SubReview> createState() => _SubReview();
}

class _SubReview extends State<SubReview> {

  TextEditingController reviewController = TextEditingController();
  var status = 'Incomplete';
  var list = ["Incomplete", "Completed"];
  

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





String submiturl = 'http://153.92.5.199:5000/subreview';
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
  

   


    if(reviewController.text.isNotEmpty){
   

      var reqBody = {
        "review":reviewController.text,
        "status": status.toString(),
        "task_submission_id": widget.task_submission_id.toString(),
 
      };

    var response = await http.post(
      Uri.parse(submiturl),
     headers: <String, String>{
    'Content-Type':
        'application/json',
  },
      body:  jsonEncode(reqBody),
    );
    log(response.statusCode.toString());
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
            Row(
              children: [
                Text("Status: "),
                DropdownMenu(
                      initialSelection: list.first,
                onSelected: (String? value) {
                  // This is called when the user selects an item.
                  setState(() {
                    status = value!;
                  });
                },
                      dropdownMenuEntries: list.map<DropdownMenuEntry<String>>((String value) {
                                        return DropdownMenuEntry<String>(value: value, label: value);
                                      }).toList(),
      )
              ],
            ),
          
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
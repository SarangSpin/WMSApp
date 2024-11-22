import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class TaskSub extends StatefulWidget {
  final String taskId;
  final String vendorId;

  const TaskSub({
    Key? key, 
    required this.taskId, 
    required this.vendorId
  }) : super(key: key);

  @override
  State<TaskSub> createState() => _TaskSubState();
}

class _TaskSubState extends State<TaskSub> {
  List<XFile> _image = [];
  final imagePicker = ImagePicker();
  final reviewController = TextEditingController();
  var successfulsubmit = false;
  bool isLoading = false;

  void pickImages() async {
    try {
      final List<XFile> selectedImages = await imagePicker.pickMultiImage(
        imageQuality: 40, 
        requestFullMetadata: false
      );
      
      if (selectedImages.isNotEmpty) {
        setState(() {
          _image = selectedImages;
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      _showMyDialog(message: 'Failed to pick images');
    }
  }

  Future<void> _showTrueDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(type),
          content: SingleChildScrollView(
            child: Text(message)
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<Widget> _buildImageWidget(XFile image) async {
    try {
      final Uint8List bytes = await image.readAsBytes();
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Container(
            height: 100,
            color: Colors.grey[200],
            child: Center(
              child: Text('Error Loading Image'),
            ),
          );
        },
      );
    } catch (e) {
      print('Error reading image: $e');
      return Container(
        height: 100,
        color: Colors.grey[200],
        child: Center(
          child: Text('Error Loading Image'),
        ),
      );
    }
  }

  Widget _buildImagePreview(XFile image, int index) {
    return FutureBuilder<Widget>(
      future: _buildImageWidget(image),
      builder: (context, snapshot) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: snapshot.hasData
                  ? snapshot.data!
                  : Center(child: CircularProgressIndicator()),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _image.removeAt(index);
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void submit() async {
    if (reviewController.text.isEmpty || _image.isEmpty) {
      _showMyDialog(message: 'Please fill review and select images');
      return;
    }

    setState(() {
      isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Submitting"),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Get images ID first
      String imagesId = uuid.v4();
      var requestID = await http.MultipartRequest(
        'GET', 
        Uri.parse('http://153.92.5.199:5000/images_id?id=$imagesId')
      ).send();

      if (requestID.statusCode == 200) {
        // Create submission request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://153.92.5.199:5000/tasksubmission'),
        );

        // Add all images to request
        for (var image in _image) {
          final bytes = await image.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: image.name,
            ),
          );
        }

        // Add request body
        request.fields.addAll({
          "review": reviewController.text,
          "time": DateTime.now().toString(),
          "task_id": widget.taskId,
          "vendor_id": widget.vendorId,
          "images_id": imagesId,
        });

        // Send request
        var response = await request.send();
        var responseStr = await response.stream.bytesToString();
        print('Response: $responseStr');

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (response.statusCode == 200) {
          successfulsubmit = true;
          _showTrueDialog();
        } else {
          _showMyDialog(message: 'Submission failed');
        }
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        _showMyDialog(message: 'Failed to get images ID');
      }
    } catch (e) {
      print('Error in submission: $e');
      if (!mounted) return;
      Navigator.pop(context);
      _showMyDialog(message: 'Error occurred during submission');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Task Submission'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: reviewController,
                decoration: const InputDecoration(
                  labelText: 'Review',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Field is required.';
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              ElevatedButton.icon(
                onPressed: isLoading ? null : pickImages,
                icon: Icon(Icons.add_photo_alternate),
                label: Text('Select Images'),
              ),
              SizedBox(height: 20),

              if (_image.isNotEmpty) ...[
                Text(
                  'Selected Images (${_image.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _image.length,
                    itemBuilder: (context, index) {
                      return _buildImagePreview(_image[index], index);
                    },
                  ),
                ),
              ],
              
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isLoading ? 'Submitting...' : 'Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}
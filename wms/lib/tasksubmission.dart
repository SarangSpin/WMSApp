
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:wms/appUI.dart';

const uuid = Uuid();

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
  bool successfulSubmit = false;
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
      _showDialog(
        title: 'Error',
        message: 'Failed to pick images. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _showDialog({
    required String title,
    required String message,
    bool isError = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: AppTheme.headingStyle.copyWith(
              color: isError ? Colors.red : AppTheme.mainOrange,
            ),
          ),
          content: Text(
            message,
            style: AppTheme.bodyStyle,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                  color: isError ? Colors.red : AppTheme.mainOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (!isError && title == 'Success') {
                  Navigator.of(context).pop(); // Pop the current page
                }
              },
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
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.paleOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.mainOrange,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Error Loading Image',
                    style: AppTheme.bodyStyle,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.paleOrange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Error Loading Image',
            style: AppTheme.bodyStyle,
          ),
        ),
      );
    }
  }

  Widget _buildImagePreview(XFile image, int index) {
    return FutureBuilder<Widget>(
      future: _buildImageWidget(image),
      builder: (context, snapshot) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: snapshot.hasData
                    ? snapshot.data!
                    : const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.mainOrange,
                          ),
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _image.removeAt(index);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> submit() async {
    if (reviewController.text.isEmpty || _image.isEmpty) {
      _showDialog(
        title: 'Error',
        message: 'Please provide both review and images before submitting.',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mainOrange),
                ),
                const SizedBox(width: 20),
                Text(
                  "Submitting...",
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      String imagesId = uuid.v4();
      var requestID = await http.MultipartRequest(
        'GET', 
        Uri.parse('http://153.92.5.199:5000/images_id?id=$imagesId')
      ).send();

      if (requestID.statusCode == 200) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://153.92.5.199:5000/tasksubmission'),
        );

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

        request.fields.addAll({
          "review": reviewController.text,
          "time": DateTime.now().toString(),
          "task_id": widget.taskId,
          "vendor_id": widget.vendorId,
          "images_id": imagesId,
        });

        var response = await request.send();
        var responseStr = await response.stream.bytesToString();

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (response.statusCode == 200) {
          successfulSubmit = true;
          _showDialog(
            title: 'Success',
            message: 'Your submission has been sent successfully.',
          );
        } else {
          throw Exception('Submission failed');
        }
      } else {
        throw Exception('Failed to get images ID');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showDialog(
        title: 'Error',
        message: 'Failed to submit. Please try again.',
        isError: true,
      );
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
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: AppTheme.mainOrange,
        scaffoldBackgroundColor: AppTheme.background,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.mainOrange,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Submit Task',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Review Details',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reviewController,
                        maxLines: 4,
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Write your review',
                          alignLabelWithHint: true,
                          labelStyle: AppTheme.bodyStyle.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.cardBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.mainOrange,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.cardBorder,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Images',
                            style: AppTheme.headingStyle,
                          ),
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : pickImages,
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              size: 20,
                            ),
                            label: const Text('Add Images'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.mainOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_image.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.cardBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            scrollDirection: Axis.horizontal,
                            itemCount: _image.length,
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 200,
                                child: _buildImagePreview(_image[index], index),
                              );
                            },
                          ),
                        ),
                      ] else
                        Container(
                          height: 150,
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.paleOrange,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.mainOrange.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: AppTheme.mainOrange.withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No images selected',
                                  style: AppTheme.bodyStyle.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : submit,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                             ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      isLoading ? 'Submitting...' : 'Submit Task',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mainOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
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
                            
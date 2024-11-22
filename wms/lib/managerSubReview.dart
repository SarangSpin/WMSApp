import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:wms/appUI.dart';
import 'package:wms/subreview.dart';

// ignore: must_be_immutable
class ManagerSubView extends StatefulWidget {
  final String task_id;
  String finish;

  ManagerSubView({
    Key? key,
    required this.task_id,
    this.finish = 'Incomplete',
  }) : super(key: key);

  @override
  State<ManagerSubView> createState() => _ManagerSubViewState();
}

class _ManagerSubViewState extends State<ManagerSubView> {
  List<dynamic> jsonRes = [];
  List<dynamic> images_length = [];
  List<Color> color = [];
  TextEditingController reviewController = TextEditingController();
  bool isLoading = false;
    late Future<List<dynamic>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _submissionsFuture = managerSubViewDash();
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  Future<void> _refreshSubmissions() async {
    setState(() {
      _submissionsFuture = managerSubViewDash();
    });
  }

  Future<List<dynamic>> managerSubViewDash() async {
    try {
      setState(() {
        isLoading = true;
      });

      String url = 'http://153.92.5.199:5000/managersubview?task_id=${widget.task_id}';
      var response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load submissions');
      }

      jsonRes = jsonDecode(response.body)['data'];
      images_length.clear();
      color.clear();

      for (var i = 0; i < jsonRes.length; i++) {
        // Set status colors
        color.add(
          jsonRes[i]["status"] == "Incomplete"
              ? Colors.red
              : Colors.green,
        );

        if (jsonRes[i]["status"] != "Incomplete") {
          widget.finish = 'Completed';
        }

        // Fetch images for each submission
        String imgUrl =
            'http://153.92.5.199:5000/imagesubview?task_submission_id=${jsonRes[i]["task_submission_id"]}';
        var imgResponse = await http.get(
          Uri.parse(imgUrl),
          headers: {"Content-Type": "application/json"},
        );

        if (imgResponse.statusCode != 200) {
          throw Exception('Failed to load images for submission ${i + 1}');
        }

        images_length.add(jsonDecode(imgResponse.body)['data']);
      }

      // Update task status if all submissions are completed
      if (widget.finish == 'Completed') {
        String url2 = 'http://153.92.5.199:5000/taskfinish?task_id=${widget.task_id}';
        await http.get(
          Uri.parse(url2),
          headers: {"Content-Type": "application/json"},
        );
      }

      return images_length;
    } catch (e) {
      log('Error in managerSubViewDash: $e');
      rethrow;
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
            'Task Submissions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: RefreshIndicator(
          color: AppTheme.mainOrange,
          onRefresh: _refreshSubmissions,
          child: FutureBuilder<List<dynamic>>(
            future: _submissionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mainOrange),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: AppTheme.bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.mainOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (jsonRes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: AppTheme.mainOrange.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Submissions Yet',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'There are no submissions to review',
                        style: AppTheme.bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jsonRes.length,
                itemBuilder: (context, index) => _buildSubmissionCard(index),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(int index) {
    final submission = jsonRes[index];
    final isIncomplete = submission["status"] == "Incomplete";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(
          color: isIncomplete ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isIncomplete
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  isIncomplete ? Icons.error_outline : Icons.check_circle_outline,
                  color: isIncomplete ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  isIncomplete ? 'Incomplete' : 'Completed',
                  style: AppTheme.subheadingStyle.copyWith(
                    color: isIncomplete ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  submission["time"].toString().substring(0, 10),
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(
                  'Review',
                  submission["review"],
                  icon: Icons.rate_review,
                ),
                if (submission["osm_changes"]?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    'Manager Suggestions',
                    submission["osm_changes"],
                    icon: Icons.comment,
                    textColor: Colors.orange,
                  ),
                ],
                if (isIncomplete) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubReview(
                              task_submission_id: submission['task_submission_id'],
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("Suggest Changes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mainOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
                if (images_length[index] > 0) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Submission Images',
                    style: AppTheme.subheadingStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildImageCarousel(index, submission),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String value, {
    IconData? icon,
    Color? textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: AppTheme.mainOrange,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.subheadingStyle.copyWith(
                  color: textColor ?? AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel(int index, Map<String, dynamic> submission) {
    return CarouselSlider.builder(
      options: CarouselOptions(
        height: 250,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        viewportFraction: 0.85,
        aspectRatio: 16 / 9,
      ),
      itemCount: images_length[index],
      itemBuilder: (context, imageIndex, pageViewIndex) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InstaImageViewer(
              child: Image.network(
                'http://153.92.5.199:5000/images/appln/${submission["task_submission_id"]}/${submission["task_submission_id"]}_${imageIndex + 1}.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.paleOrange,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.mainOrange,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Image not available',
                            style: AppTheme.bodyStyle,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.mainOrange,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:wms/login.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:wms/appUI.dart';
import 'package:wms/tasksubmission.dart';
import 'package:wms/tasksubview.dart';

class Vendor extends StatefulWidget {
  final String token;
  final String vendor;
  
  const Vendor({
    Key? key, 
    required this.token, 
    required this.vendor,
  }) : super(key: key);

  @override
  State<Vendor> createState() => _VendorState();
}

class _VendorState extends State<Vendor> {
  List<dynamic> jsonRes = [];
  late var vendorResponse;
  bool isLoading = false;
  late Future<List<dynamic>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    vendorResponse = jsonDecode(widget.vendor);
    _tasksFuture = taskDash();
  }

  Future<List<dynamic>> taskDash() async {
    try {
      setState(() {
        isLoading = true;
      });

      vendorResponse = jsonDecode(widget.vendor);
      final url = 'http://153.92.5.199:5000/vendorTask?id=${vendorResponse["vendor_id"]}';

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        jsonRes = data['data'] ?? [];
        return jsonRes;
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      log('Error fetching tasks: $e');
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshTasks() async {
    setState(() {
       _tasksFuture = taskDash();
    });
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final hasManagerReview = task['latest_review'] != null && 
                           task['latest_review'].toString().isNotEmpty;
    final isIncomplete = task["status"] == 'Incomplete';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(
          color: isIncomplete 
              ? AppTheme.mainOrange.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isIncomplete
                  ? AppTheme.paleOrange
                  : Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isIncomplete
                          ? Icons.pending_outlined
                          : Icons.check_circle,
                      color: isIncomplete
                          ? AppTheme.mainOrange
                          : Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task["task_name"],
                        style: AppTheme.headingStyle.copyWith(fontSize: 18),
                      ),
                    ),
                    if (hasManagerReview)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.mainOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.mainOrange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.comment,
                              size: 16,
                              color: AppTheme.mainOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Has Review',
                              style: AppTheme.captionStyle.copyWith(
                                color: AppTheme.mainOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Sub-Event',
                  task["name"],
                  Icons.event_note,
                ),
                if (task["description_"] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Description',
                    task["description_"],
                    Icons.description,
                  ),
                ],
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Deadline',
                  task["deadline"],
                  Icons.schedule,
                  valueColor: Colors.red,
                ),
                if (task["type"] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Type',
                    task["type"],
                    Icons.category,
                  ),
                ],
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Time Period',
                  '${task["start_time"]} - ${task["end_time"]}',
                  Icons.access_time,
                  valueColor: AppTheme.mainOrange,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Event Date',
                  task["event_date"].toString().substring(0, 10),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isIncomplete
                          ? Icons.pending_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                      color: isIncomplete ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ',
                      style: AppTheme.bodyStyle,
                    ),
                    Text(
                      task["status"],
                      style: AppTheme.subheadingStyle.copyWith(
                        color: isIncomplete ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Manager Review Section
          if (hasManagerReview)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.paleOrange,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.mainOrange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.comment,
                        size: 20,
                        color: AppTheme.mainOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Manager\'s Suggestions',
                        style: AppTheme.subheadingStyle.copyWith(
                          color: AppTheme.mainOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task['latest_review'],
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.cardBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                if (isIncomplete)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.upload_file,
                      label: "Make Submission",
                      isPrimary: true,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskSub(
                              taskId: task["task_id"],
                              vendorId: vendorResponse["vendor_id"],
                            ),
                          ),
                        ).then((_) => _refreshTasks());
                      },
                    ),
                  ),
                if (isIncomplete)
                  const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.visibility,
                    label: "View Submissions",
                    isPrimary: false,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskSubView(
                            task_id: task["task_id"],
                            vendor_id: vendorResponse["vendor_id"],
                          ),
                        ),
                      ).then((_) => _refreshTasks());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.mainOrange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: AppTheme.bodyStyle,
                ),
                TextSpan(
                  text: value,
                  style: AppTheme.subheadingStyle.copyWith(
                    color: valueColor ?? AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.mainOrange : Colors.grey[200],
        foregroundColor: isPrimary ? Colors.white : AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isPrimary ? 2 : 0,
      ),
    );
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
          title: Column(
            children: [
              const Text(
                'Vendor Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                vendorResponse['vendor_name'],
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              ),
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: AppTheme.mainOrange,
          onRefresh: _refreshTasks,
          child: FutureBuilder<List<dynamic>>(
            future: _tasksFuture,
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
                        'No Tasks Assigned',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You don\'t have any tasks assigned yet',
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: jsonRes.length,
                itemBuilder: (context, index) => _buildTaskCard(jsonRes[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}
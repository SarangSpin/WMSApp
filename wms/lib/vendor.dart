
import 'package:flutter/material.dart';
import 'package:wms/login.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    vendorResponse = jsonDecode(widget.vendor);
  }

  Future<List<dynamic>> taskDash() async {
    try {
      vendorResponse = jsonDecode(widget.vendor);
      final url = 'http://153.92.5.199:5000/vendorTask?id=${vendorResponse["vendor_id"]}';

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        jsonRes = data['data'] ?? [];
        log(response.body);
        return jsonRes;
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      log('Error fetching tasks: $e');
      return [];
    }
  }

  Future<void> _refreshTasks() async {
    setState(() {});
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final hasManagerReview = task['latest_review'] != null && 
                           task['latest_review'].toString().isNotEmpty;
    final isIncomplete = task["status"] == 'Incomplete';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Task Name: ${task["task_name"]}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (hasManagerReview)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Has Review',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text('Sub - Event: ${task["name"]}'),
            const SizedBox(height: 8.0),
            if (task["description_"] != null) ...[
              Text('Description: ${task["description_"]}'),
              const SizedBox(height: 8.0),
            ],
            Text(
              'Deadline: ${task["deadline"]}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8.0),
            if (task["type"] != null) ...[
              Text('Type: ${task["type"]}'),
              const SizedBox(height: 8.0),
            ],
            Text('Start Time: ${task["start_time"]}',
                style: const TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 8.0),
            Text('End Time: ${task["end_time"]}',
                style: const TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 8.0),
            Text(
              'Event Date: ${task["event_date"].toString().substring(0, 10)}',
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Text('Status: '),
                Text(
                  task["status"],
                  style: TextStyle(
                    color: task["status"] == 'Completed' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Manager Review Section
            if (hasManagerReview) ...[
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 18,
                          color: Colors.orange[700],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Manager\'s Suggestions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      task['latest_review'],
                      style: TextStyle(
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16.0),
            Row(
              children: [
                if (isIncomplete)
                  Expanded(
                    child: ElevatedButton.icon(
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
                      icon: Icon(Icons.upload_file),
                      label: Text("Make Submission"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (isIncomplete)
                  SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
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
                    icon: Icon(Icons.visibility),
                    label: Text("View Submissions"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Vendor: ${vendorResponse['vendor_name']}'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
            ),
            child: const Text("Logout"),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: FutureBuilder<List<dynamic>>(
          future: taskDash(),
          builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (jsonRes.isEmpty) {
              return Center(
                child: Text(
                  'No tasks assigned',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: jsonRes.length,
              itemBuilder: (context, index) => _buildTaskCard(jsonRes[index]),
            );
          },
        ),
      ),
    );
  }
}

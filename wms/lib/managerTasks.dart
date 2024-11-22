import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wms/managerSubReview.dart';

class ManagerTasks extends StatefulWidget {
  final String id;
  final String event;

  const ManagerTasks({
    Key? key,
    required this.id,
    required this.event,
  }) : super(key: key);

  @override
  State<ManagerTasks> createState() => _ManagerTasksState();
}

class _ManagerTasksState extends State<ManagerTasks> {
  List<dynamic> jsonRes = [];

  Future<List<dynamic>> fetchTasks() async {
    final url = 'http://153.92.5.199:5000/tasklist?id=${widget.id}';
    final response = await http.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);
    jsonRes = data['data'];
    print('Tasks data: $jsonRes'); // For debugging
    return jsonRes;
  }

  Future<void> _refreshTasks() async {
    await fetchTasks();
    setState(() {});
  }

  Future<void> markSubmissionsAsViewed(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('http://153.92.5.199:5000/markSubmissionsAsViewed'),
        body: {'task_id': taskId},
      );
      
      final data = jsonDecode(response.body);
      print('Marked as viewed response: $data'); // For debugging
      
      // Refresh the task list to update the unread count
      await _refreshTasks();
    } catch (e) {
      print('Error marking submissions as viewed: $e');
    }
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final unreadCount = task['unread_submissions'] ?? 0;
    final totalCount = task['total_submissions'] ?? 0;
    final hasUnreadSubmissions = unreadCount > 0;

    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    task["task_name"],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (hasUnreadSubmissions)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text('Sub-Event: ${task["name"]}'),
                Text('Vendor: ${task["vendor"]}'),
                Text(
                  'Deadline: ${task["deadline"]}',
                  style: TextStyle(color: Colors.red),
                ),
                Row(
                  children: [
                    Text('Status: '),
                    Text(
                      task["status"],
                      style: TextStyle(
                        color: task["status"] == 'Completed' 
                          ? Colors.green 
                          : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (totalCount > 0)
                  Text(
                    'Total Submissions: $totalCount',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (hasUnreadSubmissions) {
                        await markSubmissionsAsViewed(task["task_id"]);
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManagerSubView(
                            task_id: task["task_id"],
                          ),
                        ),
                      ).then((_) => _refreshTasks());
                    },
                    icon: Icon(
                      hasUnreadSubmissions 
                        ? Icons.mark_email_unread 
                        : Icons.visibility,
                    ),
                    label: Text(
                      hasUnreadSubmissions
                        ? "View New Submissions"
                        : "View Submissions"
                    ),
                    style: hasUnreadSubmissions
                      ? ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        )
                      : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('${widget.event}: Tasks'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: FutureBuilder<List<dynamic>>(
          future: fetchTasks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (jsonRes.isEmpty) {
              return Center(child: Text('No tasks found'));
            }

            return ListView.builder(
              itemCount: jsonRes.length,
              itemBuilder: (context, index) => _buildTaskCard(jsonRes[index]),
            );
          },
        ),
      ),
    );
  }
}
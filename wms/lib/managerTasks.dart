
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wms/appUI.dart';
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
  bool isLoading = false;
  late Future<List<dynamic>> _tasksFuture;


  @override
  void initState() {
    super.initState();
    // Initialize the future once
    _tasksFuture = fetchTasks();
  }


  Future<List<dynamic>> fetchTasks() async {
    try {
      setState(() {
        isLoading = true;
      });

      final url = 'http://153.92.5.199:5000/tasklist?id=${widget.id}';
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        jsonRes = data['data'];
        return jsonRes;
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Error: $e');
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
      _tasksFuture = fetchTasks();
    });
  }

  Future<void> markSubmissionsAsViewed(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('http://153.92.5.199:5000/markSubmissionsAsViewed'),
        body: {'task_id': taskId},
      );
      
      if (response.statusCode == 200) {
        await _refreshTasks();
      }
    } catch (e) {
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating submissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final unreadCount = task['unread_submissions'] ?? 0;
    final totalCount = task['total_submissions'] ?? 0;
    final hasUnreadSubmissions = unreadCount > 0;
    final isCompleted = task["status"] == 'Completed';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(
          color: isCompleted 
              ? Colors.green.withOpacity(0.3)
              : hasUnreadSubmissions 
                  ? AppTheme.mainOrange.withOpacity(0.5)
                  : AppTheme.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.1)
                  : hasUnreadSubmissions
                      ? AppTheme.paleOrange
                      : Colors.transparent,
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
                      isCompleted
                          ? Icons.check_circle
                          : Icons.assignment,
                      color: isCompleted
                          ? Colors.green
                          : AppTheme.mainOrange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task["task_name"],
                        style: AppTheme.headingStyle.copyWith(fontSize: 18),
                      ),
                    ),
                    if (hasUnreadSubmissions)
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
                              Icons.notifications_active,
                              size: 16,
                              color: AppTheme.mainOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$unreadCount new',
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
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Vendor',
                  task["vendor"],
                  Icons.business,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Deadline',
                  task["deadline"],
                  Icons.schedule,
                  valueColor: Colors.red,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle_outline
                          : Icons.pending_outlined,
                      size: 18,
                      color: isCompleted
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ',
                      style: AppTheme.bodyStyle,
                    ),
                    Text(
                      task["status"],
                      style: AppTheme.subheadingStyle.copyWith(
                        color: isCompleted ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (totalCount > 0) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Total Submissions',
                    totalCount.toString(),
                    Icons.folder,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.cardBorder,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
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
                  size: 20,
                ),
                label: Text(
                  hasUnreadSubmissions
                    ? "View New Submissions"
                    : "View Submissions",
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasUnreadSubmissions
                      ? AppTheme.mainOrange
                      : Colors.grey[200],
                  foregroundColor: hasUnreadSubmissions
                      ? Colors.white
                      : AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
        Text(
          '$label: ',
          style: AppTheme.bodyStyle,
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.subheadingStyle.copyWith(
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
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
                'Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.event,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
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
                        'No Tasks Found',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'There are no tasks assigned to this event',
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

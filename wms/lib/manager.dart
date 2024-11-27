
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wms/appUI.dart';
import 'package:wms/login.dart';
import 'package:wms/managerEvent.dart';

// Theme constants that can be exported to a separate file


class Manager extends StatefulWidget {
  final String token;
  final String manager;
   
  const Manager({
    Key? key, 
    required this.token, 
    required this.manager
  }) : super(key: key);

  @override
  State<Manager> createState() => _ManagerState();
}

class _ManagerState extends State<Manager> with TickerProviderStateMixin {
  var mainData;
  late TabController _controller;
  List<dynamic> jsonResponse = [];

  @override
  void initState() {
    super.initState();
    initSharedPref();
    _controller = TabController(length: 2, vsync: this);
  }

  void initSharedPref() async {
    mainData = await SharedPreferences.getInstance();
  }

  Future<List<dynamic>> managerDash() async {
    try {
      var managerResponse = jsonDecode(widget.manager);
      String url = 'http://153.92.5.199:5000/managerDash?osm=${managerResponse['employee_id']}';
      var response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      var data = jsonDecode(response.body);
      jsonResponse = data['data'] ?? [];
      return jsonResponse;
    } catch (e) {
      log("Error fetching manager dash: $e");
      rethrow;
    }
  }

  Future<void> _handleRefresh() async {
    await managerDash();
    if (mounted) setState(() {});
  }

  Widget _buildEmptyState(bool isAssigned) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAssigned ? Icons.assignment_outlined : Icons.assignment_turned_in,
              size: 64,
              color: AppTheme.mainOrange.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isAssigned ? 'No Pending Assignments' : 'No Completed Events',
              style: AppTheme.headingStyle.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAssigned ? 'All tasks are completed' : 'Your completed events will appear here',
              style: AppTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isAssigned) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.cardDecoration.copyWith(
        color: isAssigned 
            ? AppTheme.paleOrange.withOpacity(0.3) 
            : Colors.green[50]?.withOpacity(0.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManagerEvent(event: event),
            ),
          ).then((_) => _handleRefresh()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isAssigned 
                            ? AppTheme.mainOrange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isAssigned ? Icons.event : Icons.event_available,
                        color: isAssigned ? AppTheme.mainOrange : Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event['event_'],
                        style: AppTheme.headingStyle.copyWith(fontSize: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isAssigned 
                            ? AppTheme.mainOrange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAssigned 
                              ? AppTheme.mainOrange.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isAssigned ? 'PENDING' : 'COMPLETED',
                        style: AppTheme.captionStyle.copyWith(
                          color: isAssigned ? AppTheme.mainOrange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Population',
                          style: AppTheme.bodyStyle,
                        ),
                        Text(
                          event['population'].toString(),
                          style: AppTheme.subheadingStyle,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Deadline',
                          style: AppTheme.bodyStyle,
                        ),
                        Text(
                          event['start_date'].toString().substring(0, 10),
                          style: AppTheme.subheadingStyle.copyWith(
                            color: isAssigned ? Colors.red : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final managerData = jsonDecode(widget.manager);
    
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: AppTheme.mainOrange,
        scaffoldBackgroundColor: AppTheme.background,
      ),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.mainOrange,
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                'Manager Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${managerData['first_name']} ${managerData['last_name']}',
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
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _controller,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                text: "Assigned",
                icon: Icon(Icons.assignment),
              ),
              Tab(
                text: "Completed",
                icon: Icon(Icons.assignment_turned_in),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          color: AppTheme.mainOrange,
          onRefresh: _handleRefresh,
          child: FutureBuilder<List<dynamic>>(
            future: managerDash(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: AppTheme.bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _handleRefresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.mainOrange,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return TabBarView(
                controller: _controller,
                children: [
                  _buildEventsList(true),
                  _buildEventsList(false),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(bool isAssigned) {
    final filteredEvents = jsonResponse.where(
      (event) => event['status'] == (isAssigned ? 'assigned' : 'completed')
    ).toList();

    if (filteredEvents.isEmpty) {
      return _buildEmptyState(isAssigned);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) => _buildEventCard(
        filteredEvents[index],
        isAssigned,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

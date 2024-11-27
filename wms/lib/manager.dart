
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wms/login.dart';
import 'package:wms/managerEvent.dart';

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
      log("Manager Data: ${widget.manager}");
      log("OSM ID: ${managerResponse['employee_id']}");
      log("Response: ${response.body}");
      
      return jsonResponse;
    } catch (e) {
      log("Error fetching manager dash: $e");
      rethrow;
    }
  }

  Future<void> _handleRefresh() async {
    await managerDash();
    if (mounted) {
      setState(() {});
    }
  }

  List<dynamic> _getFilteredEvents(String status) {
    return jsonResponse.where((event) => 
      event['status'].toString().toLowerCase() == status.toLowerCase()
    ).toList();
  }

  Widget _buildEmptyState(bool isAssigned) {
    return Center(
      child: Text(
        isAssigned ? 'No Pending Assignments' : 'No Completed Assignments',
        style: TextStyle(fontSize: 30),
      ),
    );
  }

  Widget _buildEventsList(bool isAssigned) {
    final filteredEvents = _getFilteredEvents(isAssigned ? 'assigned' : 'completed');
    
    if (filteredEvents.isEmpty) {
      return _buildEmptyState(isAssigned);
    }

    return ListView.builder(
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return Card(
          child: ListTile(
            title: Text('Event: ${event['event_']}'),
            subtitle: Text('Population: ${event['population']}'),
            trailing: Text(
              'Deadline: ${event['start_date'].toString().substring(0, 10)}',
              style: TextStyle(
                color: isAssigned ? Colors.red : Colors.black,
                fontSize: 18,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManagerEvent(event: event),
              ),
            ).then((_) => _handleRefresh()), // Refresh on return
            tileColor: isAssigned ? Colors.orange[100] : Colors.lightGreen,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final managerData = jsonDecode(widget.manager);
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Manager: ${managerData['first_name']} ${managerData['last_name']}'
        ),
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
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: "Assigned"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: FutureBuilder<List<dynamic>>(
          future: managerDash(),
          builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleRefresh,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _controller,
              children: [
                _buildEventsList(true),  // Assigned events
                _buildEventsList(false), // Completed events
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

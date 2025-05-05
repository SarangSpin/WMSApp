// manage_users.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wmsapp/add_edit_user_page.dart';
import 'package:wmsapp/appUI.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final response = await http.get(
      Uri.parse('http://153.92.5.199:5000/admin/users'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load users.');
      }
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  Future<void> _addUser(BuildContext context) async {
    final newUser = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditUserPage(isEditing: false)),
    );

    if (newUser != null) {
      final registrationData = {
        'username': newUser['first_name'].toLowerCase() + newUser['last_name'].toLowerCase(),
        'password': newUser['password'],
        'email': newUser['email'],
        'first_name': newUser['first_name'],
        'last_name': newUser['last_name'],
        'phone': newUser['phone'],
        'address': newUser['address'],
        'designation': newUser['designation'],
        'admin_status': newUser['admin_status'],
      };

      try {
        final response = await http.post(
          Uri.parse('http://153.92.5.199:5000/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(registrationData),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New user added successfully!')),
            );
            await _refreshUsers(); // Refresh the user list
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Failed to add user.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to the server.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  Future<void> _editUser(BuildContext context, Map<String, dynamic> userData) async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditUserPage(isEditing: true, userData: userData)),
    );

    if (updatedUser != null) {
      try {
        final response = await http.post(
          Uri.parse('http://153.92.5.199:5000/admin/edituser'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updatedUser),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User details updated successfully!')),
            );
            await _refreshUsers(); // Refresh the user list
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Failed to update user.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to Connect to the server.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(BuildContext context, String employeeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse('http://153.92.5.199:5000/admin/deluser'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'employee_id': employeeId}),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User deleted successfully!')),
            );
            await _refreshUsers(); // Refresh the user list
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Failed to delete user.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to the server.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
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
          title: const Text(
            'Manage Users',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mainOrange),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No users created yet.', style: AppTheme.bodyStyle),
              );
            } else if (snapshot.hasData) {
              final users = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _refreshUsers,
                color: AppTheme.mainOrange,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: const Icon(Icons.person, size: 32, color: AppTheme.mainOrange),
                          title: Text('${user['first_name']} ${user['last_name']}', style: AppTheme.subheadingStyle),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'], style: AppTheme.bodyStyle),
                              Text('Designation: ${user['designation']}', style: AppTheme.captionStyle),
                              Text('Phone: ${user['phone'] ?? 'N/A'}', style: AppTheme.captionStyle),
                              Text('Admin: ${user['admin_status']}', style: AppTheme.captionStyle),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editUser(context, user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteUser(context, user['employee_id']),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.mainOrange,
          foregroundColor: Colors.white,
          onPressed: () => _addUser(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
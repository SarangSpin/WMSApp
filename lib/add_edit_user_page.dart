// add_edit_user_page.dart
import 'package:flutter/material.dart';
import 'package:wmsapp/appUI.dart';

class AddEditUserPage extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? userData;

  const AddEditUserPage({super.key, required this.isEditing, this.userData});

  @override
  State<AddEditUserPage> createState() => _AddEditUserPageState();
}

class _AddEditUserPageState extends State<AddEditUserPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  String? _designation;
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _repeatPasswordController = TextEditingController();
  bool? _isAdmin;

  List<String> _designations = ['planner', 'osm', 'gm']; // Based on your data
  List<bool> _adminOptions = [true, false];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.userData != null) {
      _firstNameController.text = widget.userData!['first_name'] ?? '';
      _lastNameController.text = widget.userData!['last_name'] ?? '';
      _emailController.text = widget.userData!['email'] ?? '';
      _phoneController.text = widget.userData!['phone']?.toString() ?? '';
      _addressController.text = widget.userData!['address'] ?? '';
      _designation = widget.userData!['designation'];
      _isAdmin = widget.userData!['admin_status'] == 'true';
    } else {
      _isAdmin = false; // Default for new users
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
          title: Text(
            widget.isEditing ? 'Edit User' : 'Add New User',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                    border: OutlineInputBorder(),
                  ),
                  value: _designation,
                  items: _designations.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _designation = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a designation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (!widget.isEditing) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _repeatPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Repeat Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please repeat the password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    const Text('Admin:'),
                    const SizedBox(width: 16),
                    ..._adminOptions.map((bool value) {
                      return Row(
                        children: [
                          Radio<bool>(
                            value: value,
                            groupValue: _isAdmin,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _isAdmin = newValue;
                              });
                            },
                          ),
                          Text(value ? 'Yes' : 'No'),
                          const SizedBox(width: 16),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mainOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final userData = {
                            'first_name': _firstNameController.text,
                            'last_name': _lastNameController.text,
                            'email': _emailController.text,
                            'phone': _phoneController.text,
                            'address': _addressController.text,
                            'designation': _designation,
                            'admin_status': _isAdmin.toString(),
                          };
                          if (!widget.isEditing) {
                            userData['password'] = _passwordController.text;
                          } else {
                            userData['employee_id'] = widget.userData!['employee_id']; // Add employee_id for editing
                          }
                          print('User Data to Return: $userData'); // Debugging log
                          Navigator.pop(context, userData);
                        }
                      },
                  child: Text(
                    widget.isEditing ? 'Update User' : 'Add User',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
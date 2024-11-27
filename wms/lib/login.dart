
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms/appUI.dart';
import 'package:wms/manager.dart';
import 'package:wms/vendor.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isNotValidate = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    initSharedPref();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _showDialog({
    String title = 'Alert',
    String message = 'Error occurred',
    bool isError = true,
  }) async {
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> loginUser() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        _isNotValidate = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isNotValidate = false;
    });

    try {
      var reqBody = {
        "username": usernameController.text,
        "password": passwordController.text
      };

      var response = await http.post(
        Uri.parse('http://153.92.5.199:5000/applogin'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status']) {
        var myToken = jsonResponse['token'];
        await prefs.setString('token', myToken);
        await prefs.setString('designation', jsonResponse['designation']);
        await prefs.setString('user', jsonResponse['user']);

        if (!mounted) return;

        if (jsonResponse['designation'] == "osm") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => Manager(
                token: myToken,
                manager: jsonResponse['user'],
              ),
            ),
            (Route<dynamic> route) => false,
          );
        } else if (jsonResponse['designation'] == "vendor") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => Vendor(
                token: myToken,
                vendor: jsonResponse['user'],
              ),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        await _showDialog(
          title: 'Login Failed',
          message: 'Invalid username or password. Please try again.',
        );
      }
    } catch (e) {
      await _showDialog(
        title: 'Error',
        message: 'Failed to connect to server. Please check your connection.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Logo or App Name
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.mainOrange.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.business_center,
                      size: 64,
                      color: AppTheme.mainOrange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    style: AppTheme.headingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Username Field
                  _buildTextField(
                    controller: usernameController,
                    labelText: 'Username',
                    prefixIcon: Icons.person_outline,
                    errorText:
                        _isNotValidate && usernameController.text.isEmpty
                            ? "Username is required"
                            : null,
                  ),
                  const SizedBox(height: 16),
                  // Password Field
                  _buildTextField(
                    controller: passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    errorText:
                        _isNotValidate && passwordController.text.isEmpty
                            ? "Password is required"
                            : null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mainOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: AppTheme.bodyStyle.copyWith(
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondary,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: AppTheme.mainOrange,
          ),
          suffixIcon: suffixIcon,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.cardBorder,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.mainOrange,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.shade300,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red.shade300,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

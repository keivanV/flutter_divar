import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ورود ادمین', style: TextStyle(fontFamily: 'Vazir')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'نام کاربری',
                    labelStyle: TextStyle(fontFamily: 'Vazir'),
                    border: OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Vazir'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'رمز عبور',
                    labelStyle: TextStyle(fontFamily: 'Vazir'),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Vazir'),
                ),
                const SizedBox(height: 16),
                if (authProvider.isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () async {
                      await authProvider.adminLogin(
                        _usernameController.text,
                        _passwordController.text,
                      );
                      if (authProvider.errorMessage == null) {
                        // Only navigate if login is successful
                        Navigator.pushReplacementNamed(
                            context, '/admin_dashboard');
                      } else {
                        // Show SnackBar with error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(fontFamily: 'Vazir'),
                              textDirection: TextDirection.rtl,
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Text(
                      'ورود',
                      style: TextStyle(fontFamily: 'Vazir'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
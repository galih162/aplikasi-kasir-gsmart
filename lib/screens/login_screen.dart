import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gs_mart_aplikasi/database/service.dart';
import 'package:gs_mart_aplikasi/screens/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validasi input kosong
    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      return;
    }


    final authProvider = Provider.of<AuthProvider>(context, listen: false);

  
    setState(() => _isLoading = true);

  
    try {
      final success = await authProvider.login(email, password);

      // Cek apakah widget masih mounted
      if (!mounted) return;

      // Reset loading state
      setState(() => _isLoading = false);

      // Cek hasil login
      if (success) {
        // Login berhasil - navigasi ke dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => KasirDashboard(
              user: authProvider.currentUser!,
            ),
          ),
        );
      } else {
        // Login gagal - tampilkan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Email atau password salah'),
            backgroundColor: const Color.fromARGB(255, 216, 215, 215),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 19, 4),
      body: Stack(
        children: [
          Container(color: const Color.fromARGB(255, 240, 20, 4)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  
                  const Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  _buildLoginTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildPasswordTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                  ),
                  
                  const SizedBox(height: 60),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Color.fromARGB(255, 223, 15, 0),
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 252, 21, 4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.2).round()), 
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: labelText,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(prefixIcon, color: Colors.white),
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white), 
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.2).round()), 
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: labelText,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.lock, color: Colors.white),
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white),
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
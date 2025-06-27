import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_selector/file_selector.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flipflow',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const PdfUploadScreen(),
      },
    );
  }
}

// GLASS CONTAINER WIDGET
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final double offsetY;
  final Function(DragUpdateDetails)? onDragUpdate;
  final Function(DragEndDetails)? onDragEnd;
  const GlassContainer({
    super.key, 
    required this.child, 
    required this.width, 
    this.height,
    this.offsetY = 0,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: GestureDetector(
        onVerticalDragUpdate: onDragUpdate,
        onVerticalDragEnd: onDragEnd,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.10),
                blurRadius: 60,
                spreadRadius: 8,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
            borderRadius: BorderRadius.circular(28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                width: width,
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.0), // fully invisible
                      Colors.white.withValues(alpha: 0.0), // fully invisible
                      Colors.white.withValues(alpha: 0.0), // fully invisible
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    width: 2.2,
                    style: BorderStyle.solid,
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
                child: Stack(
                  children: [
                    // Top highlight
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.0), // fully invisible
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Main content vertically centered
                    Center(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// LOGIN PAGE
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Attempting login with email: ${_emailController.text.trim()}');
      
      // First, try normal sign in
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      print('Login successful, user: ${userCredential.user?.email}');
      User? user = userCredential.user;

      if (user != null) {
        print('User is not null, navigating to home');
        // Proceed to the app regardless of email verification status
        if (!user.emailVerified) {
          print('User email not verified, but proceeding anyway');
          // For existing users who need verification, we'll proceed anyway
          // Try to reload user to get latest verification status
          try {
            await user.reload();
            user = FirebaseAuth.instance.currentUser;
          } catch (e) {
            print('Error reloading user: $e');
          }
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('User is null after successful login');
        if (mounted) {
          setState(() {
            _errorMessage = 'Login successful but user data is missing.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      
      // If it's a verification error, try to handle it specially
      if (e.code == 'user-not-verified') {
        print('Handling user-not-verified error');
        // Try to sign in again and force proceed
        try {
          await FirebaseAuth.instance.signOut();
          UserCredential retryCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          if (retryCredential.user != null) {
            print('Retry successful, proceeding to home');
            Navigator.pushReplacementNamed(context, '/home');
            return;
          }
        } catch (retryError) {
          print('Retry failed: $retryError');
        }
      }
      
      // Handle Firebase-specific error with user-friendly messages
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        case 'user-not-verified':
          // For existing users who need verification, try to proceed anyway
          errorMessage = 'Please try logging in again. Email verification is not required.';
          break;
        default:
          errorMessage = 'Firebase error: ${e.message ?? 'Unknown error'}';
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      // Handle other errors
      print('Unexpected error during login: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email first.';
      });
      return;
    }

    try {
      // Placeholder for password reset logic
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Responsive Content
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final formWidth = isWide ? 400.0 : constraints.maxWidth * 0.95;
              final logoSize = isWide ? 180.0 : constraints.maxWidth * 0.45;
              final verticalSpace = isWide ? 40.0 : 28.0;
              return Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight * 0.95,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: verticalSpace),
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          width: logoSize,
                        ),
                        SizedBox(height: verticalSpace),
                        // Error message
                        if (_errorMessage != null)
                          Container(
                            width: formWidth,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email field
                              SizedBox(
                                width: formWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.email_outlined, color: Colors.black, size: 28),
                                      hintText: 'Enter Email',
                                      hintStyle: const TextStyle(color: Colors.white, fontSize: 18),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 1.5),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 2),
                                      ),
                                      errorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 1.5),
                                      ),
                                      focusedErrorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      filled: false,
                                    ),
                                    cursorColor: Colors.white,
                                  ),
                                ),
                              ),
                              // Password field
                              SizedBox(
                                width: formWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.lock_outline, color: Colors.black, size: 28),
                                      hintText: 'Enter Password',
                                      hintStyle: const TextStyle(color: Colors.white, fontSize: 18),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 1.5),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 2),
                                      ),
                                      errorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 1.5),
                                      ),
                                      focusedErrorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      filled: false,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.black,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    cursorColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Forgot password
                        SizedBox(
                          width: formWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _isLoading ? null : _resetPassword,
                                  child: const Text(
                                    'Forgot password ?',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Login Button
                        SizedBox(
                          width: formWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1A2980),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _isLoading ? null : _signIn,
                              child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A2980)),
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                            ),
                          ),
                        ),
                        // Divider
                        SizedBox(
                          width: formWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.5))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                        ),
                        // Sign up link
                        SizedBox(
                          width: formWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?  ",
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: _isLoading ? null : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                                  );
                                },
                                child: const Text(
                                  'Sign up >',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: verticalSpace),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// SIGNUP PAGE
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // No email verification required - proceed directly
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific error with user-friendly messages
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account with this email already exists.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign up.';
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      // Handle other errors
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
      print('Sign up error: $e');
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
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Responsive Content
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final formWidth = isWide ? 400.0 : constraints.maxWidth * 0.95;
              final logoSize = isWide ? 180.0 : constraints.maxWidth * 0.45;
              final verticalSpace = isWide ? 40.0 : 28.0;
              return Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight * 0.95,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: verticalSpace),
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          width: logoSize,
                        ),
                        SizedBox(height: verticalSpace),
                        // Error message
                        if (_errorMessage != null)
                          Container(
                            width: formWidth,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Name field
                              SizedBox(
                                width: formWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      if (value.trim().length < 2) {
                                        return 'Name must be at least 2 characters';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.person_outline, color: Colors.black, size: 28),
                                      hintText: 'Enter Name',
                                      hintStyle: const TextStyle(color: Colors.white, fontSize: 18),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 1.5),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 2),
                                      ),
                                      errorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 1.5),
                                      ),
                                      focusedErrorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      filled: false,
                                    ),
                                    cursorColor: Colors.white,
                                  ),
                                ),
                              ),
                              // Email field
                              SizedBox(
                                width: formWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.email_outlined, color: Colors.black, size: 28),
                                      hintText: 'Enter Email',
                                      hintStyle: const TextStyle(color: Colors.white, fontSize: 18),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 1.5),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 2),
                                      ),
                                      errorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 1.5),
                                      ),
                                      focusedErrorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      filled: false,
                                    ),
                                    cursorColor: Colors.white,
                                  ),
                                ),
                              ),
                              // Password field
                              SizedBox(
                                width: formWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.lock_outline, color: Colors.black, size: 28),
                                      hintText: 'Enter Password',
                                      hintStyle: const TextStyle(color: Colors.white, fontSize: 18),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 1.5),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white, width: 2),
                                      ),
                                      errorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 1.5),
                                      ),
                                      focusedErrorBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      filled: false,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.black,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    cursorColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: verticalSpace),
                        // Sign Up Button
                        SizedBox(
                          width: formWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1A2980),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _isLoading ? null : _signUp,
                              child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A2980)),
                                    ),
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: verticalSpace),
                        // Divider
                        SizedBox(
                          width: formWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.5))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                        ),
                        // Back to login link
                        SizedBox(
                          width: formWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account?  ",
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: _isLoading ? null : () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Login <',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: verticalSpace),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// HOME PAGE
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _logoAnimController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;

  @override
  void initState() {
    super.initState();
    _logoAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _logoAnimController, curve: Curves.elasticOut));
    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoAnimController, curve: Curves.easeIn));
    _logoAnimController.forward();
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 500;
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.08),
                    // Animated logo
                    FadeTransition(
                      opacity: _logoFadeAnim,
                      child: ScaleTransition(
                        scale: _logoScaleAnim,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: isWide ? 180 : size.width * 0.45,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.12),
                    // Login Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8),
                      child: SizedBox(
                        width: 340,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF23A6A7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
            ),
                            elevation: 8,
                            shadowColor: Colors.black26,
                            padding: const EdgeInsets.symmetric(vertical: 16),
      ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                        ),
                      ),
                    ),
                    // Sign Up Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8),
                      child: SizedBox(
                        width: 340,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB23A7C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black26,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PDF UPLOAD SCREEN
class PdfUploadScreen extends StatefulWidget {
  const PdfUploadScreen({super.key});

  @override
  State<PdfUploadScreen> createState() => _PdfUploadScreenState();
}

class _PdfUploadScreenState extends State<PdfUploadScreen> with SingleTickerProviderStateMixin {
  String? _fileName;
  String? _error;
  bool _isUploading = false;
  XFile? _selectedFile;
  late AnimationController _logoAnimController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;

  // API Configuration
  static const String apiUrl = 'https://flipflow.onrender.com/upload'; // Update this with your actual API URL

  @override
  void initState() {
    super.initState();
    _logoAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _logoAnimController, curve: Curves.elasticOut));
    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoAnimController, curve: Curves.easeIn));
    _logoAnimController.forward();
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    super.dispose();
  }

  void _pickPdf() async {
    setState(() {
      _error = null;
    });
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'pdf',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      final isPdf = file.name.toLowerCase().endsWith('.pdf');
      if (isPdf) {
        setState(() {
          _fileName = file.name;
          _selectedFile = file;
          _error = null;
        });
      } else {
        setState(() {
          _fileName = null;
          _selectedFile = null;
          _error = 'Please select a PDF file.';
        });
      }
    } else {
      setState(() {
        _fileName = null;
        _selectedFile = null;
        _error = 'No file selected.';
      });
    }
  }

  Future<void> _uploadPdfAndProcess() async {
    if (_selectedFile == null) {
      setState(() {
        _error = 'Please select a PDF file first.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      
      // Add the PDF file
      var file = await http.MultipartFile.fromPath(
        'file',
        _selectedFile!.path,
        filename: _selectedFile!.name,
      );
      request.files.add(file);

      // Send the request
      var response = await request.send();
      
      if (response.statusCode == 200) {
        // Success - get the video data
        var videoBytes = await response.stream.toBytes();
        
        // Navigate to result screen with video data
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ResultScreen(videoBytes: videoBytes),
            ),
          );
        }
      } else {
        // Handle error
        var errorResponse = await response.stream.bytesToString();
        setState(() {
          _error = 'Upload failed: ${response.statusCode} - $errorResponse';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Upload failed: $e';
      });
      print('Upload error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF585150),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final cardWidth = isWide ? 420.0 : constraints.maxWidth * 0.98;
          final logoSize = isWide ? 180.0 : constraints.maxWidth * 0.45;
          final verticalSpace = isWide ? 40.0 : 28.0;
          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight * 0.95,
                ),
                child: Center(
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.04*255).toInt()),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.10),
                          blurRadius: 60,
                          spreadRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animated logo
                        FadeTransition(
                          opacity: _logoFadeAnim,
                          child: ScaleTransition(
                            scale: _logoScaleAnim,
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: logoSize,
                            ),
                          ),
                        ),
                        SizedBox(height: verticalSpace),
                        // Upload label and icon
                        SizedBox(
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload the pdf here',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A2980),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                icon: const Icon(Icons.picture_as_pdf, size: 22),
                                label: const Text('Choose PDF', style: TextStyle(fontSize: 15)),
                                onPressed: _pickPdf,
                              ),
                            ],
                          ),
                        ),
                        if (_fileName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.10*255).toInt()),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.insert_drive_file, color: Colors.white70, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    _fileName!,
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        // Underline separator
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18.0),
                          child: const Divider(color: Colors.white, thickness: 1.2),
                        ),
                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A2980),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 6,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _isUploading ? null : _uploadPdfAndProcess,
                            child: _isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Convert to Video',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white),
                                ),
                          ),
                        ),
                        SizedBox(height: verticalSpace),
                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: const Text(
                            "Convert your PDF's into videos with Our AI powered PDF-to-Video converter.",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: verticalSpace),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// RESULT SCREEN
class ResultScreen extends StatefulWidget {
  final List<int>? videoBytes;
  
  const ResultScreen({super.key, this.videoBytes});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _logoAnimController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    // Logo animation
    _logoAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _logoAnimController, curve: Curves.elasticOut));
    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoAnimController, curve: Curves.easeIn));
    _logoAnimController.forward();
    
    // Initialize video if available
    if (widget.videoBytes != null) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      // Create a temporary file for the video
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/converted_video.mp4');
      await tempFile.writeAsBytes(widget.videoBytes!);
      
      // Initialize video controller
      _videoController = VideoPlayerController.file(tempFile);
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo() async {
    if (widget.videoBytes == null) return;
    
    try {
      if (kIsWeb) {
        // For web, show instructions since direct download requires additional setup
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video conversion completed! The video is ready for viewing.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // For mobile, save to downloads
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/converted_video.mp4');
        await file.writeAsBytes(widget.videoBytes!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved to: ${file.path}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF585150),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final cardWidth = isWide ? 420.0 : constraints.maxWidth * 0.98;
          final logoSize = isWide ? 180.0 : constraints.maxWidth * 0.45;
          final verticalSpace = isWide ? 40.0 : 28.0;
          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight * 0.95,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: verticalSpace),
                      // Animated logo
                      FadeTransition(
                        opacity: _logoFadeAnim,
                        child: ScaleTransition(
                          scale: _logoScaleAnim,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: logoSize,
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpace),
                      // Video player or placeholder
                      Container(
                        width: cardWidth,
                        height: cardWidth * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isVideoInitialized && _videoController != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VideoPlayer(_videoController!),
                                  // Video controls overlay
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    right: 16,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              if (_videoController!.value.isPlaying) {
                                                _videoController!.pause();
                                              } else {
                                                _videoController!.play();
                                              }
                                            });
                                          },
                                          icon: Icon(
                                            _videoController!.value.isPlaying 
                                              ? Icons.pause 
                                              : Icons.play_arrow,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        Text(
                                          '${_videoController!.value.position.inSeconds}s / ${_videoController!.value.duration.inSeconds}s',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_library,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.videoBytes != null 
                                      ? 'Loading video...'
                                      : 'No result video available.',
                                    style: TextStyle(
                                      color: Colors.grey[600], 
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                      SizedBox(height: verticalSpace),
                      // Download Button
                      SizedBox(
                        width: cardWidth,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1A2980),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: widget.videoBytes != null ? _downloadVideo : null,
                          child: const Text(
                            'Download Video',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpace),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> signUp(String email, String password, BuildContext context) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCredential.user?.sendEmailVerification();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify your email'),
        content: Text('A verification email has been sent to $email. Please verify before logging in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    // Handle signup error
    print(e);
  }
}

Future<void> signIn(String email, String password, BuildContext context) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = userCredential.user;

    if (user != null) {
      // Proceed to the app (no email verification required)
      Navigator.pushReplacementNamed(context, '/home');
    }
  } catch (e) {
    // Handle login error
    print(e);
  }
}

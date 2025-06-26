import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_selector/file_selector.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      home: const HomePage(),
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
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;

      if (user != null && user.emailVerified) {
        // Proceed to the app (email is verified)
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Email not verified
        await FirebaseAuth.instance.signOut();
        // Show a message and offer to resend verification
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Email not verified'),
            content: Text('Please verify your email before logging in.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await user?.sendEmailVerification();
                  Navigator.pop(context);
                },
                child: Text('Resend Verification Email'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific error
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      // Handle other errors
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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
        email: _emailController.text,
        password: _passwordController.text,
      );
      await userCredential.user?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PdfUploadScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific error
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      // Handle other errors
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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
          _error = null;
        });
      } else {
        setState(() {
          _fileName = null;
          _error = 'Please select a PDF file.';
        });
      }
    } else {
      setState(() {
        _fileName = null;
        _error = 'No file selected.';
      });
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
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const ResultScreen()),
                              );
                            },
                            child: const Text(
                              'Continue',
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
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _logoAnimController;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;

  @override
  void initState() {
    super.initState();
    // Logo animation
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
    return Scaffold(
      backgroundColor: const Color(0xFF585150),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                      // Placeholder for removed video
                      Container(
                        width: cardWidth,
                        height: cardWidth * 0.6,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text(
                            'No result video available.',
                            style: TextStyle(color: Colors.black54, fontSize: 18),
                          ),
                        ),
                      ),
                      SizedBox(height: verticalSpace),
                      // Download Button (disabled)
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
                          onPressed: null,
                          child: const Text(
                            'Download',
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

    if (user != null && user.emailVerified) {
      // Proceed to the app (email is verified)
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Email not verified
      await FirebaseAuth.instance.signOut();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Email not verified'),
          content: Text('Please verify your email before logging in.'),
          actions: [
            TextButton(
              onPressed: () async {
                await user?.sendEmailVerification();
                Navigator.pop(context);
              },
              child: Text('Resend Verification Email'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    // Handle login error
    print(e);
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/error_message.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const SignupScreen({super.key, required this.onSwitchToLogin});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String? error;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _passwordStrength = 0;
  String _passwordFeedback = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    // Listen to password changes for strength indicator
    passwordController.addListener(() {
      setState(() {
        _passwordStrength = Validators.getPasswordStrength(passwordController.text);
        _passwordFeedback = Validators.getPasswordFeedback(passwordController.text);
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered. Please use a different email or try logging in.';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address format.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  Future<void> signup() async {
    setState(() {
      error = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validate email with regex
    if (!Validators.isValidEmail(email)) {
      setState(() {
        error = 'Invalid email address. Please enter a valid email.';
      });
      return;
    }

    // Validate password strength
    if (!Validators.isValidPassword(password)) {
      final feedback = Validators.getPasswordFeedback(password);
      setState(() {
        error = feedback.isNotEmpty ? feedback : 'Password does not meet requirements:\n'
            '• At least 8 characters\n'
            '• One uppercase letter\n'
            '• One lowercase letter\n'
            '• One number\n'
            '• One special character (@\$!%*?&)';
      });
      return;
    }

    // Check if passwords match
    if (password != confirmPassword) {
      setState(() {
        error = 'Passwords do not match.';
      });
      return;
    }

    try {
      // Create user with email and password
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      // Show verification dialog immediately (use WidgetsBinding to ensure it shows)
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showVerificationDialog(email);
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = _formatErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        error = _formatErrorMessage(e.toString());
      });
    }
  }

  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true, // Use root navigator to prevent StreamBuilder from closing it
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Check Your Email'),
            ],
          ),
          content: Text(
            'A verification email has been sent to:\n$email\n\n'
            'Please check your email and click the verification link to verify your account.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Cancel - sign out and close dialog
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pop();
                  emailController.clear();
                  passwordController.clear();
                  confirmPasswordController.clear();
                  setState(() {
                    error = null;
                  });
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Check if user is verified
                await FirebaseAuth.instance.currentUser?.reload();
                final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
                
                if (isVerified) {
                  // User is verified - close dialog and navigate to home
                  if (mounted) {
                    Navigator.of(context).pop();
                    // StreamBuilder will automatically navigate to HomeScreen
                  }
                } else {
                  // Not verified yet - show error
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You are not verified yet. Please check your email.'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('I am Verified'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // If dialog is dismissed and user is not verified, sign them out
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        FirebaseAuth.instance.signOut();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container( 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.purple.shade300,
              Colors.deepPurple.shade500,
              Colors.indigo.shade700,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon Section
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/icon.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TripCalc',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Welcome Text
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join us and start tracking your trips',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Signup Form Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Email Field
                          CustomTextField(
                            controller: emailController,
                            labelText: 'Email Address',
                            hintText: 'Enter your email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          CustomTextField(
                            controller: passwordController,
                            labelText: 'Password',
                            hintText: 'Create a password',
                            icon: Icons.lock_outline,
                            obscureText: !_passwordVisible,
                            showVisibilityToggle: true,
                            onVisibilityToggle: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),

                          // Password Strength Indicator
                          if (passwordController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            PasswordStrengthIndicator(
                              strength: _passwordStrength,
                              feedback: _passwordFeedback,
                            ),
                          ],
                          
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          CustomTextField(
                            controller: confirmPasswordController,
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter your password',
                            icon: Icons.lock_outline,
                            obscureText: !_confirmPasswordVisible,
                            showVisibilityToggle: true,
                            onVisibilityToggle: () {
                              setState(() {
                                _confirmPasswordVisible = !_confirmPasswordVisible;
                              });
                            },
                          ),

                          // Error Message
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            ErrorMessage(message: error!),
                          ],

                          const SizedBox(height: 32),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                shadowColor: Colors.deepPurple.withOpacity(0.3),
                              ),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onSwitchToLogin,
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
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

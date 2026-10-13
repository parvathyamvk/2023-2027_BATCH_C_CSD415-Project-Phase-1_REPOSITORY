import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'donor_home.dart';
import 'ngo_home.dart';
import 'volunteer_home.dart';
import 'receiver_home.dart';
import 'admin_home.dart';


// =====================================================
// LOGIN SCREEN
// =====================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ===================================================
  // LOGIN
  // ===================================================

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email and password.',
          ),
        ),
      );
      return;
    }

    try {
      // Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Keep the existing local login flag for the current app flow.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);

      // =========================================================
      // FIXED ADMIN ACCOUNT
      // =========================================================
      // The Admin account is authenticated through Firebase first.
      // We do NOT require an Admin users/{uid} document here.
      // This is important because Firestore rules identify the fixed
      // Admin using the authenticated email address.
      const adminEmail = 'admin@shareplate.com';

      if (email.toLowerCase() == adminEmail) {
        await prefs.setString('userRole', 'admin');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminHomeScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // =========================================================
      // NORMAL USER ROLE
      // =========================================================
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Logged-in user could not be found.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc.data()?['role']?.toString().toLowerCase();

      if (!mounted) return;

      if (role == 'donor') {
        await prefs.setString('userRole', 'donor');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const DonorHomeScreen(),
          ),
          (route) => false,
        );
      } else if (role == 'ngo') {
        await prefs.setString('userRole', 'ngo');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const NgoHomeScreen(),
          ),
          (route) => false,
        );
      } else if (role == 'volunteer') {
        await prefs.setString('userRole', 'volunteer');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const VolunteerHomeScreen(),
          ),
          (route) => false,
        );
      } else if (role == 'receiver') {
        await prefs.setString('userRole', 'receiver');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ReceiverHomeScreen(),
          ),
          (route) => false,
        );
      } else {
        // New users who have not selected a role yet continue
        // through the existing role-selection screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserTypeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF222222),
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            15,
            24,
            30,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // =================================================
              // TITLE
              // =================================================

              const Text(
                'Welcome back 👋',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Login to continue with SharePlate.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              // =================================================
              // EMAIL
              // =================================================

              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,

                keyboardType:
                    TextInputType.emailAddress,

                decoration: InputDecoration(
                  hintText:
                      'Enter your email',

                  prefixIcon: const Icon(
                    Icons.email_outlined,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),

                    borderSide:
                        BorderSide.none,
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),

                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE85D4A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // PASSWORD
              // =================================================

              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    passwordController,

                obscureText:
                    hidePassword,

                decoration: InputDecoration(
                  hintText:
                      'Enter your password',

                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon:
                      IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        hidePassword =
                            !hidePassword;
                      });
                    },
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),

                    borderSide:
                        BorderSide.none,
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),

                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE85D4A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // =================================================
              // FORGOT PASSWORD
              // =================================================

              Align(
                alignment:
                    Alignment.centerRight,

                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Forgot password will be added when backend is connected.',
                        ),
                      ),
                    );
                  },

                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color:
                          Color(0xFFE85D4A),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // =================================================
              // LOGIN BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed: login,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                            0xFFE85D4A),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              14),
                    ),
                  ),

                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // DIVIDER
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 12,
                    ),

                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Divider(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // =================================================
              // SIGN UP
              // =================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RegisterScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color:
                            Color(0xFFE85D4A),
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =====================================================
// REGISTER SCREEN
// =====================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {

  final TextEditingController
      nameController =
      TextEditingController();

  final TextEditingController
      emailController =
      TextEditingController();

  final TextEditingController
      passwordController =
      TextEditingController();

  final TextEditingController
      confirmPasswordController =
      TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ===================================================
  // CREATE ACCOUNT
  // ===================================================

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword =
        confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all the fields.',
          ),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain at least 6 characters.',
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Passwords do not match.',
          ),
        ),
      );
      return;
    }

    try {
      // Firebase Authentication
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('User account was not created.');
      }

      // Create the user's Firestore profile.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': name,
        'email': email,
        'phone': '',
        'location': '',
        'role': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save the basic information locally for the current app flow.
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', name);
      await prefs.setString('userEmail', email);
      await prefs.remove('userPhone');
      await prefs.remove('userLocation');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const UserTypeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Account creation failed. Please try again.';

      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Please choose a stronger password.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.white,
        elevation: 0,

        foregroundColor:
            const Color(0xFF222222),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                'Join SharePlate ❤️',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create an account to get started.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // NAME
              // =================================================

              const Text(
                'Full Name',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    nameController,

                decoration:
                    InputDecoration(
                  hintText:
                      'Enter your full name',

                  prefixIcon:
                      const Icon(
                    Icons.person_outline,
                  ),

                  filled: true,
                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(14),

                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // EMAIL
              // =================================================

              const Text(
                'Email',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    emailController,

                keyboardType:
                    TextInputType
                        .emailAddress,

                decoration:
                    InputDecoration(
                  hintText:
                      'Enter your email',

                  prefixIcon:
                      const Icon(
                    Icons.email_outlined,
                  ),

                  filled: true,
                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(14),

                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // PASSWORD
              // =================================================

              const Text(
                'Password',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    passwordController,

                obscureText:
                    hidePassword,

                decoration:
                    InputDecoration(
                  hintText:
                      'Create a password',

                  prefixIcon:
                      const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon:
                      IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        hidePassword =
                            !hidePassword;
                      });
                    },
                  ),

                  filled: true,
                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(14),

                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // CONFIRM PASSWORD
              // =================================================

              const Text(
                'Confirm Password',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    confirmPasswordController,

                obscureText:
                    hideConfirmPassword,

                decoration:
                    InputDecoration(
                  hintText:
                      'Re-enter your password',

                  prefixIcon:
                      const Icon(
                    Icons.lock_outline,
                  ),

                  suffixIcon:
                      IconButton(
                    icon: Icon(
                      hideConfirmPassword
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        hideConfirmPassword =
                            !hideConfirmPassword;
                      });
                    },
                  ),

                  filled: true,
                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(14),

                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // CREATE ACCOUNT BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed:
                      createAccount,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                            0xFFE85D4A),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              14),
                    ),
                  ),

                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // BACK TO LOGIN
              // =================================================

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      color:
                          Color(0xFFE85D4A),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =====================================================
// CHOOSE USER ROLE
// =====================================================

class UserTypeScreen extends StatelessWidget {
  const UserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,

        elevation: 0,

        title: const Text(
          'Choose Your Role',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        foregroundColor:
            const Color(0xFF222222),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                'How will you use SharePlate?',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Select the option that best describes you.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // DONOR
              // =================================================

              RoleCard(
                icon:
                    Icons.volunteer_activism,

                title: 'Donor',

                subtitle:
                    'Donate food to people who need it.',

                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) {
                    showRoleSelected(
                      context,
                      'Donor',
                    );
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'role': 'donor',
                  });

                  final prefs =
                      await SharedPreferences.getInstance();

                  await prefs.setString(
                    'userRole',
                    'donor',
                  );

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const DonorHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 15),

              // =================================================
              // NGO
              // =================================================

              RoleCard(
                icon: Icons.business,

                title: 'NGO',

                subtitle:
                    'Manage donations and distribution.',

                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) {
                    showRoleSelected(context, 'NGO');
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'role': 'ngo',
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userRole', 'ngo');

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NgoHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 15),

              // =================================================
              // VOLUNTEER
              // =================================================

              RoleCard(
                icon:
                    Icons.delivery_dining,

                title: 'Volunteer',

                subtitle:
                    'Help with pickup and delivery.',

                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) {
                    showRoleSelected(context, 'Volunteer');
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'role': 'volunteer',
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userRole', 'volunteer');

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const VolunteerHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 15),

              // =================================================
              // RECEIVER
              // =================================================

              RoleCard(
                icon: Icons.groups_rounded,
                title: 'Receiver',
                subtitle: 'Request food for your community.',
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) {
                    showRoleSelected(context, 'Receiver');
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set({
                      'role': 'receiver',
                    }, SetOptions(merge: true));

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('userRole', 'receiver');

                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReceiverHomeScreen(),
                      ),
                      (route) => false,
                    );
                  } on FirebaseException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Receiver setup failed: ${e.message ?? e.code}',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Receiver setup failed: $e'),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 15),

            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveRoleAndShowMessage(
    BuildContext context,
    String role,
    String displayRole,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'role': role,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', role);
    }

    if (!context.mounted) return;

    showRoleSelected(context, displayRole);
  }

  void showRoleSelected(
    BuildContext context,
    String role,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$role dashboard will be added next.',
        ),
      ),
    );
  }
}


// =====================================================
// ROLE CARD
// =====================================================

class RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(20),

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.all(18),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.05),

              blurRadius: 10,

              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [

            Container(
              width: 56,
              height: 56,

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                        0xFFE85D4A)
                    .withOpacity(0.12),

                borderRadius:
                    BorderRadius.circular(
                        16),
              ),

              child: Icon(
                icon,

                color:
                    const Color(
                        0xFFE85D4A),

                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(
                    title,

                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF222222),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,

                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .arrow_forward_ios_rounded,

              size: 17,

              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
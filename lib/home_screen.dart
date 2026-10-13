import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'donor_home.dart';
import 'receiver_home.dart';
import 'ngo_home.dart';
import 'volunteer_home.dart';

const Color coral = Color(0xFFE85D4A);
const Color purple = Color(0xFF9A6BFF);
const Color background = Color(0xFFFFF8F2);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  late final List<Widget> screens = [
    HomeContent(onNavigate: _changeTab),
    const FindFoodScreen(),
    const ShareFoodScreen(),
    const ProfileScreen(),
  ];

  void _changeTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: coral,
        unselectedItemColor: Colors.grey,
        elevation: 8,

        onTap: _changeTab,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Find',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Share',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME CONTENT
// ============================================================

class HomeContent extends StatelessWidget {
  final void Function(int) onNavigate;

  const HomeContent({super.key, required this.onNavigate});

  Future<void> _openDashboard(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    // ----------------------------------------------------------
    // NOT LOGGED IN
    // ----------------------------------------------------------

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      return;
    }

    // ----------------------------------------------------------
    // GET USER ROLE
    // ----------------------------------------------------------

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc.data()?['role']?.toString().toLowerCase() ?? '';

      if (!context.mounted) return;

      // --------------------------------------------------------
      // DONOR
      // --------------------------------------------------------

      if (role == 'donor') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DonorHomeScreen()),
        );

        return;
      }

      // --------------------------------------------------------
      // NGO
      // --------------------------------------------------------

      if (role == 'ngo') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NgoHomeScreen()),
        );

        return;
      }

      // --------------------------------------------------------
      // VOLUNTEER
      // --------------------------------------------------------

      if (role == 'volunteer') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VolunteerHomeScreen()),
        );

        return;
      }

      // --------------------------------------------------------
      // RECEIVER
      // --------------------------------------------------------

      if (role == 'receiver') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReceiverHomeScreen()),
        );

        return;
      }

      // --------------------------------------------------------
      // ROLE NOT SET
      // --------------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account role has not been set yet.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open dashboard: $e')));
    }
  }

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'SharePlate',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications will appear here.'),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // WELCOME
            // ==================================================
            const Text(
              'Welcome to SharePlate 👋',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Connect, share and make a difference.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // MAIN SHARE CARD
            // ==================================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [coral, purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.circular(24),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Share what you can.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Every connection can create a positive impact.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      _openDashboard(context);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: coral,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // WHAT WOULD YOU LIKE TO DO
            // ==================================================
            const Text(
              'What would you like to do?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: HomeActionCard(
                    icon: Icons.volunteer_activism,
                    title: 'Share',
                    subtitle: 'Offer surplus food',

                    onTap: () {
                      onNavigate(2);
                    },
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: HomeActionCard(
                    icon: Icons.search_rounded,
                    title: 'Find',
                    subtitle: 'Find available food',

                    onTap: () {
                      onNavigate(1);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            HomeActionCard(
              icon: Icons.delivery_dining_rounded,
              title: 'Volunteer',
              subtitle: 'Help collect and deliver food',
              fullWidth: true,

              onTap: () {
                _openDashboard(context);
              },
            ),

            const SizedBox(height: 30),

            // ==================================================
            // OVERALL IMPACT
            // ==================================================
            const Text(
              '🌍 Overall Impact',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            const Text(
              'Together, we can reduce food waste and help communities.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 15),

            const OverallImpactCard(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME ACTION CARD
// ============================================================

class HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool fullWidth;

  const HomeActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,

      height: 125,

      child: Material(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        child: InkWell(
          onTap: onTap,

          borderRadius: BorderRadius.circular(20),

          child: Padding(
            padding: const EdgeInsets.all(17),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Container(
                  width: 44,
                  height: 44,

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EC),

                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: Icon(icon, color: coral, size: 24),
                ),

                const Spacer(),

                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,

                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OVERALL IMPACT
// ============================================================

class OverallImpactCard extends StatelessWidget {
  const OverallImpactCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('stats')
          .doc('overall')
          .snapshots(),

      builder: (context, snapshot) {
        int donations = 0;
        int peopleHelped = 0;
        int deliveries = 0;
        int volunteers = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() ?? {};

          donations = _getNumber(data['donations']);

          peopleHelped = _getNumber(data['peopleHelped']);

          deliveries = _getNumber(data['deliveries']);

          volunteers = _getNumber(data['volunteers']);
        }

        return Container(
          width: double.infinity,

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(20),
          ),

          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,

                children: [
                  ImpactItem(
                    icon: Icons.volunteer_activism,
                    number: donations.toString(),
                    label: 'Donations',
                  ),

                  ImpactItem(
                    icon: Icons.people_alt_outlined,
                    number: peopleHelped.toString(),
                    label: 'People Helped',
                  ),

                  ImpactItem(
                    icon: Icons.delivery_dining_outlined,
                    number: deliveries.toString(),
                    label: 'Deliveries',
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const Divider(),

              const SizedBox(height: 18),

              ImpactItem(
                icon: Icons.directions_run_rounded,
                number: volunteers.toString(),
                label: 'Active Volunteers',
              ),
            ],
          ),
        );
      },
    );
  }

  static int _getNumber(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

// ============================================================
// IMPACT ITEM
// ============================================================

class ImpactItem extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;

  const ImpactItem({
    super.key,
    required this.icon,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 25, color: coral),

        const SizedBox(height: 7),

        Text(
          number,

          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: coral,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          textAlign: TextAlign.center,

          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }
}

// ============================================================
// FIND FOOD SCREEN
// ============================================================

class FindFoodScreen extends StatelessWidget {
  const FindFoodScreen({super.key});

  Future<void> _openReceiverDashboard(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc.data()?['role']?.toString().toLowerCase();

      if (!context.mounted) return;

      if (role == 'receiver') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReceiverHomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Food requests are available from the Receiver dashboard.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open Find: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Find Food',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Container(
                width: 85,
                height: 85,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EC),
                  borderRadius: BorderRadius.circular(25),
                ),

                child: const Icon(Icons.search_rounded, size: 42, color: coral),
              ),

              const SizedBox(height: 22),

              const Text(
                'Find available food',
                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                'Receivers can use their dashboard to request available food from SharePlate.',
                textAlign: TextAlign.center,

                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () {
                  _openReceiverDashboard(context);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: coral,
                  foregroundColor: Colors.white,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 14,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                child: const Text(
                  'Open Receiver Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SHARE FOOD SCREEN
// ============================================================

class ShareFoodScreen extends StatelessWidget {
  const ShareFoodScreen({super.key});

  Future<void> _openDonorDashboard(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc.data()?['role']?.toString().toLowerCase();

      if (!context.mounted) return;

      if (role == 'donor') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DonorHomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only donor accounts can create food donations.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open donor dashboard: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Share Food',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Container(
                width: 90,
                height: 90,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EC),
                  borderRadius: BorderRadius.circular(25),
                ),

                child: const Icon(
                  Icons.volunteer_activism,
                  size: 45,
                  color: coral,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Share your surplus food',
                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                'Donate extra food and help connect it with people who need it.',
                textAlign: TextAlign.center,

                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () {
                  _openDonorDashboard(context);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: coral,
                  foregroundColor: Colors.white,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                child: const Text(
                  'Open Donor Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE SCREEN
// ============================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: user == null
          ? const LoggedOutProfile()
          : LoggedInProfile(user: user),
    );
  }
}

// ============================================================
// LOGGED OUT PROFILE
// ============================================================

class LoggedOutProfile extends StatelessWidget {
  const LoggedOutProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 85,
              color: Colors.grey,
            ),

            const SizedBox(height: 18),

            const Text(
              'You are not logged in',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Login to access your SharePlate profile.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 22),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: coral,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
              ),

              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOGGED IN PROFILE
// ============================================================

class LoggedInProfile extends StatelessWidget {
  final User user;

  const LoggedInProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),

      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        final name = data['name']?.toString().trim() ?? '';

        final role = data['role']?.toString().trim() ?? '';

        final phone = data['phone']?.toString().trim() ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              const SizedBox(height: 20),

              CircleAvatar(
                radius: 45,

                backgroundColor: const Color(0xFFFFF0EC),

                child: const Icon(Icons.person, size: 48, color: coral),
              ),

              const SizedBox(height: 15),

              Text(
                name.isEmpty ? 'SharePlate User' : name,

                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                user.email ?? 'No email',

                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    ProfileInfoRow(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: user.email ?? 'Not available',
                    ),

                    const Divider(height: 25),

                    ProfileInfoRow(
                      icon: Icons.badge_outlined,
                      title: 'Role',
                      value: role.isEmpty ? 'Not set' : role.toUpperCase(),
                    ),

                    if (phone.isNotEmpty) ...[
                      const Divider(height: 25),

                      ProfileInfoRow(
                        icon: Icons.phone_outlined,
                        title: 'Phone',
                        value: phone,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,

                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pushAndRemoveUntil(
                      context,

                      MaterialPageRoute(builder: (_) => const HomeScreen()),

                      (route) => false,
                    );
                  },

                  icon: const Icon(Icons.logout),

                  label: const Text('Logout'),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: coral,

                    side: const BorderSide(color: coral),

                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// PROFILE INFO ROW
// ============================================================

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, color: coral),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 4),

              Text(value, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

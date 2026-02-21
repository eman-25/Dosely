import 'package:flutter/material.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/header.dart';
import 'home_screen.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double dragDy = 0;

    void handleVerticalDragUpdate(DragUpdateDetails d) {
      dragDy += d.delta.dy;
    }

    void handleVerticalDragEnd(DragEndDetails d) {
      const threshold = 80.0;
      // If user swipes up sufficiently, pop back to Home
      if (dragDy < -threshold) Navigator.of(context).pop();
      dragDy = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: GestureDetector(
        onVerticalDragUpdate: handleVerticalDragUpdate,
        onVerticalDragEnd: handleVerticalDragEnd,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ListView(
              children: [
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.settings_rounded, color: AppColors.text),
                    SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _Section(title: 'Account', tiles: [
                  _Tile(icon: Icons.edit_rounded, title: 'Edit profile'),
                  _Tile(icon: Icons.health_and_safety_rounded, title: 'Personal Health Information'),
                  _Tile(icon: Icons.lock_rounded, title: 'Security'),
                  _Tile(icon: Icons.notifications_rounded, title: 'Notifications'),
                  _Tile(icon: Icons.privacy_tip_rounded, title: 'Privacy'),
                ]),
                const SizedBox(height: 14),
                const _Section(title: 'Support & About', tiles: [
                  _Tile(icon: Icons.help_rounded, title: 'Help & Support'),
                  _Tile(icon: Icons.info_rounded, title: 'About Us'),
                ]),
                const SizedBox(height: 14),
                const _Section(title: 'Actions', tiles: [
                  _Tile(icon: Icons.report_rounded, title: 'Report a problem'),
                  _Tile(icon: Icons.logout_rounded, title: 'Log out'),
                ]),
                const SizedBox(height: 24),
                // Bottom greeting similar to mockup
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Greetings, Sara !\nHow can MedAI help you today?',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.c3,
                        child: Icon(Icons.person_rounded, color: Colors.white),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Tile> tiles;
  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...tiles.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: Icon(t.icon, color: Colors.black54),
                  title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    switch (t.title) {
                    case 'Edit profile':
                    Navigator.pushNamed(context, '/editProfile');
                    break;
                    case 'Personal Health Information':
                    Navigator.pushNamed(context, '/editPersonalHealthInfo');
                    break;
                    case 'Privacy':
                    Navigator.pushNamed(context, '/privacy');
                    break;
                    case 'Language':
                    Navigator.pushNamed(context, '/language');
                    break;
                    case 'Notifications':
                    Navigator.pushNamed(context, '/notifications');
                    break;
                    case 'Security':
                    Navigator.pushNamed(context, '/security');
                    break;
                    case 'Help & Support':
                    Navigator.pushNamed(context, '/helpSupport');
                    break;
                    case 'About Us':
                    Navigator.pushNamed(context, '/aboutUs');
                    break;
                    case 'Report a problem':
                    Navigator.pushNamed(context, '/reportProblem');
                    break;
                    case 'Log out':
                   // Simple confirmation dialog (or navigate to logout screen)
                    showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                        TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                        ),
                        TextButton(
                        onPressed: () {
                // TODO: Clear auth / provider / shared prefs
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      break;
  }
  },
                ),
              ),
            )),
      ],
    );
  }
}

class _Tile {
  final IconData icon;
  final String title;
  const _Tile({required this.icon, required this.title});
}

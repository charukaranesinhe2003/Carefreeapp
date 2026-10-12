import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F8),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                BackButtonRound(),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Help', style: Theme.of(context).textTheme.displayLarge),
                      Text('How to find pharmacies and clinics', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _HelpCard(
              icon: Icons.my_location_rounded,
              title: 'Use my location',
              body:
                  'Tap Use My Location, then Allow. The app follows your position and lists pharmacies and clinics near you, grouped by distance.',
            ),
            const _HelpCard(
              icon: Icons.search_rounded,
              title: 'Search an area yourself',
              body:
                  'Tap Don\'t allow, or type a town in the search box. Sri Lanka towns and your last location still work when the phone is offline.',
            ),
            const _HelpCard(
              icon: Icons.local_pharmacy_rounded,
              title: 'Pharmacies and clinics',
              body:
                  'Each card shows whether it is a pharmacy or a clinic, if it is open, and how far it is. Tap a card to call or see details.',
            ),
            const _HelpCard(
              icon: Icons.sticky_note_2_rounded,
              title: 'Notes',
              body: 'Open Notes to write what to remember about a visit. You can edit or delete a note later.',
            ),
            const _HelpCard(
              icon: Icons.alarm_rounded,
              title: 'Reminders',
              body:
                  'Open Reminders, add what you need, then pick a date and time. Allow notifications when the phone asks. At that time the phone plays a sound and shows a notification, even if this app is closed.',
            ),
            const SizedBox(height: 4),
            Pressable(
              onTap: () => launchUrl(Uri(scheme: 'tel', path: '1990')),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emergency_rounded, color: Color(0xFFE11D48)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need urgent help?', style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('Call 1990 Suwa Seriya for a free ambulance', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3D6E6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

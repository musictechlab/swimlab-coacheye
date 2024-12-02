import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SwimBuddyPage extends StatelessWidget {
  const SwimBuddyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: Text('SwimBuddy Pro', style: TextStyle(
          color: const Color.fromARGB(255, 255, 255, 255))),
          backgroundColor: const Color(0xFF4D565D),

      ),
      backgroundColor: const Color(0xFF4D565D),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/swimbuddy_logo.png',
                width: 500,
                height: 500,
              ),
            ),
            SizedBox(height: 24),
            _buildInfoSection(
              'SwimBuddy Pro',
              'Programmable Metronome For Swimmers',
            ),
            _buildDivider(),
            _buildInfoSection(
              'Easy to Use',
              '• Set the interval, e.g. 1 second\n'
              '• Put the device under the cap\n'
              '• Keep the pace and enjoy your progress',
            ),
            _buildDivider(),
            _buildInfoSection(
              'Key Features',
              '• 3 Default Programs\n'
              '• 14 Days Battery Life\n'
              '• Bluetooth Connectivity\n'
              '• Waterproof Design',
            ),
            _buildDivider(),
            _buildInfoSection(
              'Smart Design',
              'Modern, sleek, and compact design that complements '
              'your swimming lifestyle while providing top performance in the water.',
            ),
            _buildDivider(),
            _buildPreOrderSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        color: Colors.white24,
        thickness: 1,
      ),
    );
  }

  Widget _buildPreOrderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text(
          'Pre-order Now',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '10% off for all pre-order purchases',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                final url = Uri.parse('https://www.swimbuddy.pro/newsletter?utm_source=coacheye');
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                padding: EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: Text(
                'Join Waiting List',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                final url = Uri.parse('https://www.swimbuddy.pro?utm_source=coacheye');
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                padding: EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: Text(
                'Read More',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 20),
      ],
    );
  }
} 
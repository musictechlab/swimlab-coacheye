import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About SwimLab Coach\'s Eye', style: TextStyle(
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
                'assets/splash.png',
                width: 200,
                height: 200,
              ),
            ),
            SizedBox(height: 24),
            _buildInfoSection(
              'Version',
              'Version 1.0.0+13',
            ),
            _buildDivider(),
            _buildInfoSection(
              'Description',
              'SwimLab Coach\'s Eye is a professional video analysis tool designed specifically for swim coaches. It provides advanced features for analyzing swimming technique and performance.',
            ),
            _buildDivider(),
            _buildInfoSection(
              'Features',
              '• Video playback controls (play, pause, rewind, forward)\n'
              '• Speed control (0.5x to 2x playback speed)\n'
              '• Drawing tools:\n'
              '  - Lines and curves\n'
              '  - Arrows for motion indication\n'
              '  - Rectangles and circles\n'
              '  - Triangles for form analysis\n'
              '• Measurement tools:\n'
              '  - Angle measurement\n'
              '  - Protractor for precise angles\n'
              '• Spotlight masking tool\n'
              '• Customizable colors and stroke widths\n'
              '• Undo/redo functionality\n'
              '• Video timeline with frame preview\n'
              '• Volume control and muting\n'
              '• Shape manipulation (move and resize)',
            ),
            _buildDivider(),
            _buildInfoSection(
              'Developer',
              'Created by SwimLab.io',
            ),
            _buildDivider(),
            _buildInfoSection(
              'Contact',
              'For support or inquiries:\nEmail: support@swimlab.io\nWebsite: https://www.swimlab.io/products/coacheye',
            ),
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
} 
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsPage extends StatefulWidget {
  final Color currentBackgroundColor;
  final Function(Color) onBackgroundColorChanged;

  const SettingsPage({
    super.key, 
    required this.currentBackgroundColor,
    required this.onBackgroundColorChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentBackgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(
          color: const Color.fromARGB(255, 255, 255, 255))),
          backgroundColor: const Color(0xFF4D565D),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text(
              'App Background Color',
              style: TextStyle(color: Colors.white),
            ),
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedColor,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Pick a color'),
                    content: SingleChildScrollView(
                      child: BlockPicker(
                        pickerColor: _selectedColor,
                        onColorChanged: (Color color) {
                          setState(() {
                            _selectedColor = color;
                          });
                          widget.onBackgroundColorChanged(color);
                        },
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Done'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            title: const Text(
              'Reset Settings',
              style: TextStyle(color: Colors.white),
            ),
            leading: const Icon(Icons.restore, color: Colors.white),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Reset Settings'),
                    content: const Text('This will reset all settings to default values. Continue?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Reset'),
                        onPressed: () {
                          setState(() {
                            _selectedColor = const Color(0xFF4D565D);
                          });
                          widget.onBackgroundColorChanged(const Color(0xFF4D565D));
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
} 
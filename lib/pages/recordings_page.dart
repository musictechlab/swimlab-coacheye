import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class RecordingsPage extends StatefulWidget {
  @override
  _RecordingsPageState createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  List<FileSystemEntity> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      
      print('Application Documents Directory: ${directory.path}');
      print('Full Recordings Path: ${recordingsDir.path}');
      
      if (!await recordingsDir.exists()) {
        print('Recordings directory does not exist, creating it');
        await recordingsDir.create(recursive: true);
      }

      final List<FileSystemEntity> files = await recordingsDir.list().toList();
      print('All files in directory:');
      for (var file in files) {
        print('File: ${file.path} - Exists: ${await File(file.path).exists()}');
      }
      
      final videoFiles = files.where((file) => 
        file.path.endsWith('.mp4') || 
        file.path.endsWith('.mov')
      ).toList();
      
      print('Filtered video files:');
      for (var file in videoFiles) {
        print('Video: ${file.path} - Exists: ${await File(file.path).exists()}');
      }
      
      setState(() {
        _recordings = videoFiles;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading recordings: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecording(FileSystemEntity recording) async {
    try {
      await recording.delete();
      _loadRecordings(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting recording')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recordings'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _recordings.isEmpty
              ? Center(
                  child: Text(
                    'No recordings found',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: _recordings.length,
                  itemBuilder: (context, index) {
                    final recording = _recordings[index];
                    final fileName = recording.path.split('/').last;
                    final fileStats = recording.statSync();
                    final fileDate = DateTime.fromMillisecondsSinceEpoch(
                        fileStats.modified.millisecondsSinceEpoch);

                    return ListTile(
                      leading: Icon(Icons.video_library, color: Colors.white70),
                      title: Text(
                        fileName,
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${fileDate.toString().split('.')[0]}',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRecording(recording),
                      ),
                      onTap: () {
                        // TODO: Implement video playback
                      },
                    );
                  },
                ),
    );
  }
} 
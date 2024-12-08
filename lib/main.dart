import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';  // Add this line
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'pages/about_page.dart';
import 'pages/swimbuddy_page.dart';
import 'pages/settings_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'pages/recordings_page.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:share_plus/share_plus.dart';


void main() {
  runApp(CoachEye());
}

class CoachEye extends StatefulWidget {
  const CoachEye({super.key});

  @override
  State<CoachEye> createState() => _CoachEyeState();
}

class _CoachEyeState extends State<CoachEye> {
  Color _backgroundColor = const Color(0xFF4D565D);

  void _updateBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(color: Colors.white), // This will make all AppBar icons white, including the back button
          color: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: VideoEditorScreen(
        backgroundColor: _backgroundColor,
        onBackgroundColorChanged: _updateBackgroundColor,
      ),
    );
  }
}
enum ShapeType { line, arrow, rectangle, circle, triangle, curve, angle, protractor }

class VideoEditorScreen extends StatefulWidget {
  final Color backgroundColor;
  final Function(Color) onBackgroundColorChanged;

  const VideoEditorScreen({
    super.key,
    required this.backgroundColor,
    required this.onBackgroundColorChanged,
  });

  @override
  _VideoEditorScreenState createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  Color _selectedColor = Colors.lightGreen;
  double _strokeWidth = 10.0;
  ShapeType _selectedShape = ShapeType.line;
  final List<Shape> _shapes = [];
  final List<Shape> _undoStack = [];
  Shape? _currentShape;
  double _volume = 0.1;
  double? _previousVolume = 0.1;
  bool _isVolumeSliderVisible = false; // To toggle the volume slider visibility
  bool _isMovingShape = false;
  Shape? _movingShape;
  Offset? _lastPosition;
  bool _isMaskMode = false;
  Shape? _maskShape;
  bool _isResizingMask = false;
  bool _isStrokeWidthSliderVisible = false;
  int _selectedIndex = 0;
  static const int HOME_INDEX = 0;
  static const int OPEN_VIDEO_INDEX = 1;
  static const int SWIMBUDDY_INDEX = 2;
  static const int SETTINGS_INDEX = 3;
  static const int ABOUT_INDEX = 4;
 static const int RECORDINGS_INDEX = 5;
  bool _showAnimation = true; // Add this property
  bool _isFullScreen = false;
  late Duration _skipStepTime = const Duration(seconds: 5);
  static const Duration MIN_SKIP_TIME = Duration(seconds: 3);
  static const Duration MAX_SKIP_TIME = Duration(seconds: 30);
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.25, 0.5, 1.0, 1.25, 1.5, 1.75, 2.0];
  bool _isPlaybackSpeedEnabled = true;  // Add this property
  final GlobalKey _strokeWidthIconKey = GlobalKey();
  Offset? _strokeWidthPosition;
  bool _isResizingProtractor = false;
  Shape? _selectedProtractor;
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isResizingCircle = false;
  Shape? _selectedCircle;
  bool _isResizingTriangle = false;
  Shape? _selectedTriangle;
  bool _isResizingRectangle = false;
  Shape? _selectedRectangle;
  bool _isResizingArrow = false;
  Shape? _selectedArrow;
  // Add this property to track angle visibility
  bool _showTriangleAngles = true;
  final GlobalKey _triangleIconKey = GlobalKey();
  bool _isTriangleToolsetVisible = false;
  Offset? _triangleToolsetPosition;
  bool _isRecording = false;
  String _recordingDuration = '00:00';
  Timer? _recordingTimer;  // Add this property
  bool _isInitialized = true;  // We can set this to true since we don't need initialization
  // Add this property to the class
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toggleMute();
    });
  }

  void _updateSkipStepTime() {
    if (_controller != null && _controller!.value.isInitialized) {
      final videoDuration = _controller!.value.duration;
      // Calculate skip time as approximately 2% of total duration
      final calculatedSkipTime = Duration(milliseconds: (videoDuration.inMilliseconds * 0.02).round());
      
      setState(() {
        _skipStepTime = calculatedSkipTime.compareTo(MIN_SKIP_TIME) < 0 
            ? MIN_SKIP_TIME 
            : calculatedSkipTime.compareTo(MAX_SKIP_TIME) > 0 
                ? MAX_SKIP_TIME 
                : calculatedSkipTime;
      });
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      // Debug print to verify the path
      print('Selected video path: ${result.files.single.path}');
      
      // Reset all video-related states first
      _resetAppState();
      _resetVideoState();
      
      try {
        final file = File(result.files.single.path!);
        if (await file.exists()) {
          _controller = VideoPlayerController.file(file);
          
          await _controller!.initialize();
          
          setState(() {
            _showAnimation = false;
            _controller!.setVolume(0.0);
            _volume = 0.0;
            _previousVolume = 0.1;
            _controller!.addListener(() {
              setState(() {}); // Update the UI on each video frame
            });
          });
          
          _updateSkipStepTime();
        } else {
          throw Exception('Selected video file does not exist');
        }
      } catch (e) {
        print('Error initializing video: $e');
        setState(() {
          _controller?.dispose();
          _controller = null;
        });
        
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text('Failed to load video: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _resetAppState() {
    setState(() {
      _shapes.clear();
      _undoStack.clear();
      _currentShape = null;
      _selectedColor = Colors.lightGreen;
      _strokeWidth = 7.0;
      _selectedShape = ShapeType.line;
      _isMaskMode = false;  // Disable mask mode
      _maskShape = null;    // Clear any existing mask
    });
  }

  void _resetVideoState() {
    setState(() {
      _volume = 0.1;
      _previousVolume = 0.1;
      _isVolumeSliderVisible = false;
      _playbackSpeed = 1.0;
      _isPlaybackSpeedEnabled = true;
      _skipStepTime = const Duration(seconds: 5);
      _isFullScreen = false;
    });
  }

  void _togglePlayPause() {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        _controller!.value.isPlaying
            ? _controller!.pause()
            : _controller!.play();
      });
    }
  }

  void _rewind() {
    if (_controller != null && _controller!.value.isInitialized) {
      final currentPosition = _controller!.value.position;
      final rewindPosition = currentPosition - _skipStepTime;
      _controller!.seekTo(
          rewindPosition > Duration.zero ? rewindPosition : Duration.zero);
    }
  }

  void _forward() {
    if (_controller != null && _controller!.value.isInitialized) {
      final currentPosition = _controller!.value.position;
      final forwardPosition = currentPosition + _skipStepTime;
      _controller!.seekTo(forwardPosition < _controller!.value.duration
          ? forwardPosition
          : _controller!.value.duration);
    }
  }

  void _setPlaybackSpeed(double? speed) {
    if (speed != null && _controller != null) {
      _controller!.setPlaybackSpeed(speed);
    }
  }

  void _changeColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _changeStrokeWidth(double width) {
    setState(() {
      _strokeWidth = width;
    });
  }

  void _undo() {
    setState(() {
      if (_shapes.isNotEmpty) {
        _undoStack.add(_shapes.removeLast());
      }
    });
  }

  void _redo() {
    setState(() {
      if (_undoStack.isNotEmpty) {
        _shapes.add(_undoStack.removeLast());
      }
    });
  }

  void _selectShape(ShapeType shapeType) {
    setState(() {
      _selectedShape = shapeType;
    });
  }

  double _calculateAngle(Offset p1, Offset vertex, Offset p2) {
    final v1 = Offset(p1.dx - vertex.dx, p1.dy - vertex.dy);
    final v2 = Offset(p2.dx - vertex.dx, p2.dy - vertex.dy);

    final dotProduct = v1.dx * v2.dx + v1.dy * v2.dy;
    final magnitude1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
    final magnitude2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy);

    final cosineTheta = dotProduct / (magnitude1 * magnitude2);
    final angleInRadians = acos(cosineTheta);

    return angleInRadians * (180 / pi);
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
      _controller?.setVolume(_volume);
    });
  }

  void _toggleMute() {
    setState(() {
      if (_volume > 0) {
        _previousVolume = _volume;
        _volume = 0.0;
      } else {
        _volume = _previousVolume ?? 0.1;
      }
      _controller?.setVolume(_volume);
    });
  }

  void _seekToPosition(double dx, double width) {
    if (_controller != null && _controller!.value.isInitialized) {
      final duration = _controller!.value.duration;
      final position = dx / width * duration.inMilliseconds;
      _controller!.seekTo(Duration(milliseconds: position.toInt()));
    }
  }

  void _toggleMaskMode() {
    setState(() {
      _isMaskMode = !_isMaskMode;
      // Reset current shape when exiting mask mode
      if (!_isMaskMode) {
        _currentShape = null;
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _updatePlaybackSpeed(double speed) {
    if (_controller != null) {
      setState(() {
        if (!_isPlaybackSpeedEnabled) {
          _playbackSpeed = 1.0;
          _isPlaybackSpeedEnabled = true;
        } else {
          _playbackSpeed = speed;
        }
      });
      _controller!.setPlaybackSpeed(_playbackSpeed);
    }
  }

  void _togglePlaybackSpeed() {
    setState(() {
      _isPlaybackSpeedEnabled = !_isPlaybackSpeedEnabled;
      if (!_isPlaybackSpeedEnabled) {
        _playbackSpeed = 1.0;
        _controller?.setPlaybackSpeed(1.0);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _recordingTimer?.cancel();  // Cancel timer in dispose
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Handle navigation or actions based on index
      switch (index) {
        case HOME_INDEX: // Home
          setState(() {
            _controller?.dispose();
            _controller = null;
            _showAnimation = true; // Reset animation flag when home is clicked
          });
          break;
        case OPEN_VIDEO_INDEX: // Open Video
          _pickVideo();
          break;
        case 2: // Settings
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsPage(
                currentBackgroundColor: widget.backgroundColor,
                onBackgroundColorChanged: widget.onBackgroundColorChanged,
              ),
            ),
          ).then((_) {
            // Reset selected index when returning from Settings
            setState(() {
              _selectedIndex = HOME_INDEX;
            });
          });
          break;
        case 3: // SwimBuddy
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SwimBuddyPage()),
          ).then((_) {
            // Reset selected index when returning from SwimBuddy
            setState(() {
              _selectedIndex = HOME_INDEX;
            });
          });
          break;
        case 4: // About
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AboutPage())
          ).then((_) {
            // Reset selected index when returning from About
            setState(() {
              _selectedIndex = HOME_INDEX;
            });
          });
          break;
        case RECORDINGS_INDEX:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecordingsPage()),
          ).then((_) {
            setState(() {
              _selectedIndex = HOME_INDEX;
            });
          });
          break;
      }
    });
  }

  // Add this method to handle returning home
  void _returnHome() {
    setState(() {
      _controller?.dispose();
      _controller = null;
      _showAnimation = true; // Show the welcome animation again
      _resetAppState(); // Reset all drawing states
      _selectedIndex = HOME_INDEX; // Set selected index to home
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _captureScreenshot() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No video loaded to capture')),
      );
      return;
    }

    // Pause video while taking screenshot
    bool wasPlaying = _controller!.value.isPlaying;
    if (wasPlaying) {
      await _controller!.pause();
    }

    try {
      RenderRepaintBoundary boundary = _screenshotKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();

        // Generate timestamp for unique filename
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Save the screenshot
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/screenshot_$timestamp.png');
        await file.writeAsBytes(pngBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Screenshot saved: ${file.path}'),
              action: SnackBarAction(
                label: 'Open File',
                onPressed: () => _openScreenshotFolder(file.path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error capturing screenshot: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture screenshot')),
        );
      }
    }

    // Resume video if it was playing
    if (wasPlaying) {
      await _controller!.play();
    }
  }

  Future<void> _openScreenshotFolder(String path) async {
    try {
      final Uri uri;
      if (Platform.isWindows) {
        uri = Uri.parse('file:///${path.replaceAll('\\', '/').replaceAll('//', '/')}');
      } else if (Platform.isMacOS) {
        uri = Uri.parse('file://$path');
      } else if (Platform.isLinux) {
        // For Linux, we'll open the parent directory
        final directory = Directory(path).parent.path;
        uri = Uri.parse('file://$directory');
      } else {
        // For other platforms, show a message that this feature isn't supported
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening folders is not supported on this platform')),
          );
        }
        return;
      }

      if (!await launchUrl(uri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open folder')),
          );
        }
      }
    } catch (e) {
      print('Error opening folder: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening folder: $e')),
        );
      }
    }
  }

  void _toggleTriangleToolset() {
    final RenderBox renderBox = _triangleIconKey.currentContext?.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    setState(() {
      _isTriangleToolsetVisible = !_isTriangleToolsetVisible;
      _triangleToolsetPosition = position;
    });
  }

  void _toggleRecording() {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No video loaded to record')),
      );
      return;
    }

    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _startRecording();
      } else {
        _stopRecording();
      }
    });
  }

  void _startRecording() async {
    try {
      // Check platform before attempting to record
      if (!Platform.isMacOS) {  // Add platform check
        final started = await FlutterScreenRecording.startRecordScreen("recording_${DateTime.now().millisecondsSinceEpoch}");
        
        if (started) {
          _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
            setState(() {
              final duration = Duration(seconds: timer.tick);
              _recordingDuration = _formatDuration(duration);
            });
          });
        } else {
          setState(() {
            _isRecording = false;
            _recordingDuration = '00:00';
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to start recording')),
            );
          }
        }
      } else {
        // Show message for macOS users
        setState(() {
          _isRecording = false;
          _recordingDuration = '00:00';
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Screen recording is not supported on macOS')),
          );
        }
      }
    } catch (e) {
      print('Error starting recording: $e');
      setState(() {
        _isRecording = false;
        _recordingDuration = '00:00';
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    setState(() {
      _recordingDuration = '00:00';
      _isRecording = false;
    });

    if (!Platform.isMacOS) {  // Add platform check
      try {
        final path = await FlutterScreenRecording.stopRecordScreen;

        if (context.mounted && path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recording saved to: $path'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => _openScreenshotFolder(path),
              ),
            ),
          );
        }
      } catch (e) {
        print('Error stopping recording: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to stop recording: $e')),
          );
        }
      }
    }
  }

  Future<void> _shareVideo() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No video loaded to share')),
      );
      return;
    }

    try {
      String filePath = _controller!.dataSource;
      if (filePath.startsWith('file://')) {
        filePath = filePath.substring(7);
      }
      
      print('Attempting to share file: $filePath');
      final videoFile = File(filePath);
      
      if (await videoFile.exists()) {
        // Get the render box of the share button
        final RenderBox? buttonBox = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
        
        if (buttonBox != null) {
          final buttonPosition = buttonBox.localToGlobal(Offset.zero);
          final buttonSize = buttonBox.size;
          final bounds = buttonPosition & buttonSize;
          
          print('Button bounds: $bounds');
          print('Button position: $buttonPosition');
          print('Button size: $buttonSize');
          print('Platform: ${Platform.operatingSystem}');
          
          // Share the file with position origin
          if (Platform.isIOS || Platform.isMacOS) {
            await Share.shareXFiles(
              [XFile(videoFile.absolute.path)],
              text: 'Check out this video from CoachEye',
              sharePositionOrigin: bounds,
            );
          } else {
            await Share.shareXFiles(
              [XFile(videoFile.absolute.path)],
              text: 'Check out this video from CoachEye',
            );
          }
        } else {
          print('Button box is null');
          // Fallback to sharing without position
          await Share.shareXFiles(
            [XFile(videoFile.absolute.path)],
            text: 'Check out this video from CoachEye',
          );
        }
      } else {
        print('File does not exist at path: $filePath');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video file not found at: $filePath')),
          );
        }
      }
    } catch (e) {
      print('Error sharing video: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        leading: _controller != null
            ? Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.home, color: Colors.white),
                      onPressed: _returnHome,
                      tooltip: 'Return Home',
                    ),
                    IconButton(
                      icon: Icon(Icons.folder_open_outlined, color: Colors.yellow),
                      onPressed: _pickVideo,
                      tooltip: 'Open Video',
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.yellow),
                      onPressed: _returnHome,
                      tooltip: 'Close Video',
                    ),
                  ],
                ),
              )
            : null,
        leadingWidth: 180, // Adjust this value to fit your icons
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left section
            Expanded(
              flex: 1,
              child: Container(),
            ),
            // Middle section with title and content
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Swimlab Coach\'s Eye',
                    textAlign: TextAlign.center, // Add this
                    style: TextStyle(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  if (_controller != null)
                    Text(
                      'Video Analysis Mode',
                      textAlign: TextAlign.center, // Add this
                      style: TextStyle(
                        color: Colors.yellow[200],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            // Right section
            Expanded(
              flex: 1,
              child: Container(),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_controller != null && _controller!.value.isInitialized) ...[
            // Add share icon before the recording button
            IconButton(
              key: _shareButtonKey,
              icon: Icon(Icons.share, color: Colors.white),
              onPressed: _shareVideo,
              tooltip: 'Share Video',
            ),
            // Recording button
            IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'REC',
                      style: TextStyle(
                        color: _isRecording ? Colors.white : Colors.red,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: _toggleRecording,
            tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
          ),
          if (_isRecording)
            Center(
              child: Text(
                _recordingDuration,
                style: TextStyle(color: Colors.red),
              ),
            ),
            // Add screenshot button to AppBar
            IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.white),
              onPressed: _captureScreenshot,
              tooltip: 'Take Screenshot',
            ),
          ],
        ],
      ),
      body: RepaintBoundary(
        key: _screenshotKey,
        child: Stack(
          children: [
            // Add the home page design when no video is loaded and showing animation
            if (_controller == null && _showAnimation)
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.75),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Text
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: TweenAnimationBuilder(
                            duration: Duration(seconds: 3),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      'Swimming Video Analysis Made Easy',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                        // Wrap both text and logo in a single GestureDetector
                        GestureDetector(
                          onTap: _pickVideo,
                          
                          behavior: HitTestBehavior.opaque, // Add this to ensure taps are caught
                          child: Column(
                            
                            children: [
                              GestureDetector(
                                onTap: _pickVideo,
                                
                                child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Text(
                                  'Click to open a video file',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    decoration: TextDecoration.underline, // Add underline to indicate clickability
                                  ),
                                ),
                              )),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                              // Animated Logo
                              TweenAnimationBuilder(
                                duration: Duration(seconds: 1),
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                builder: (context, double value, child) {
                                  final screenSize = MediaQuery.of(context).size;
                                  final logoSize = math.min(
                                    screenSize.width * 0.4,
                                    screenSize.height * 0.4
                                  );
                                  
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.5),
                                              width: 2,
                                              strokeAlign: BorderSide.strokeAlignOutside,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: CustomPaint(
                                            foregroundPainter: DottedBorderPainter(),
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Image.asset(
                                                'assets/splash.png',
                                                width: logoSize,
                                                height: logoSize,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Add TI dedication text
                        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                        TweenAnimationBuilder(
                          duration: Duration(seconds: 2),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: 'with love to '),
                                    TextSpan(
                                      text: 'Total Immersion',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: ' Swimming'),
                                  ],
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Existing video player and other widgets
            if (_controller != null && _controller!.value.isInitialized && !_showAnimation)
              Positioned.fill(
                child: _isFullScreen
                    ? VideoPlayer(_controller!)
                    : Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
              ),

            // Drawing layers
            if (_isMaskMode)
              Positioned.fill(
                child: CustomPaint(
                  painter: MaskPainter([if (_maskShape != null) _maskShape!], currentShape: _currentShape),
                  child: Container(),
                ),
              ),

            // Drawing overlay
            if (_controller != null && _controller!.value.isInitialized)
              GestureDetector(
                onPanStart: (details) {
                  if (_selectedShape == ShapeType.protractor) {
                    final position = details.localPosition;
                    // Check if we're clicking on an existing protractor
                    for (var shape in _shapes) {
                      if (shape.shapeType == ShapeType.protractor) {
                        final center = shape.points.first;
                        final radius = (shape.points.first - shape.points.last).distance;
                        final distanceFromCenter = (position - center).distance;
                        
                        // Check if we're near the edge (for resizing)
                        if ((distanceFromCenter - radius).abs() < 20) {
                          setState(() {
                            _isResizingProtractor = true;
                            _selectedProtractor = shape;
                            _currentShape = shape;
                          });
                          return;
                        }
                        
                        // Check if we're inside the protractor (for moving)
                        if (distanceFromCenter < radius) {
                          setState(() {
                            _isMovingShape = true;
                            _movingShape = shape;
                            _lastPosition = position;
                          });
                          return;
                        }
                      }
                    }
                    
                    // Create new protractor if not interacting with existing one
                    setState(() {
                      _currentShape = Shape(
                        points: [position, position],
                        color: _selectedColor,
                        strokeWidth: _strokeWidth,
                        shapeType: ShapeType.protractor,
                      );
                    });
                    return;
                  }
                  if (_isMaskMode) {
                    final position = details.localPosition;
                    // If we already have a mask, check if we're clicking near its edge
                    if (_maskShape != null) {
                      final center = _maskShape!.points.first;
                      final radius = (_maskShape!.points.first - _maskShape!.points.last).distance;
                      final distanceFromCenter = (position - center).distance;
                      
                      // Check if we're near the edge (for resizing)
                      if ((distanceFromCenter - radius).abs() < 20) {
                        setState(() {
                          _isResizingMask = true;
                          _currentShape = _maskShape;
                        });
                        return;
                      }
                      
                      // Check if we're inside the circle (for moving)
                      if (distanceFromCenter < radius) {
                        setState(() {
                          _isMovingShape = true;
                          _movingShape = _maskShape;
                          _lastPosition = position;
                        });
                        return;
                      }
                    }
                    
                    // Create new mask only if we don't have one
                    if (_maskShape == null) {
                      setState(() {
                        _currentShape = Shape(
                          points: [position, position],
                          color: Colors.transparent,
                          strokeWidth: 1,
                          shapeType: ShapeType.circle,
                          isMask: true,
                        );
                      });
                    }
                    return;
                  }
                  if (_selectedShape == ShapeType.circle) {
                    final position = details.localPosition;
                    // Check if we're clicking on an existing circle
                    for (var shape in _shapes) {
                      if (shape.shapeType == ShapeType.circle) {
                        final center = shape.points.first;
                        final radius = (shape.points.first - shape.points.last).distance;
                        final distanceFromCenter = (position - center).distance;
                        
                        // Check if we're near the edge (for resizing)
                        if ((distanceFromCenter - radius).abs() < 20) {
                          setState(() {
                            _isResizingCircle = true;
                            _selectedCircle = shape;
                            _currentShape = shape;
                          });
                          return;
                        }
                        
                        // Check if we're inside the circle (for moving)
                        if (distanceFromCenter < radius) {
                          setState(() {
                            _isMovingShape = true;
                            _movingShape = shape;
                            _lastPosition = position;
                          });
                          return;
                        }
                      }
                    }
                    
                    // Create new circle if not interacting with existing one
                    setState(() {
                      _currentShape = Shape(
                        points: [position, position],
                        color: _selectedColor,
                        strokeWidth: _strokeWidth,
                        shapeType: ShapeType.circle,
                      );
                    });
                    return;
                  }
                  if (_selectedShape == ShapeType.triangle) {
                    final position = details.localPosition;
                    // Check if we're clicking on an existing triangle
                    for (var shape in _shapes) {
                      if (shape.shapeType == ShapeType.triangle) {
                        final p1 = shape.points[0];
                        final p2 = shape.points.last;
                        final p3 = Offset(2 * p1.dx - p2.dx, p2.dy);
                        
                        // Check if we're near any vertex for resizing
                        if ((position - p1).distance < 20 || 
                            (position - p2).distance < 20 || 
                            (position - p3).distance < 20) {
                          setState(() {
                            _isResizingTriangle = true;
                            _selectedTriangle = shape;
                            _currentShape = shape;
                          });
                          return;
                        }
                        
                        // Check if we're inside the triangle for moving
                        if (_pointInTriangle(position, p1, p2, p3)) {
                          setState(() {
                            _isMovingShape = true;
                            _movingShape = shape;
                            _lastPosition = position;
                          });
                          return;
                        }
                      }
                    }
                    
                    // Create new triangle if not interacting with existing one
                    setState(() {
                      _currentShape = Shape(
                        points: [position, position],
                        color: _selectedColor,
                        strokeWidth: _strokeWidth,
                        shapeType: ShapeType.triangle,
                      );
                    });
                    return;
                  }
                  if (_selectedShape == ShapeType.rectangle) {
                    final position = details.localPosition;
                    // Check if we're clicking on an existing rectangle
                    for (var shape in _shapes) {
                      if (shape.shapeType == ShapeType.rectangle) {
                        final rect = Rect.fromPoints(shape.points.first, shape.points.last);
                        
                        // Check if we're near any corner (for resizing)
                        if (_isNearCorner(position, rect)) {
                          setState(() {
                            _isResizingRectangle = true;
                            _selectedRectangle = shape;
                            _currentShape = shape;
                          });
                          return;
                        }
                        
                        // Check if we're inside the rectangle (for moving)
                        if (rect.contains(position)) {
                          setState(() {
                            _isMovingShape = true;
                            _movingShape = shape;
                            _lastPosition = position;
                          });
                          return;
                        }
                      }
                    }
                    
                    // Create new rectangle if not interacting with existing one
                    setState(() {
                      _currentShape = Shape(
                        points: [position, position],
                        color: _selectedColor,
                        strokeWidth: _strokeWidth,
                        shapeType: ShapeType.rectangle,
                      );
                    });
                    return;
                  }
                  if (_selectedShape == ShapeType.arrow) {
                    final position = details.localPosition;
                    // Check if we're clicking on an existing arrow
                    for (var shape in _shapes) {
                      if (shape.shapeType == ShapeType.arrow) {
                        final start = shape.points.first;
                        final end = shape.points.last;
                        
                        // Check if we're near either end of the arrow (for resizing)
                        if ((position - start).distance < 20 || (position - end).distance < 20) {
                          setState(() {
                            _isResizingArrow = true;
                            _selectedArrow = shape;
                            _currentShape = shape;
                          });
                          return;
                        }
                        
                        // Check if we're near the arrow line (for moving)
                        if (_isPointNearLine(position, start, end)) {
                          setState(() {
                            _isMovingShape = true;
                            _movingShape = shape;
                            _lastPosition = position;
                          });
                          return;
                        }
                      }
                    }
                    
                    // Create new arrow if not interacting with existing one
                    setState(() {
                      _currentShape = Shape(
                        points: [position, position],
                        color: _selectedColor,
                        strokeWidth: _strokeWidth,
                        shapeType: ShapeType.arrow,
                      );
                    });
                    return;
                  }
                    final position = details.localPosition;
                  // Check if we're clicking on an existing shape
                    for (var shape in _shapes) {
                    if (shape.containsPoint(position)) {
                      setState(() {
                        _isMovingShape = true;
                        _movingShape = shape;
                        _lastPosition = position;
                        // Deselect other shapes
                        for (var s in _shapes) {
                          s.isSelected = false;
                        }
                        shape.isSelected = true;
                      });
                      return;
                    }
                  }
                  
                  // If not clicking on a shape, start drawing a new one
                  setState(() {
                    for (var s in _shapes) {
                      s.isSelected = false;
                    }
                    _currentShape = Shape(
                      points: [position],
                      color: _selectedColor,
                      strokeWidth: _strokeWidth,
                      shapeType: _selectedShape,
                    );
                  });
                },
                onPanUpdate: (details) {
                  if (_selectedShape == ShapeType.protractor) {
                    final position = details.localPosition;
                    if (_isResizingProtractor && _selectedProtractor != null) {
                      setState(() {
                        _selectedProtractor!.points[1] = position; // Update radius
                      });
                      return;
                    }
                    if (_isMovingShape && _movingShape != null && _lastPosition != null) {
                      setState(() {
                        final delta = position - _lastPosition!;
                        _movingShape!.move(delta);
                        _lastPosition = position;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _currentShape!.points[1] = position;
                      });
                    }
                    return;
                  }
                  if (_isMaskMode) {
                    final position = details.localPosition;
                    if (_isResizingMask && _currentShape != null) {
                      setState(() {
                        _currentShape!.points[1] = position; // Update radius
                        _maskShape = _currentShape;
                      });
                      return;
                    }
                    if (_isMovingShape && _movingShape != null && _lastPosition != null) {
                      setState(() {
                        final delta = position - _lastPosition!;
                        _movingShape!.move(delta);
                        _lastPosition = position;
                        _maskShape = _movingShape;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _currentShape!.points[1] = position; // Update radius while creating
                      });
                    }
                    return;
                  }
                  if (_selectedShape == ShapeType.circle) {
                    final position = details.localPosition;
                    if (_isResizingCircle && _selectedCircle != null) {
                      setState(() {
                        _selectedCircle!.points[1] = position; // Update radius
                      });
                      return;
                    }
                    if (_isMovingShape && _movingShape != null && _lastPosition != null) {
                      setState(() {
                        final delta = position - _lastPosition!;
                        _movingShape!.move(delta);
                        _lastPosition = position;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _currentShape!.points[1] = position;
                      });
                    }
                    return;
                  }
                  if (_selectedShape == ShapeType.triangle) {
                    final position = details.localPosition;
                    if (_isResizingTriangle && _selectedTriangle != null) {
                      setState(() {
                        // Update the triangle's base point while keeping the apex fixed
                        _selectedTriangle!.points[1] = position;
                      });
                      return;
                    }
                    if (_isMovingShape && _movingShape != null && _lastPosition != null) {
                      setState(() {
                        final delta = position - _lastPosition!;
                        _movingShape!.move(delta);
                        _lastPosition = position;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _currentShape!.points[1] = position;
                      });
                    }
                    return;
                  }
                  if (_selectedShape == ShapeType.rectangle) {
                    final position = details.localPosition;
                    if (_isResizingRectangle && _selectedRectangle != null) {
                      setState(() {
                        _selectedRectangle!.points[1] = position; // Update corner position
                      });
                      return;
                    }
                    if (_isMovingShape && _movingShape != null && _lastPosition != null) {
                      setState(() {
                        final delta = position - _lastPosition!;
                        _movingShape!.move(delta);
                        _lastPosition = position;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _currentShape!.points[1] = position;
                      });
                    }
                    return;
                  }
                  if (_selectedShape == ShapeType.arrow) {
                    final position = details.localPosition;
                    if (_isResizingArrow && _selectedArrow != null) {
                      setState(() {
                        // Update the nearest end point of the arrow
                        final start = _selectedArrow!.points.first;
                        final end = _selectedArrow!.points.last;
                        if ((position - start).distance < (position - end).distance) {
                          _selectedArrow!.points[0] = position;
                        } else {
                          _selectedArrow!.points[1] = position;
                        }
                      });
                      return;
                    }
                    if (_isMovingShape && _movingShape != null && _lastPosition != null) {
                      setState(() {
                        final delta = position - _lastPosition!;
                        _movingShape!.move(delta);
                        _lastPosition = position;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _currentShape!.points[1] = position;
                      });
                    }
                    return;
                  }
                  final position = details.localPosition;
                  if (_isMovingShape && _movingShape != null && _lastPosition != null) {
                    setState(() {
                      final delta = position - _lastPosition!;
                      _movingShape!.move(delta);
                      _lastPosition = position;
                    });
                  } else if (_currentShape != null) {
                    setState(() {
                      if (_selectedShape == ShapeType.angle) {
                        if (_currentShape!.points.length < 3) {
                          _currentShape!.points.add(position);
                        }
                      } else {
                        _currentShape?.points.add(position);
                      }
                    });
                  }
                },
                onPanEnd: (details) {
                  if (_selectedShape == ShapeType.protractor) {
                    if (_isResizingProtractor) {
                      setState(() {
                        _isResizingProtractor = false;
                        _selectedProtractor = null;
                        _currentShape = null;
                      });
                      return;
                    }
                    if (_isMovingShape) {
                      setState(() {
                        _isMovingShape = false;
                        _movingShape = null;
                        _lastPosition = null;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _shapes.add(_currentShape!);
                        _currentShape = null;
                        _undoStack.clear();
                      });
                    }
                    return;
                  }
                  if (_isMaskMode) {
                    if (_isResizingMask) {
                      setState(() {
                        _isResizingMask = false;
                        _currentShape = null;
                      });
                      return;
                    }
                    if (_isMovingShape) {
                      setState(() {
                        _isMovingShape = false;
                        _movingShape = null;
                        _lastPosition = null;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _maskShape = _currentShape;
                        _currentShape = null;
                      });
                    }
                    return;
                  }
                  if (_selectedShape == ShapeType.circle) {
                    if (_isResizingCircle) {
                      setState(() {
                        _isResizingCircle = false;
                        _selectedCircle = null;
                        _currentShape = null;
                      });
                      return;
                    }
                    if (_isMovingShape) {
                      setState(() {
                        _isMovingShape = false;
                        _movingShape = null;
                        _lastPosition = null;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _shapes.add(_currentShape!);
                        _currentShape = null;
                        _undoStack.clear();
                      });
                    }
                    return;
                  }
                  if (_selectedShape == ShapeType.triangle) {
                    if (_isResizingTriangle) {
                      setState(() {
                        _isResizingTriangle = false;
                        _selectedTriangle = null;
                        _currentShape = null;
                      });
                      return;
                    }
                    if (_isMovingShape) {
                      setState(() {
                        _isMovingShape = false;
                        _movingShape = null;
                        _lastPosition = null;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _shapes.add(_currentShape!);
                        _currentShape = null;
                        _undoStack.clear();
                      });
                    }
                    return;
                  }
                  if (_selectedShape == ShapeType.rectangle) {
                    if (_isResizingRectangle) {
                      setState(() {
                        _isResizingRectangle = false;
                        _selectedRectangle = null;
                        _currentShape = null;
                      });
                      return;
                    }
                    if (_isMovingShape) {
                      setState(() {
                        _isMovingShape = false;
                        _movingShape = null;
                        _lastPosition = null;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _shapes.add(_currentShape!);
                        _currentShape = null;
                        _undoStack.clear();
                      });
                    }
                    return;
                  }
                  if (_selectedShape == ShapeType.arrow) {
                    if (_isResizingArrow) {
                      setState(() {
                        _isResizingArrow = false;
                        _selectedArrow = null;
                        _currentShape = null;
                      });
                      return;
                    }
                    if (_isMovingShape) {
                      setState(() {
                        _isMovingShape = false;
                        _movingShape = null;
                        _lastPosition = null;
                      });
                      return;
                    }
                    if (_currentShape != null) {
                      setState(() {
                        _shapes.add(_currentShape!);
                        _currentShape = null;
                        _undoStack.clear();
                      });
                    }
                    return;
                  }
                  if (_isMovingShape) {
                    setState(() {
                      _isMovingShape = false;
                      _movingShape = null;
                      _lastPosition = null;
                    });
                  } else if (_currentShape != null) {
                    setState(() {
                      _shapes.add(_currentShape!);
                      _currentShape = null;
                      _undoStack.clear();
                    });
                  }
                },
                child: MouseRegion(
                  cursor: _isMaskMode ? SystemMouseCursors.click : MouseCursor.defer,
                  child: CustomPaint(
                    painter: DrawingPainter(
                      _shapes,
                      _currentShape,
                      _calculateAngle,
                      showTriangleAngles: _showTriangleAngles,
                    ),
                    child: Container(),
                  ),
                ),
              ),

            // Playback controls - Only show when video is loaded
            if (_controller != null && _controller!.value.isInitialized) ...[
              // Volume slider
              if (_isVolumeSliderVisible)
                Positioned(
                  top: 305, // Align with the speaker icon
                  left: 50, // Place beside the sidebar
                  child: Container(
                    width: 300, // Adjust slider width
                    height: 40,
                    color: Colors.black.withOpacity(0.5), // Background for slider
                    child: Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: _setVolume,
                            activeColor: Colors.red,
                            inactiveColor: Colors.grey,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isVolumeSliderVisible = false; // Close slider
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // Tools bar
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Container(
                  height: 56, // Explicit height for the toolbar
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Add consistent spacing between icons
                        SizedBox(width: 4),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.restart_alt, 
                                  color: _isMaskMode ? Colors.grey : (_shapes.isEmpty ? Colors.grey : Colors.white)
                                ),
                                onPressed: _isMaskMode ? null : (_shapes.isEmpty ? null : _resetAppState),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.undo, 
                                  color: _isMaskMode ? Colors.grey : (_shapes.isEmpty ? Colors.grey : Colors.white)
                                ),
                                onPressed: _isMaskMode ? null : (_shapes.isEmpty ? null : _undo),
                                tooltip: 'Undo',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.redo, 
                                  color: _isMaskMode ? Colors.grey : (_undoStack.isEmpty ? Colors.grey : Colors.white)
                                ),
                                onPressed: _isMaskMode ? null : (_undoStack.isEmpty ? null : _redo),
                                tooltip: 'Redo',
                              ),
                              VerticalDivider(
                                color: Colors.grey,
                                thickness: 1,
                                indent: 8,
                                endIndent: 8,
                                width: 20,
                              ),
                              IconButton(
                                icon: Icon(Icons.color_lens, 
                                  color: _isMaskMode ? Colors.grey : Colors.yellow[500]
                                ),
                                onPressed: _isMaskMode ? null : () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Pick a color'),
                                        content: BlockPicker(
                                          pickerColor: _selectedColor,
                                          onColorChanged: _changeColor,
                                        ),
                                        actions: [
                                          TextButton(
                                            child: Text('Done'),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _selectedShape == ShapeType.line && !_isMaskMode
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                child: IconButton(
                                  // Add padding and constraints to control icon spacing
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  icon: Icon(
                                    Icons.line_axis,
                                    color: _isMaskMode ? Colors.grey : Colors.green[500],
                                    // Explicitly set icon size
                                    size: 24,
                                  ),
                                  onPressed: _isMaskMode ? null : () => _selectShape(ShapeType.line),
                                  tooltip: 'Line',
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _selectedShape == ShapeType.curve && !_isMaskMode
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  icon: SvgPicture.asset(
                                    'assets/line_curve.svg',
                                    color: _isMaskMode ? Colors.grey : Colors.purple[300],
                                    width: 24,
                                    height: 24,
                                    // Add fit property to ensure proper scaling
                                    fit: BoxFit.contain,
                                  ),
                                  onPressed: _isMaskMode ? null : () => _selectShape(ShapeType.curve),
                                  tooltip: 'Curve',
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _selectedShape == ShapeType.arrow && !_isMaskMode
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.arrow_back,
                                    color: _isMaskMode ? Colors.grey : Colors.white
                                  ),
                                  onPressed: _isMaskMode ? null : () => _selectShape(ShapeType.arrow),
                                  tooltip: 'Arrow',
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _selectedShape == ShapeType.rectangle && !_isMaskMode
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.crop_square,
                                    color: _isMaskMode ? Colors.grey : Colors.red[200]
                                  ),
                                  onPressed: _isMaskMode ? null : () => _selectShape(ShapeType.rectangle),
                                  tooltip: 'Rectangle',
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _selectedShape == ShapeType.circle && !_isMaskMode
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.circle_outlined, color: _isMaskMode ? Colors.grey : Colors.orange[500]),
                                  onPressed: _isMaskMode ? null : () => _selectShape(ShapeType.circle),
                                  tooltip: 'Circle',
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _selectedShape == ShapeType.triangle && !_isMaskMode
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                child: IconButton(
                                  key: _triangleIconKey,
                                  icon: Icon(Icons.change_history,
                                    color: _isMaskMode ? Colors.grey : Colors.blue[500]
                                  ),
                                  onPressed: _isMaskMode ? null : () {
                                    _selectShape(ShapeType.triangle);
                                    _toggleTriangleToolset();
                                  },
                                  tooltip: 'Triangle',
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _selectedShape == ShapeType.protractor && !_isMaskMode
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.architecture, // Using architecture icon for protractor
                                    color: _isMaskMode ? Colors.grey : Colors.blue[200]
                                  ),
                                  onPressed: _isMaskMode ? null : () => _selectShape(ShapeType.protractor),
                                  tooltip: 'Protractor',
                                ),
                              ),
                              VerticalDivider(
                                color: Colors.grey,
                                thickness: 1,
                                indent: 8,
                                endIndent: 8,
                                width: 20,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _isStrokeWidthSliderVisible && !_isMaskMode
                                    ? Colors.black.withOpacity(0.5)
                                    : Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                child: IconButton(
                                  key: _strokeWidthIconKey,
                                  icon: Icon(
                                    Icons.line_weight, 
                                    color: _isMaskMode ? Colors.grey : Colors.white
                                  ),
                                  onPressed: _isMaskMode ? null : () {
                                    final RenderBox renderBox = _strokeWidthIconKey.currentContext?.findRenderObject() as RenderBox;
                                    final position = renderBox.localToGlobal(Offset.zero);
                                    setState(() {
                                      _isStrokeWidthSliderVisible = !_isStrokeWidthSliderVisible;
                                      _strokeWidthPosition = position;
                                    });
                                  },
                                  tooltip: 'Adjust Stroke Width',
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: _isMaskMode
                                      ? Colors.black.withOpacity(0.5)
                                      : Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.flashlight_on,
                                    color: _isMaskMode ? Colors.yellow : Colors.yellow,
                                  ),
                                  onPressed: _toggleMaskMode,
                                  tooltip: 'Toggle Mask Mode',
                                ),
                              ),
                              
                            ],
                          ),
                        ),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),

              // Stroke Width Slider
              if (_isStrokeWidthSliderVisible && _strokeWidthPosition != null)
                Positioned(
                  left: _strokeWidthPosition!.dx - 0, // Center on the icon
                  bottom: MediaQuery.of(context).size.height - _strokeWidthPosition!.dy,
                  child: Container(
                    width: 40,
                    height: 200,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() {
                              _isStrokeWidthSliderVisible = false;
                            });
                          },
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: _strokeWidth,
                              min: 1.0,
                              max: 30.0,
                              onChanged: _changeStrokeWidth,
                              activeColor: _selectedColor,
                              inactiveColor: Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          _strokeWidth.toStringAsFixed(1),
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

              // Triangle Toolset
              if (_isTriangleToolsetVisible && _triangleToolsetPosition != null)
                Positioned(
                  left: _triangleToolsetPosition!.dx - 0, // Adjust position as needed
                  bottom: MediaQuery.of(context).size.height - _triangleToolsetPosition!.dy + 0,
                  child: Container(
                    width: 100,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      //borderRadius: BorderRadius.circular(8),
                      //border: Border.all(color: Colors.blue[500]!, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
          
                      children: [
                        Row( 
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Change to spaceBetween
                          children: [
                            // Text(
                            //   'Triangle Tools',
                            //   style: TextStyle(color: Colors.white, fontSize: 14),
                            // ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: _toggleTriangleToolset,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        Divider(color: Colors.grey, height: 16),
                        Row(
                          
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _showTriangleAngles ? Icons.architecture : Icons.architecture,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showTriangleAngles = !_showTriangleAngles;
                                    });
                                  },
                                  tooltip: _showTriangleAngles ? 'Hide Angles' : 'Show Angles',
                                ),
                                // Text(
                                //   'Toggle Angles',
                                //   style: TextStyle(color: Colors.white, fontSize: 12),
                                // ),
                              ],
                            ),
                            // Add more triangle-specific tools here
                            // For example:
                            // Column(
                            //   children: [
                            //     IconButton(
                            //       icon: Icon(
                            //         Icons.rotate_right,
                            //         color: Colors.blue[500],
                            //       ),
                            //       onPressed: () {
                            //         // Add rotation functionality
                            //       },
                            //       tooltip: 'Rotate Triangle',
                            //     ),
                            //     Text(
                            //       'Rotate',
                            //       style: TextStyle(color: Colors.white, fontSize: 12),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom Toolbar for Playback Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                          thumbColor: Colors.white,
                          overlayColor: Colors.white.withOpacity(0.3),
                        ),
                        child: Slider(
                          value: _controller!.value.position.inMilliseconds.toDouble(),
                          min: 0,
                          max: _controller!.value.duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            _controller!.seekTo(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      
                      // Modified Controls row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side controls with added skip buttons
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.skip_previous, color: Colors.white),
                                onPressed: () => _controller!.seekTo(Duration.zero),
                                tooltip: 'Start',
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () {
                                  _rewind();
                                },
                                tooltip: 'Rewind',
                              ),
                              IconButton(
                                icon: Icon(
                                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward, color: Colors.white),
                                onPressed: () {
                                  _forward();
                                },
                                tooltip: 'Forward',
                              ),
                              IconButton(
                                icon: Icon(Icons.skip_next, color: Colors.white),
                                onPressed: () => _controller!.seekTo(_controller!.value.duration),
                                tooltip: 'End',
                              ),
                              IconButton(
                                icon: Icon(
                                  _volume == 0 ? Icons.volume_off : Icons.volume_up,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleMute,
                              ),
                              SizedBox(
                                width: 100,
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 2,
                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: _volume,
                                    min: 0,
                                    max: 1,
                                    onChanged: _setVolume,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      color: _isPlaybackSpeedEnabled ? Colors.white : Colors.grey,
                                    ),
                                    if (!_isPlaybackSpeedEnabled)
                                      Transform.rotate(
                                        angle: -pi / 4,
                                        child: Container(
                                          width: 24,
                                          height: 2,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                                onPressed: _togglePlaybackSpeed,
                                tooltip: 'Toggle Playback Speed',
                              ),
                              Container(
                                width: 150,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: SliderTheme(
                                        data: SliderThemeData(
                                          trackHeight: 2,
                                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                          overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                                          activeTrackColor: Colors.white,
                                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                                          thumbColor: Colors.white,
                                        ),
                                        child: Slider(
                                          value: _playbackSpeed,
                                          min: _speedOptions.first,
                                          max: _speedOptions.last,
                                          onChanged: _isPlaybackSpeedEnabled ? _updatePlaybackSpeed : null,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_playbackSpeed.toStringAsFixed(2)}x',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Right side controls remain the same
                          Row(
                            children: [
                              Text(
                                '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(width: 16),
                              IconButton(
                                icon: Icon(Icons.settings, color: Colors.white),
                                onPressed: () {
                                  // Add settings menu functionality
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleFullScreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Play/Pause overlay
              if (!_controller!.value.isPlaying && _shapes.isEmpty && _currentShape == null)
                Positioned.fill(
                  child: Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(24),
                          child: Icon(
                            Icons.play_arrow,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _controller == null || !_controller!.value.isInitialized
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                    backgroundColor: Colors.black87,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.video_library),
                    label: 'Open Video',
                    backgroundColor: Colors.black87,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                    backgroundColor: Colors.black87,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.pool),
                    label: 'SwimBuddy',
                    backgroundColor: Colors.black87,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.info_outline),
                    label: 'About',
                    backgroundColor: Colors.black87,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.videocam),
                    label: 'Recordings',
                    backgroundColor: Colors.black87,
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.yellow,
                unselectedItemColor: Colors.grey,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.black87,
              ),
            )
          : null, // Hide bottom navigation when video is loaded
    );
  }

  bool _pointInTriangle(Offset p, Offset v1, Offset v2, Offset v3) {
    double area = 0.5 * (-v2.dy * v3.dx + v1.dy * (-v2.dx + v3.dx) +
        v1.dx * (v2.dy - v3.dy) + v2.dx * v3.dy);
    double s = 1 / (2 * area) *
        (v1.dy * v3.dx - v1.dx * v3.dy +
            (v3.dy - v1.dy) * p.dx +
            (v1.dx - v3.dx) * p.dy);
    double t = 1 / (2 * area) *
        (v1.dx * v2.dy - v1.dy * v2.dx +
            (v1.dy - v2.dy) * p.dx +
            (v2.dx - v1.dx) * p.dy);
    return s >= 0 && t >= 0 && (1 - s - t) >= 0;
  }

  bool _isNearCorner(Offset point, Rect rect, [double threshold = 20.0]) {
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];
    
    return corners.any((corner) => (point - corner).distance < threshold);
  }

  bool _isPointNearLine(Offset point, Offset start, Offset end, [double threshold = 20.0]) {
    final length = (end - start).distance;
    if (length == 0) return false;
    
    final d = ((point.dx - start.dx) * (end.dx - start.dx) +
            (point.dy - start.dy) * (end.dy - start.dy)) /
        (length * length);
    
    if (d < 0 || d > 1) return false;
    
    final projection = Offset(
      start.dx + d * (end.dx - start.dx),
      start.dy + d * (end.dy - start.dy),
    );
    return (point - projection).distance < threshold;
  }
}

class PlayPauseIntent extends Intent {}

class RewindIntent extends Intent {}

class ForwardIntent extends Intent {}

class ProgressBarPainter extends CustomPainter {
  final Duration progress;
  final Duration duration;

  ProgressBarPainter({required this.progress, required this.duration});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.grey.shade400;
    final progressPaint = Paint()..color = Colors.red;
    final markerPaint = Paint()..color = Colors.white;

    // Draw the background line
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2 - 2, size.width, 8), // Centered background
      backgroundPaint,
    );

    // Draw the progress line
    if (duration.inMilliseconds > 0) {
      final double progressWidth =
          (progress.inMilliseconds / duration.inMilliseconds) * size.width;
      canvas.drawRect(
        Rect.fromLTWH(0, size.height / 2 - 2, progressWidth, 8), // Centered progress
        progressPaint,
      );
    }

    // Draw the markers with varying heights
    const int markerCount = 70; // Number of markers
    final waveFrequency = 50; // Frequency of the wave
    final waveAmplitude = size.height * .8; // Amplitude of the wave

    for (int i = 0; i <= markerCount; i++) {
      final double dx = (i / markerCount) * size.width;
      final double dy = size.height / 2 +
          waveAmplitude * sin((i / markerCount) * waveFrequency * 0.3 * pi);
      final double markerHeight = dy - size.height / 2;

      canvas.drawLine(
        Offset(dx, size.height / 2 - markerHeight / 2),
        Offset(dx, size.height / 2 + markerHeight / 2),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Shape {
  List<Offset> points;
  Color color;
  double strokeWidth;
  ShapeType shapeType;
  bool isSelected;
  Offset? dragOffset;
  final bool isMask;

  Shape({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.shapeType,
    this.isSelected = false,
    this.dragOffset,
    this.isMask = false,
  });

  bool containsPoint(Offset point) {
    switch (shapeType) {
      case ShapeType.line:
      case ShapeType.arrow:
        return _isPointNearLine(point, points.first, points.last);
      case ShapeType.rectangle:
        return _isPointInRectangle(point);
      case ShapeType.circle:
        return _isPointInCircle(point);
      case ShapeType.triangle:
        return _isPointInTriangle(point);
      case ShapeType.curve:
        return _isPointNearCurve(point);
      case ShapeType.protractor:
        return _isPointInProtractor(point);
      default:
        return false;
    }
  }

  bool _isPointNearLine(Offset point, Offset start, Offset end, [double threshold = 20.0]) {
    final length = (end - start).distance;
    final d = ((point.dx - start.dx) * (end.dx - start.dx) +
            (point.dy - start.dy) * (end.dy - start.dy)) /
        (length * length);
    
    if (d < 0 || d > 1) return false;
    
    final projection = Offset(
      start.dx + d * (end.dx - start.dx),
      start.dy + d * (end.dy - start.dy),
    );
    return (point - projection).distance < threshold;
  }

  bool _isPointInRectangle(Offset point) {
    final rect = Rect.fromPoints(points.first, points.last);
    return rect.contains(point);
  }

  bool _isPointInCircle(Offset point) {
    final center = points.first;
    final radius = (points.first - points.last).distance;
    return (point - center).distance <= radius;
  }

  bool _isPointInTriangle(Offset point) {
    if (points.length < 2) return false;
    final p1 = points[0];
    final p2 = points.last;
                      final p3 = Offset(2 * p1.dx - p2.dx, p2.dy);
                      
    return _pointInTriangle(point, p1, p2, p3);
  }

  bool _pointInTriangle(Offset p, Offset v1, Offset v2, Offset v3) {
    double area = 0.5 * (-v2.dy * v3.dx + v1.dy * (-v2.dx + v3.dx) +
        v1.dx * (v2.dy - v3.dy) + v2.dx * v3.dy);
    double s = 1 / (2 * area) *
        (v1.dy * v3.dx - v1.dx * v3.dy +
            (v3.dy - v1.dy) * p.dx +
            (v1.dx - v3.dx) * p.dy);
    double t = 1 / (2 * area) *
        (v1.dx * v2.dy - v1.dy * v2.dx +
            (v1.dy - v2.dy) * p.dx +
            (v2.dx - v1.dx) * p.dy);
    return s >= 0 && t >= 0 && (1 - s - t) >= 0;
  }

  bool _isPointNearCurve(Offset point) {
    const threshold = 20.0;
    for (int i = 1; i < points.length; i++) {
      if (_isPointNearLine(point, points[i - 1], points[i], threshold)) {
        return true;
      }
    }
    return false;
  }

  bool _isPointInProtractor(Offset point) {
    if (points.length < 2) return false;
    final center = points.first;
    final radius = (points.first - points.last).distance;
    
    // Check if point is within the protractor's circle area
    return (point - center).distance <= radius;
  }

  void move(Offset delta) {
    for (int i = 0; i < points.length; i++) {
      points[i] = points[i] + delta;
    }
  }

  // Add a method to calculate angles for triangle
  List<double> calculateTriangleAngles() {
    if (shapeType != ShapeType.triangle || points.length < 2) return [];
    
    final p1 = points[0];  // apex
    final p2 = points.last;  // base right point
    final p3 = Offset(2 * p1.dx - p2.dx, p2.dy);  // base left point
    
    // Calculate vectors
    final a = (p2 - p1).distance;  // side length from apex to right
    final b = (p3 - p1).distance;  // side length from apex to left
    final c = (p3 - p2).distance;  // base length
    
    // Calculate angles using law of cosines
    final angleA = acos((b * b + c * c - a * a) / (2 * b * c)) * 180 / pi;
    final angleB = acos((a * a + c * c - b * b) / (2 * a * c)) * 180 / pi;
    final angleC = 180 - angleA - angleB;  // angles in triangle sum to 180°
    
    return [angleA, angleB, angleC];
  }
}

class DrawingPainter extends CustomPainter {
  final List<Shape> shapes;
  final Shape? currentShape;
  final double Function(Offset, Offset, Offset)? calculateAngle;
  final bool showTriangleAngles; // Add this property

  DrawingPainter(
    this.shapes, 
    this.currentShape, 
    this.calculateAngle, 
    {this.showTriangleAngles = true} // Default to true for backward compatibility
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (var shape in shapes) {
      _drawShape(canvas, shape);
    }
    if (currentShape != null) {
      _drawShape(canvas, currentShape!);
    }
  }

  void _drawShape(Canvas canvas, Shape shape) {
    final paint = Paint()
      ..color = shape.color
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw selection indicator if shape is selected
    if (shape.isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..strokeWidth = paint.strokeWidth + 4
        ..style = PaintingStyle.stroke;
      _drawShapeWithPaint(canvas, shape, selectionPaint);
    }

    _drawShapeWithPaint(canvas, shape, paint);
  }

  void _drawShapeWithPaint(Canvas canvas, Shape shape, Paint paint) {
    if (shape.shapeType == ShapeType.line) {
      if (shape.points.length >= 2) {
        canvas.drawLine(shape.points.first, shape.points.last, paint);
      }
    } else if (shape.shapeType == ShapeType.rectangle) {
      _drawRectangle(canvas, shape.points, paint);
    } else if (shape.shapeType == ShapeType.arrow) {
      _drawArrow(canvas, shape.points, paint);
    } else if (shape.shapeType == ShapeType.circle) {
      _drawCircle(canvas, shape.points, paint);
    } else if (shape.shapeType == ShapeType.triangle) {
      _drawTriangle(canvas, shape.points, paint);
    } else if (shape.shapeType == ShapeType.curve) {
      _drawCurve(canvas, shape.points, paint);
    } else if (shape.shapeType == ShapeType.angle) {
      _drawAngle(canvas, shape.points, paint);
    } else if (shape.shapeType == ShapeType.protractor) {
      _drawProtractor(canvas, shape.points, paint);
    }
  }

  void _drawRectangle(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length >= 2) {
      final rect = Rect.fromPoints(points.first, points.last);

      // Draw outer border
      final outerPaint = Paint()
        ..color = Colors.black.withOpacity(1)
        ..strokeWidth = paint.strokeWidth - 1
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect.inflate(1), outerPaint);

      // Draw inner border
      final innerPaint = Paint()
        ..color = Colors.black.withOpacity(1)
        ..strokeWidth = paint.strokeWidth - 1
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect.deflate(1), innerPaint);

      // Draw the main rectangle
      canvas.drawRect(rect, paint);
    }
  }


  void _drawArrow(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length >= 2) {
      final p1 = points.first;
      final p2 = points.last;
      canvas.drawLine(p1, p2, paint);

      // Calculate the arrowhead points
      const arrowHeadLength = 10.0;
      const arrowHeadAngle = pi / 6;

      final angle = atan2(p2.dy - p1.dy, p2.dx - p1.dx);
      final path = Path()
        ..moveTo(p2.dx, p2.dy)
        ..lineTo(
          p2.dx - arrowHeadLength * cos(angle - arrowHeadAngle),
          p2.dy - arrowHeadLength * sin(angle - arrowHeadAngle),
        )
        ..lineTo(
          p2.dx - arrowHeadLength * cos(angle + arrowHeadAngle),
          p2.dy - arrowHeadLength * sin(angle + arrowHeadAngle),
        )
        ..close();

      // Draw outer border
      final outerPaint = Paint()
        ..color = Colors.black.withOpacity(1)
        ..strokeWidth = paint.strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, outerPaint);

      // Draw inner border
      final innerPaint = Paint()
        ..color = Colors.black.withOpacity(1)
        ..strokeWidth = paint.strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, innerPaint);

      // Draw the main arrow
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  void _drawCircle(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length >= 2) {
      final center = points.first;
      final radius = (points.first - points.last).distance;

      // Draw outer border
      final outerPaint = Paint()
        ..color = Colors.black.withOpacity(1)
        ..strokeWidth = paint.strokeWidth - 1
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius + 1, outerPaint);

      // Draw inner border
      final innerPaint = Paint()
        ..color = Colors.black.withOpacity(1)
        ..strokeWidth = paint.strokeWidth - 1
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius - 1, innerPaint);

      // Draw the main circle
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawTriangle(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length >= 2) {
      final p1 = points[0];  // apex
      final p2 = points.last;  // base right point
      final p3 = Offset(2 * p1.dx - p2.dx, p2.dy);  // base left point
      
      // Draw the triangle
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, paint);
      
      // Only draw angles if showTriangleAngles is true
      if (showTriangleAngles) {
        final angles = Shape(
          points: points,
          color: paint.color,
          strokeWidth: paint.strokeWidth,
          shapeType: ShapeType.triangle
        ).calculateTriangleAngles();
        
        if (angles.length == 3) {
          final textStyle = TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          );
          
          _drawAngleText(canvas, p1, angles[0], textStyle, paint.color);
          _drawAngleText(canvas, p2, angles[1], textStyle, paint.color);
          _drawAngleText(canvas, p3, angles[2], textStyle, paint.color);
        }
      }
    }
  }

  void _drawAngleText(Canvas canvas, Offset position, double angle, TextStyle style, Color shapeColor) {
    final text = '${angle.toStringAsFixed(1)}°';
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Draw background for better visibility
    final bgRect = Rect.fromCenter(
      center: Offset(
        position.dx,
        position.dy,
      ),
      width: textPainter.width + 16,
      height: textPainter.height + 8,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(4)),
      Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
    
    // Draw border in shape color
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(4)),
      Paint()
        ..color = shapeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawCurve(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawAngle(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length == 3) {
      canvas.drawLine(points[0], points[1], paint);
      canvas.drawLine(points[1], points[2], paint);

      if (calculateAngle != null) {
        final angle = calculateAngle!(points[0], points[1], points[2]);
        final angleText = "${angle.toStringAsFixed(1)}°";

        TextPainter(
          text: TextSpan(
            text: angleText,
            style: TextStyle(color: paint.color, fontSize: 16),
          ),
          textDirection: TextDirection.ltr,
        )
          ..layout()
          ..paint(canvas, points[1]);
      }
    }
  }

  void _drawProtractor(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length >= 2) {
      final center = points.first;
      final radius = (points.first - points.last).distance;
      
      // Create a thinner paint for the protractor lines
      final thinPaint = Paint()
        ..color = paint.color
        ..strokeWidth = 5.0  // Reduced from original strokeWidth
        ..style = PaintingStyle.stroke;
      
      // Draw the main circle
      canvas.drawCircle(center, radius, thinPaint);
      
      // Draw angle markers every 10 degrees
      for (int angle = 0; angle < 360; angle += 10) {
        final radian = angle * pi / 180;
        final startPoint = Offset(
          center.dx + radius * cos(radian),
          center.dy + radius * sin(radian)
        );
        
        // Longer lines for major angles (30°)
        final lineLength = angle % 30 == 0 ? radius * 0.15 : radius * 0.1;
        final endPoint = Offset(
          center.dx + (radius - lineLength) * cos(radian),
          center.dy + (radius - lineLength) * sin(radian)
        );
        
        canvas.drawLine(startPoint, endPoint, thinPaint);
        
        // Draw angle numbers for every 30 degrees
        if (angle % 30 == 0) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '$angle°',
              style: TextStyle(
                color: paint.color,
                fontSize: 12,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          
          final textPoint = Offset(
            center.dx + (radius - lineLength - 20) * cos(radian) - textPainter.width / 2,
            center.dy + (radius - lineLength - 20) * sin(radian) - textPainter.height / 2,
          );
          
          textPainter.paint(canvas, textPoint);
        }
      }
      
      // Draw crosshairs at center with thin lines
      canvas.drawLine(
        Offset(center.dx - 10, center.dy),
        Offset(center.dx + 10, center.dy),
        thinPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - 10),
        Offset(center.dx, center.dy + 10),
        thinPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class MaskPainter extends CustomPainter {
  final List<Shape> masks;
  final Shape? currentShape;

  MaskPainter(this.masks, {this.currentShape});

  @override
  void paint(Canvas canvas, Size size) {
    final maskPath = Path();
    maskPath.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    for (var mask in masks) {
      if (mask.points.length >= 2) {
        final center = mask.points.first;
        final radius = (mask.points.first - mask.points.last).distance;
        maskPath.addOval(Rect.fromCircle(center: center, radius: radius));
      }
    }

    // Draw the green outline only for the shape being currently drawn
    if (currentShape != null && currentShape!.points.length >= 2) {
      final center = currentShape!.points.first;
      final radius = (currentShape!.points.first - currentShape!.points.last).distance;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
      );
    }

    maskPath.fillType = PathFillType.evenOdd;
    canvas.drawPath(
      maskPath,
      Paint()
        ..color = Colors.black.withOpacity(0.75),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashWidth = 6;
    final dashSpace = 4;
    final radius = 12.0;

    // Create a path for rounded rectangle
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    // Convert the path to a dotted line
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        if (distance + dashWidth > metric.length) {
          // Draw remaining space if less than dash width
          canvas.drawPath(
            metric.extractPath(distance, metric.length),
            paint,
          );
          break;
        }
        
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


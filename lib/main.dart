import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';


void main() {
  runApp(CoachEye());
}

class CoachEye extends StatelessWidget {
  const CoachEye({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 71, 74, 77), // Set global background color
      ),
      home: VideoEditorScreen(),
    );
  }
}

enum ShapeType { line, arrow, rectangle, circle, triangle, curve, angle }

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  _VideoEditorScreenState createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  Color _selectedColor = Colors.greenAccent;
  double _strokeWidth = 10.0;
  ShapeType _selectedShape = ShapeType.line;
  final List<Shape> _shapes = [];
  final List<Shape> _undoStack = [];
  Shape? _currentShape;
  double _volume = 0.1;
  double? _previousVolume;
  bool _isVolumeSliderVisible = false; // To toggle the volume slider visibility
  bool _isMovingShape = false;
  Shape? _movingShape;
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      _resetAppState();
      _controller = VideoPlayerController.file(File(result.files.single.path!))
        ..initialize().then((_) {
          setState(() {});
          _controller!.setVolume(_volume); // Set initial volume to 30%
          //_controller!.play();
          _controller!.addListener(() {
            setState(() {}); // Update the UI on each video frame
          });
        });
    }
  }

  void _resetAppState() {
    setState(() {
      _shapes.clear();
      _undoStack.clear();
      _currentShape = null;
      _selectedColor = Colors.green;
      _strokeWidth = 7.0;
      _selectedShape = ShapeType.line;
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
      final rewindPosition = currentPosition - Duration(seconds: 5);
      _controller!.seekTo(
          rewindPosition > Duration.zero ? rewindPosition : Duration.zero);
    }
  }

  void _forward() {
    if (_controller != null && _controller!.value.isInitialized) {
      final currentPosition = _controller!.value.position;
      final forwardPosition = currentPosition + Duration(seconds: 5);
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Color.fromARGB(0, 255,255,255), // Makes the AppBar background transparent
        title: Text(
          'Swimlab Coach\'s Eye',
          style: TextStyle(
              color: const Color.fromARGB(255, 255, 255,
                  255)), // Ensure text is visible on transparency
        ),
        elevation: 0, // Removes the shadow under the AppBar
        centerTitle: true, // Centers the AppBar title
        actions: [],
      ),
      body: _controller == null || !_controller!.value.isInitialized
          ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Widget
              Image.asset(
                'assets/logo-white.png', // Add your logo file to assets and update path
                width: 300,
                height: 300,
              ),
              SizedBox(height: 20),
              // "Open Video" Button
              ElevatedButton(
                onPressed: _pickVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow, // Set background color to yellow
                  minimumSize: Size(200, 50), // Set width and height
                ),
                child: Text('Open Video'),
              ),
            ],
          ),
        )
      :  Stack(
              children: [
                
               // Ensure Video Player Fills the Screen
              Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),

                // Drawing/Annotation Overlay
                GestureDetector(
                  onPanStart: (details) {
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
                  child: CustomPaint(
                    painter: DrawingPainter(
                      _shapes,
                      _currentShape,
                      _calculateAngle,
                    ),
                    child: Container(),
                  ),
                ),


// Left Sidebar with Playback and Volume Controls
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 50,
                    color: Colors.black.withOpacity(0.5), // Add transparency
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.folder_open_outlined, color: Colors.yellow),
                          onPressed: _pickVideo,
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.yellow),
                          onPressed: () {
                            setState(() {
                              _controller?.dispose();
                              _controller = null;
                            });
                          },
                          tooltip: 'Close Video',
                        ),
                        Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_previous, color: Colors.white),
                          onPressed: () {
                            if (_controller != null &&
                                _controller!.value.isInitialized) {
                              _controller!.seekTo(Duration.zero);
                            }
                          },
                          tooltip: 'Restart Video',
                        ),
                        IconButton(
                          icon: Icon(Icons.replay_10, color: Colors.white),
                          onPressed: () {
                            if (_controller != null &&
                                _controller!.value.isInitialized) {
                              _controller!.seekTo(_controller!.value.position -
                                  Duration(seconds: 10));
                            }
                          },
                          tooltip: 'Rewind 10 seconds',
                        ),
                        IconButton(
                          icon: Icon(
                            _controller != null && _controller!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayPause,
                          tooltip: 'Play/Pause',
                        ),
                        IconButton(
                          icon: Icon(Icons.forward_10, color: Colors.white),
                          onPressed: () {
                            if (_controller != null &&
                                _controller!.value.isInitialized) {
                              _controller!.seekTo(_controller!.value.position +
                                  Duration(seconds: 10));
                            }
                          },
                          tooltip: 'Forward 10 seconds',
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next, color: Colors.white),
                          onPressed: () {
                            if (_controller != null &&
                                _controller!.value.isInitialized) {
                              _controller!.seekTo(_controller!.value.duration);
                            }
                          },
                          tooltip: 'Skip to End',
                        ),

                        // Mute/Unmute Icon
                        IconButton(
                          icon: Icon(
                            _volume == 0.0
                                ? Icons.volume_off
                                : Icons.volume_up,
                            color: Colors.white,
                          ),
                          onPressed: _toggleMute,
                          tooltip: 'Mute/Unmute',
                        ),
                        Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                        // Volume Slider Toggle Icon
                        IconButton(
                          icon: Icon(Icons.speaker, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isVolumeSliderVisible =
                                  !_isVolumeSliderVisible; // Toggle slider visibility
                            });
                          },
                          tooltip: 'Adjust Volume',
                        ),
                        
                        // Playback Speed Controls
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: FittedBox(
                            child: DropdownButton<double>(
                              value: _controller != null
                                ? _controller!.value.playbackSpeed
                                : 1.0,
                              dropdownColor: Colors.black87,
                              style: TextStyle(color: Colors.white),
                              items: [
                                DropdownMenuItem(value: 0.5, child: Text("0.5x")),
                                DropdownMenuItem(value: 1.0, child: Text("1x")),
                                DropdownMenuItem(value: 1.5, child: Text("1.5x")),
                                DropdownMenuItem(value: 2.0, child: Text("2x")),
                              ],
                              onChanged: _setPlaybackSpeed,
                            ),
                          ),
                        ),


                      ],
                    ),
                  ),
                ),

                // Horizontal Volume Slider (Appears Beside Sidebar)
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
         
                // Right Sidebar with Tools (Positioned on Top of Video)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 50,
                    color: Colors.black.withOpacity(0.5), // Add transparency
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: _resetAppState,
                        ),
                        IconButton(
                          icon: Icon(Icons.undo, color: Colors.white),
                          onPressed: _undo,
                          tooltip: 'Undo',
                        ),
                        IconButton(
                          icon: Icon(Icons.redo, color: Colors.white),
                          onPressed: _redo,
                          tooltip: 'Redo',
                        ),
                        Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.color_lens, color: Colors.yellow[500]),
                          onPressed: () {
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
                          color: _selectedShape == ShapeType.line
                            ? Colors.black.withOpacity(0.5)
                            : Colors.transparent,
                          shape: BoxShape.rectangle,
                          ),
                          child: IconButton(
                          icon: Icon(Icons.line_axis,
                            color: Colors.green[500]),
                          onPressed: () => _selectShape(ShapeType.line),
                          tooltip: 'Line',
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                          color: _selectedShape == ShapeType.curve
                            ? Colors.black.withOpacity(0.5)
                            : Colors.transparent,
                          shape: BoxShape.rectangle,
                          ),
                          child: IconButton(
                          icon: SvgPicture.asset(
                            'assets/line_curve.svg', // Ensure you have the SVG file in your assets
                            color: Colors.purple[300], // Set the color of the SVG icon
                            width: 24,
                            height: 24,
                          ),
                          onPressed: () => _selectShape(ShapeType.curve),
                          tooltip: 'Curve',
                          ),
                        ),
                          
                        Container(
                          decoration: BoxDecoration(
                          color: _selectedShape == ShapeType.arrow
                            ? Colors.black.withOpacity(0.5)
                            : Colors.transparent,
                          shape: BoxShape.rectangle,
                          ),
                          child: IconButton(
                          icon: Icon(Icons.arrow_back,
                            color: Colors.white),
                          onPressed: () => _selectShape(ShapeType.arrow),
                          tooltip: 'Arrow',
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                          color: _selectedShape == ShapeType.rectangle
                            ? Colors.black.withOpacity(0.5)
                            : Colors.transparent,
                          shape: BoxShape.rectangle,
                          ),
                          child: IconButton(
                          icon: Icon(Icons.crop_square,
                            color: Colors.red[200]),
                          onPressed: () => _selectShape(ShapeType.rectangle),
                          tooltip: 'Rectangle',
                          ),
                        ),
                        
                        Container(
                          decoration: BoxDecoration(
                          color: _selectedShape == ShapeType.circle
                            ? Colors.black.withOpacity(0.5)
                            : Colors.transparent,
                          shape: BoxShape.rectangle,
                          ),
                          child: IconButton(
                          icon: Icon(Icons.circle_outlined, color: Colors.orange[500]),
                          onPressed: () => _selectShape(ShapeType.circle),
                          tooltip: 'Circle',
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                          color: _selectedShape == ShapeType.triangle
                            ? Colors.black.withOpacity(0.5)
                            : Colors.transparent,
                          shape: BoxShape.rectangle,
                          ),
                          child: IconButton(
                          icon: Icon(Icons.change_history,
                            color: Colors.blue[500]),
                          onPressed: () => _selectShape(ShapeType.triangle),
                          tooltip: 'Triangle',
                          ),
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
                    color: Colors.black.withOpacity(0.5), // Add transparency
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTapDown: (details) {
                            _seekToPosition(
                              details.localPosition.dx,
                              MediaQuery.of(context).size.width,
                            );
                          },
                          onPanUpdate: (details) {
                            _seekToPosition(
                              details.localPosition.dx,
                              MediaQuery.of(context).size.width,
                            );
                          },
                          child: CustomPaint(
                            painter: ProgressBarPainter(
                              progress: _controller!.value.position,
                              duration: _controller!.value.duration,
                            ),
                            child: Container(
                              height: 100,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
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

  Shape({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.shapeType,
    this.isSelected = false,
    this.dragOffset,
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
      default:
        return false;
    }
  }

  bool _isPointNearLine(Offset point, Offset start, Offset end) {
    const threshold = 20.0;
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
      if (_isPointNearLine(point, points[i - 1], points[i])) {
        return true;
      }
    }
    return false;
  }

  void move(Offset delta) {
    for (int i = 0; i < points.length; i++) {
      points[i] = points[i] + delta;
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<Shape> shapes;
  final Shape? currentShape;
  final double Function(Offset, Offset, Offset)? calculateAngle;

  DrawingPainter(this.shapes, this.currentShape, this.calculateAngle);

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
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      path.lineTo(points.last.dx, points.last.dy);
      path.lineTo(2 * points[0].dx - points.last.dx, points.last.dy);
      path.close();
      canvas.drawPath(path, paint);
    }
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

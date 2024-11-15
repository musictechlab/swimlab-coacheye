import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoEditorScreen(),
    );
  }
}

enum ShapeType { line, rectangle, circle, triangle, curve, angle }

class VideoEditorScreen extends StatefulWidget {
  @override
  _VideoEditorScreenState createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  Color _selectedColor = Colors.green; // Default color set to green
  double _strokeWidth = 7.0; // Default line weight set to bold
  ShapeType _selectedShape = ShapeType.line;
  List<Shape> _shapes = [];
  List<Shape> _undoStack = [];
  Shape? _currentShape;
  double _volume = 0.1; // Set default volume to 30%
  double? _previousVolume;

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
          _controller!.play();
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
        title: Text('Swimlab Video Coach Eye'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _pickVideo,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetAppState,
          ),
          IconButton(
            icon: Icon(Icons.color_lens),
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
          PopupMenuButton<double>(
            onSelected: _changeStrokeWidth,
            itemBuilder: (context) => [
              PopupMenuItem(value: 1.0, child: Text("Thin")),
              PopupMenuItem(value: 3.0, child: Text("Normal")),
              PopupMenuItem(value: 5.0, child: Text("Bold")),
            ],
            icon: Icon(Icons.line_weight),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if (_controller != null &&
                          _controller!.value.isInitialized)
                        VideoPlayer(_controller!),
                      GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _currentShape = Shape(
                              points: [details.localPosition],
                              color: _selectedColor,
                              strokeWidth: _strokeWidth,
                              shapeType: _selectedShape,
                            );
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            if (_selectedShape == ShapeType.angle) {
                              if (_currentShape != null &&
                                  _currentShape!.points.length < 3) {
                                _currentShape!.points
                                    .add(details.localPosition);
                              }
                            } else {
                              _currentShape?.points.add(details.localPosition);
                            }
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            if (_currentShape != null) {
                              _shapes.add(_currentShape!);
                              _currentShape = null;
                              _undoStack.clear();
                            }
                          });
                        },
                        child: CustomPaint(
                          painter: DrawingPainter(
                              _shapes, _currentShape, _calculateAngle),
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTapDown: (details) {
                    _seekToPosition(details.localPosition.dx,
                        MediaQuery.of(context).size.width);
                  },
                  onPanUpdate: (details) {
                    _seekToPosition(details.localPosition.dx,
                        MediaQuery.of(context).size.width);
                  },
                  child: CustomPaint(
                    painter: ProgressBarPainter(
                      progress: _controller!.value.position,
                      duration: _controller!.value.duration,
                    ),
                    child: Container(
                      height: 20,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                          _volume == 0.0 ? Icons.volume_off : Icons.volume_up),
                      onPressed: _toggleMute,
                    ),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: _setVolume,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.skip_previous),
                        onPressed: () {
                          if (_controller != null &&
                              _controller!.value.isInitialized) {
                            _controller!.seekTo(Duration.zero);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.replay_10),
                        onPressed: () {
                          if (_controller != null &&
                              _controller!.value.isInitialized) {
                            _controller!.seekTo(_controller!.value.position -
                                Duration(seconds: 2));
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                            _controller != null && _controller!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow),
                        onPressed: _togglePlayPause,
                      ),
                      IconButton(
                        icon: Icon(Icons.forward_10),
                        onPressed: () {
                          if (_controller != null &&
                              _controller!.value.isInitialized) {
                            _controller!.seekTo(_controller!.value.position +
                                Duration(seconds: 2));
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next),
                        onPressed: () {
                          if (_controller != null &&
                              _controller!.value.isInitialized) {
                            _controller!.seekTo(_controller!.value.duration);
                          }
                        },
                      ),
                      DropdownButton<double>(
                        value: _controller != null
                            ? _controller!.value.playbackSpeed
                            : 1.0,
                        items: [
                          DropdownMenuItem(value: 0.5, child: Text("0.5x")),
                          DropdownMenuItem(value: 1.0, child: Text("1x")),
                          DropdownMenuItem(value: 1.5, child: Text("1.5x")),
                          DropdownMenuItem(value: 2.0, child: Text("2x")),
                        ],
                        onChanged: _setPlaybackSpeed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right sidebar with tools
          Container(
            width: 80,
            // color: Colors.grey[200],
            color: Colors.white.withOpacity(1), // Set transparency here
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.linear_scale),
                  onPressed: () => _selectShape(ShapeType.line),
                  tooltip: 'Line',
                ),
                IconButton(
                  icon: Icon(Icons.crop_square),
                  onPressed: () => _selectShape(ShapeType.rectangle),
                  tooltip: 'Rectangle',
                ),
                IconButton(
                  icon: Icon(Icons.circle),
                  onPressed: () => _selectShape(ShapeType.circle),
                  tooltip: 'Circle',
                ),
                IconButton(
                  icon: Icon(Icons.change_history),
                  onPressed: () => _selectShape(ShapeType.triangle),
                  tooltip: 'Triangle',
                ),
                IconButton(
                  icon: Icon(Icons.brush),
                  onPressed: () => _selectShape(ShapeType.curve),
                  tooltip: 'Curve',
                ),
                // IconButton(
                //   icon: Icon(Icons.architecture),
                //   onPressed: () => _selectShape(ShapeType.angle),
                //   tooltip: 'Angle',
                // ),
                IconButton(
                  icon: Icon(Icons.undo),
                  onPressed: _undo,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: Icon(Icons.redo),
                  onPressed: _redo,
                  tooltip: 'Redo',
                ),
              ],
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

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    if (duration.inMilliseconds > 0) {
      final double progressWidth =
          (progress.inMilliseconds / duration.inMilliseconds) * size.width;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, progressWidth, size.height),
        progressPaint,
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

  Shape({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.shapeType,
  });
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

    if (shape.shapeType == ShapeType.line) {
      if (shape.points.length >= 2) {
        canvas.drawLine(shape.points.first, shape.points.last, paint);
      }
    } else if (shape.shapeType == ShapeType.rectangle) {
      _drawRectangle(canvas, shape.points, paint);
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
      canvas.drawRect(rect, paint);
    }
  }

  void _drawCircle(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length >= 2) {
      final center = points.first;
      final radius = (points.first - points.last).distance;
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
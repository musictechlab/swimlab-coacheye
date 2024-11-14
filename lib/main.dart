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
  Color _selectedColor = Colors.green;
  double _strokeWidth = 7.0;
  ShapeType _selectedShape = ShapeType.line;
  List<Shape> _shapes = [];
  List<Shape> _undoStack = [];
  Shape? _currentShape;
  Shape? _selectedShapeToMove;
  Offset? _initialPosition;
  double _volume = 0.1;
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
          _controller!.setVolume(_volume);
          _controller!.play();
          _controller!.addListener(() {
            setState(() {});
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
        _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
      });
    }
  }

  void _rewind() {
    if (_controller != null && _controller!.value.isInitialized) {
      final currentPosition = _controller!.value.position;
      final rewindPosition = currentPosition - Duration(seconds: 5);
      _controller!.seekTo(rewindPosition > Duration.zero ? rewindPosition : Duration.zero);
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

  bool _isPointInsideShape(Shape shape, Offset point) {
    if (shape.points.isEmpty) return false;
    final rect = Rect.fromPoints(shape.points.first, shape.points.last);
    return rect.contains(point);
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
        title: Text('Video Editor'),
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
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: _undo,
          ),
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: _redo,
          ),
          PopupMenuButton<ShapeType>(
            onSelected: _selectShape,
            itemBuilder: (context) => [
              PopupMenuItem(value: ShapeType.line, child: Text("Line")),
              PopupMenuItem(value: ShapeType.rectangle, child: Text("Rectangle")),
              PopupMenuItem(value: ShapeType.circle, child: Text("Circle")),
              PopupMenuItem(value: ShapeType.triangle, child: Text("Triangle")),
              PopupMenuItem(value: ShapeType.curve, child: Text("Curve")),
              PopupMenuItem(value: ShapeType.angle, child: Text("Angle")),
            ],
            icon: Icon(Icons.shape_line),
          ),
        ],
      ),
      body: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.space): PlayPauseIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): RewindIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): ForwardIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            PlayPauseIntent: CallbackAction<PlayPauseIntent>(
              onInvoke: (intent) => _togglePlayPause(),
            ),
            RewindIntent: CallbackAction<RewindIntent>(
              onInvoke: (intent) => _rewind(),
            ),
            ForwardIntent: CallbackAction<ForwardIntent>(
              onInvoke: (intent) => _forward(),
            ),
          },
          child: Focus(
            autofocus: true,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if (_controller != null && _controller!.value.isInitialized)
                        VideoPlayer(_controller!),
                      GestureDetector(
                        onTapDown: (details) {
                          final selectedShape = _shapes.lastWhere(
                            (shape) => _isPointInsideShape(shape, details.localPosition),
                            orElse: () => null,
                          );
                          setState(() {
                            _selectedShapeToMove = selectedShape;
                            _initialPosition = details.localPosition;
                          });
                        },
                        onPanUpdate: (details) {
                          if (_selectedShapeToMove != null) {
                            setState(() {
                              final delta = details.localPosition - _initialPosition!;
                              for (int i = 0; i < _selectedShapeToMove!.points.length; i++) {
                                _selectedShapeToMove!.points[i] += delta;
                              }
                              _initialPosition = details.localPosition;
                            });
                          }
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _selectedShapeToMove = null;
                            _initialPosition = null;
                          });
                        },
                        child: CustomPaint(
                          painter: DrawingPainter(_shapes, _currentShape, _calculateAngle),
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTapDown: (details) {
                    _seekToPosition(details.localPosition.dx, MediaQuery.of(context).size.width);
                  },
                  onPanUpdate: (details) {
                    _seekToPosition(details.localPosition.dx, MediaQuery.of(context).size.width);
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
                      icon: Icon(_volume == 0.0 ? Icons.volume_off : Icons.volume_up),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.replay_10),
                      onPressed: () {
                        _controller!.seekTo(_controller!.value.position - Duration(seconds: 10));
                      },
                    ),
                    IconButton(
                      icon: Icon(
                          _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _togglePlayPause,
                    ),
                    IconButton(
                      icon: Icon(Icons.forward_10),
                      onPressed: () {
                        _controller!.seekTo(_controller!.value.position + Duration(seconds: 10));
                      },
                    ),
                    DropdownButton<double>(
                      value: _controller!.value.playbackSpeed,
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
              ],
            ),
          ),
        ),
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

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    if (duration.inMilliseconds > 0) {
      final double progressWidth = (progress.inMilliseconds / duration.inMilliseconds) * size.width;
      canvas.drawRect(Rect.fromLTWH(0, 0, progressWidth, size.height), progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
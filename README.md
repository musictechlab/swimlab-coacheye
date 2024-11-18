
# Swimlab Coach Eye

Swimlab Video Coach Eye is a Flutter Proof Of Concept Demo application designed to assist swimming coaches in analyzing and annotating videos. It provides tools to draw shapes, calculate angles (in progress), and control video playback for enhanced coaching and review sessions.

## Features

- **Video Playback:**
  - Play, pause, rewind, and forward videos.
  - Adjust playback speed.
  - Set volume or mute videos.

- **Annotation Tools:**
  - Draw lines, rectangles, circles, triangles, curves, and angles on the video.
  - Customize stroke width and colors for annotations.
  - Undo/redo functionality.

- **User Interaction:**
  - Gesture-based seeking on the video progress bar.
  - Custom drawing and annotation on video frames.

- **File Management:**
  - Select and load videos using the file picker.

- **User Interface:**
  - Clean and user-friendly interface with a customizable sidebar for annotation tools.

## Requirements

- **Flutter SDK** (2.0 or later)
- **Dart** (2.12 or later)
- Dependencies:
  - `video_player` (for video playback)
  - `file_picker` (for file selection)
  - `flutter_colorpicker` (for color selection)
/Users/msmenzyk/Downloads/README.md
## Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/musictechlab/swimlab-coacheye.git
   cd swimlab-coacheye
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App:**
   ```bash
   flutter run
   ```

## Usage

1. **Open a Video:**
   - Click the `+` icon in the app bar to select a video file.

2. **Control Playback:**
   - Use the playback controls to play, pause, rewind, or forward the video.

3. **Draw Annotations:**
   - Select a shape (e.g., line, rectangle, circle) from the sidebar.
   - Customize color and stroke width using the toolbar.
   - Draw directly on the video by dragging your finger or mouse.

4. **Undo/Redo Actions:**
   - Use the undo/redo buttons in the sidebar to manage annotations.

5. **Adjust Volume:**
   - Use the volume slider or mute button to control audio.

6. **Change Playback Speed:**
   - Select a speed from the dropdown menu.

## File Structure

- **`main.dart`**: Entry point of the app.
- **`VideoEditorScreen`**: Main screen for video playback and annotation.
- **Custom Painters**:
  - `DrawingPainter`: Handles rendering of shapes and annotations.
  - `ProgressBarPainter`: Renders the video progress bar.

## Customization

- **Annotation Shapes:**
  - Modify the `ShapeType` enum to add new shapes.
  - Update the `_drawShape` method in `DrawingPainter` to define rendering logic.

- **UI Enhancements:**
  - Customize colors, layout, or icons in the `build` method of `VideoEditorScreen`.

## Known Limitations

- Currently supports only local video files.
- Annotations are not saved or exported; they reset when the video is reloaded.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## About

<div align="center">
  Rockstar Developers 🤘 for the Music Industry<br>
  <a href="https://www.musictechlab.io/">Website</a>
  <span> | </span>
  <a href="https://linkedin.com/company/musictechlab">LinkdedIn</a><span> | </span>
  <a href="mailto:office@musictechlab.io">Let's talk</a><br>
  Crafted by https://www.musictechlab.io
</div>

---
Feel free to contribute to the project by submitting issues or pull requests! 🚀
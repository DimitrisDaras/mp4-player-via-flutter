import 'dart:html'; // For web file handling
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker

void main() {
  runApp(VideoWallController());
}

class VideoWallController extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Wall Controller',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: VideoControllerPage(),
    );
  }
}

class VideoControllerPage extends StatefulWidget {
  @override
  _VideoControllerPageState createState() => _VideoControllerPageState();
}

class _VideoControllerPageState extends State<VideoControllerPage> {
  VideoPlayerController? _controller;
  double _volume = 1.0; // Default volume (1.0 = max)
  String? _errorMessage; // Variable to hold error messages
  bool _isFullScreen = false; // Track full-screen state

  Future<void> _selectVideo() async {
    // Open a file picker to select a video file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.isNotEmpty) {
      // Get the first file from the result
      final file = result.files.first;

      // Create a Blob from the bytes and generate a URL for playback
      final bytes = file.bytes; // Get the file bytes

      if (bytes != null) {
        final blob = Blob([Uint8List.fromList(bytes)]);
        final url = Url.createObjectUrlFromBlob(blob); // Create a URL

        setState(() {
          // Initialize the video player controller with the generated URL
          _controller = VideoPlayerController.network(url)
            ..initialize().then((_) {
              _controller!.setVolume(_volume); // Set initial volume
              _controller!.play();
              _errorMessage = null; // Clear any previous error message
              setState(() {}); // Update the UI once the video is initialized and playing
            }).catchError((error) {
              // Handle any errors during initialization
              setState(() {
                _errorMessage = "Error loading video: $error";
              });
            });
        });
      }
    } else {
      // Handle the case where no file was selected
      print("No video selected");
    }
  }

  void _playVideo() {
    if (_controller != null && !_controller!.value.isPlaying) {
      _controller!.play();
      setState(() {});
    }
  }

  void _pauseVideo() {
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
      setState(() {});
    }
  }

  void _stopVideo() {
    if (_controller != null) {
      _controller!.pause();
      _controller!.seekTo(Duration.zero);
      setState(() {});
    }
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
      _controller?.setVolume(_volume); // Set the video volume
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen; // Toggle full-screen state
    });
  }

  @override
  void dispose() {
    _controller?.dispose(); // Clean up the controller when the widget is disposed
    super.dispose();
  }

  Widget _buildSeekBar() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.replay_10),
          onPressed: () {
            if (_controller != null) {
              final currentPosition = _controller!.value.position;
              final newPosition = currentPosition - Duration(seconds: 10);
              _controller!.seekTo(newPosition);
            }
          },
        ),
        Expanded(
          child: VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            padding: EdgeInsets.symmetric(vertical: 8), // Adjust padding as needed
          ),
        ),
        IconButton(
          icon: Icon(Icons.forward_10),
          onPressed: () {
            if (_controller != null) {
              final currentPosition = _controller!.value.position;
              final newPosition = currentPosition + Duration(seconds: 10);
              _controller!.seekTo(newPosition);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: _toggleFullScreen, // Detect double-tap to toggle full-screen
        child: Container(
          margin: EdgeInsets.only(top: 40), // Add top margin
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Video Player Container with Red Border
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 4), // Red border
                ),
                padding: EdgeInsets.all(8), // Padding inside the border
                child: ClipRect(
                  child: SizedBox(
                    width: _isFullScreen ? MediaQuery.of(context).size.width : 600, // Full width if full-screen
                    height: _isFullScreen ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.height * 0.7, // Full height if full-screen
                    child: (_controller != null && _controller!.value.isInitialized)
                        ? VideoPlayer(_controller!)
                        : Center(
                            child: Text(
                              'Select a video to play',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Error message display
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                SizedBox(height: 20),
              ],
              // Seek Bar
              _controller != null && _controller!.value.isInitialized
                  ? _buildSeekBar()
                  : Container(), // Only show seek bar if video is initialized
              SizedBox(height: 20),
              // Volume Control
              Row(
                children: [
                  Text('Volume: ${(_volume * 100).round()}%', style: TextStyle(fontSize: 16)), // Volume percentage
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: _setVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100, // 100 divisions for finer control
                      label: '${(_volume * 100).round()}',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Control Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _selectVideo,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: Colors.blue, // Uniform color for all buttons
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                      ),
                      child: Text('Select Video'),
                    ),
                    ElevatedButton(
                      onPressed: _playVideo,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: Colors.blue, // Uniform color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                      ),
                      child: Text('Play'),
                    ),
                    ElevatedButton(
                      onPressed: _pauseVideo,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: Colors.blue, // Uniform color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                      ),
                      child: Text('Pause'),
                    ),
                    ElevatedButton(
                      onPressed: _stopVideo,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: Colors.blue, // Uniform color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                      ),
                      child: Text('Stop'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20), // Add extra spacing at the bottom
            ],
          ),
        ),
      ),
    );
  }
}

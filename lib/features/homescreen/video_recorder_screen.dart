import 'dart:async';
import 'dart:io';
import 'package:Wemotions/features/homescreen/upload_post.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoRecorderScreen extends StatefulWidget {
  final String parentVideoId;
  const VideoRecorderScreen({Key? key,required this.parentVideoId}) : super(key: key);
  @override
  _VideoRecorderScreenState createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen> {
  CameraController? cameraController;
  bool isRecording = false;
  bool isFlashOn = false;
  double progress = 0.0;
  Timer? timer;
  int maxRecordingTime = 60; // Maximum recording time in seconds
  String? recordedVideoPath;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      final frontCamera = cameras.first;

      // Initialize the camera controller
      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );

      await cameraController?.initialize();
      setState(() {});
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  void startRecording() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Start recording
      await cameraController?.startVideoRecording();
      setState(() {
        isRecording = true;
        progress = 0.0;
      });

      // Timer for progress bar
      timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          progress += 0.1 / maxRecordingTime;
          if (progress >= 1.0) {
            stopRecording();
          }
        });
      });
    } catch (e) {
      debugPrint("Error starting video recording: $e");
    }
  }

  void stopRecording() async {
    if (cameraController == null || !cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      // Stop recording
      final file = await cameraController?.stopVideoRecording();
      setState(() {
        isRecording = false;
        recordedVideoPath = file?.path;
        timer?.cancel();
      });

      // Navigate to the preview screen
      if (recordedVideoPath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPreviewScreen(videoPath: recordedVideoPath!,parentVideoId: widget.parentVideoId),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error stopping video recording: $e");
    }
  }

  void toggleFlash() {
    if (cameraController != null) {
      setState(() {
        isFlashOn = !isFlashOn;
        cameraController?.setFlashMode(
          isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      });
    }
  }

  void toggleCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      final currentLensDirection = cameraController?.description.lensDirection;

      final newCamera = cameras.firstWhere(
        (camera) => camera.lensDirection != currentLensDirection,
      );

      // Initialize the new camera
      cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
      );
      await cameraController?.initialize();
      setState(() {});
    } catch (e) {
      debugPrint("Error toggling camera: $e");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: cameraController == null || !cameraController!.value.isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            )
          : Stack(
              children: [
                // Camera preview
                 Positioned.fill(
            child: CameraPreview(cameraController!),
          ),

                // Top buttons: Back, Flip, and Flash
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 68,
                  right: 18,
                  child: Column(
                    children: [
                      _buildActionButton(Icons.cameraswitch, "Flip", toggleCamera),
                      const SizedBox(height: 16),
                      _buildActionButton(
                          isFlashOn ? Icons.flash_on : Icons.flash_off,
                          "Flash",
                          toggleFlash),
                    ],
                  ),
                ),

                // Timer, Progress Bar, and Record Button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatTime(progress * maxRecordingTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
    if (isRecording) {
      // Stop recording on tap
      stopRecording();
    } else {
      // Start recording on tap
      startRecording();
    }
    isRecording = !isRecording; // Toggle recording state
  },
  onLongPress: () {
    if (!isRecording) {
      // Start recording on long press
      startRecording();
      isRecording = true;
    }
  },
  onLongPressUp: () {
    if (isRecording) {
      // Stop recording when long press is released
      stopRecording();
      isRecording = false;
    }
  },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Circular Progress
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: isRecording ? progress : 0.0,
                                  strokeWidth: 4.0,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.purple,
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              // Record Button
                              Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isRecording ? Icons.stop : Icons.videocam_rounded,
                                  color: Colors.purple,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  String formatTime(double seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds.toInt() % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;
  final String parentVideoId;
  const VideoPreviewScreen({Key? key, required this.videoPath,required this.parentVideoId}) : super(key: key);

  @override
  _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController videoController;
  bool isPlaying = false;
  double progress = 0.0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
  }

  void initializeVideoPlayer() {
    videoController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
      })
      ..addListener(() {
        final currentPosition = videoController.value.position.inMilliseconds.toDouble();
        final totalDuration = videoController.value.duration.inMilliseconds.toDouble();
        setState(() {
          progress = totalDuration > 0 ? currentPosition / totalDuration : 0.0;
        });
        if (videoController.value.position >= videoController.value.duration) {
        setState(() {
          isPlaying = false; // Reset play/pause button
        });
      }
    });
  }

  void togglePlayPause() {
    if (videoController.value.isPlaying) {
      videoController.pause();
    } else {
      videoController.play();
    }

    setState(() {
      isPlaying = videoController.value.isPlaying;
    });
  }
  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: videoController.value.isInitialized
                ? AspectRatio(
                    aspectRatio: videoController.value.aspectRatio,
                    child: VideoPlayer(videoController),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  ),
          ),
          
          Positioned(
            top: 60,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 60,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.white,
              onPressed: () {
                _showDiscardDialog(context);
              },
            ),
          ),
          Positioned(
            bottom: 50,
            right: 40,
            child:SizedBox(
              width: 80,
              height: 50,
            child:FloatingActionButton(
                    backgroundColor:
                    const Color.fromRGBO(147, 54, 231, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onPressed: () {
                  Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UploadReplyScreen(videoPath: widget.videoPath,parentVideoId: widget.parentVideoId)),
              );
                    },
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        color:Colors.white,
                      ),
                    ),
                  ),
             /*IconButton(
              icon: const Icon(Icons.forward),
              color: Colors.white,
              onPressed: () {
                  post();
              },
            ),*/
          ),
      ),
          Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatTime(progress * videoController.value.duration.inSeconds.toDouble()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
            GestureDetector(
              onTap: togglePlayPause,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Progress
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4.0,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.purple,
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  // Play/Pause Button
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.purple,
                      size: 36,
                    ),
                  ),
                ],
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

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)), // Rounded corners
      ),
      backgroundColor: const Color.fromRGBO(41, 41, 41, 1), // Black background
      title: const Center(
        child: Text(
          "Discard the last clip?",
          style: TextStyle(
            color: Colors.white, // White text color for title
            fontSize: 18.0,
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceAround, // Center the buttons
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.red, // Red background for Discard button
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text(
            "Discard",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    ),
    );
  }
  String formatTime(double seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds.toInt() % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
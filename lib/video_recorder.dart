import 'package:camera/camera.dart';
import 'package:cameraappsample/cam_renderer.dart';
import 'package:flutter/material.dart';


class VideoRecorder extends StatefulWidget {
  @override
  VideoRecorderState createState() => VideoRecorderState();
}

class VideoRecorderState extends State<VideoRecorder> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton(
              onPressed: () {
                availableCameras().then(
                        (cameras) {
                      print(cameras);
                      CameraController _controller = CameraController(
                          cameras[0],
                          ResolutionPreset.high,
                          enableAudio: true
                      );
                      _controller.initialize().then(
                              (_) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CamRenderer(_controller)
                                )
                            );
                          }
                      );
                    }
                );
              },
              child: Icon(Icons.videocam),
            )
          ],
        ),
      ),
    );
  }
}
import 'package:cameraappsample/camera_service.dart';
import 'package:cameraappsample/camera_widget.dart';
import 'package:cameraappsample/dual_camera.dart';
import 'package:cameraappsample/video_recorder.dart';
import 'package:flutter/material.dart';

import 'camera_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        /*appBar: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: new Container(
            color: Colors.pink,
          ),
        ),*/
        //body: new VideoRecorder()
        //body: VideoRecorderExample(),
        //body: CameraScreen(),
        body: new CameraService(
          cameraType: CameraType.FRONT,
          captureType: CaptureType.PHOTO,
        ),
        //body: DualCameraScreen(),
      ),
    );
  }
}

import 'package:cameraappsample/camera_service.dart';
import 'package:flutter/material.dart';

class DualCameraScreen extends StatefulWidget {
  @override
  _DualCameraScreenState createState() => _DualCameraScreenState();
}

class _DualCameraScreenState extends State<DualCameraScreen> {
  final _cameraService1Key1= new GlobalKey<CameraServiceState>();
  final _cameraService1Key2= new GlobalKey<CameraServiceState>();

  @override
  Widget build(BuildContext context) {
    double height= MediaQuery.of(context).size.height / 2;
    return Column(
      children: <Widget>[
        new Container(
          height: height,
          child: new CameraService(
            key: _cameraService1Key1,
            captureType: CaptureType.VIDEO,
            cameraType: CameraType.FRONT,
          ),
        ),
        new Container(
          height: height,
          child: new CameraService(
            key: _cameraService1Key2,
            captureType: CaptureType.VIDEO,
            cameraType: CameraType.REAR,
          ),
        ),
      ],
    );
  }
}

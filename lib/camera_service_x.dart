
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';

class CameraService extends StatefulWidget {
  @override
  _CameraServiceState createState() => _CameraServiceState();
}

class _CameraServiceState extends State<CameraService> with WidgetsBindingObserver {
  CameraController _cameraController;
  List<CameraDescription> _cameras;
  int _selectedCameraIndex;
  String _videoFilePath;
  String _imageFilePath;
  bool _isRecordingOn= false;

  Timer _timerVideoTime;
  int _timeInSec= 0;
  int _videoTimeLengthInSec= 180;

  Timer _timerStartCamera;
  AppLifecycleState _appLifecycleState;

  void activateCameraTimer() {
    const oneSec= const Duration(seconds: 1);
    _timerStartCamera= new Timer.periodic(oneSec, (Timer timer) async {
      if(_cameraController != null && _cameraController.value.isInitialized) {
        startVideoCapture();
        deactivateCameraTimer();
      }
    });
  }

  void deactivateCameraTimer() {
    _timerStartCamera?.cancel();
  }

  void startVideoTimer() {
    const oneSec= const Duration(seconds: 1);
    _timerVideoTime= new Timer.periodic(oneSec, (Timer timer) async {
      //if(_appLifecycleState == AppLifecycleState.resumed) {
        setState(() {
          _timeInSec= _timeInSec + 1;
        });
        if(_timeInSec >= _videoTimeLengthInSec) {
          await stopVideoCapture();
        }
      //}
    });
  }

  void stopVideoTimer() {
    _timeInSec= 0;
    _timerVideoTime?.cancel();
  }

  String formatTime(Duration duration) {
    return [
      if (duration.inHours != 0) duration.inHours,
      duration.inMinutes,
      duration.inSeconds,
    ].map((seg) => seg.remainder(60).toString().padLeft(2, '0')).join(':');
  }

  @override
  void initState() {
    initCamera();
    //activateCameraTimer();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameras= null;
    _selectedCameraIndex= null;
    _videoFilePath= _imageFilePath= null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void showToastMsg(bool success, String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: success ? Colors.grey : Colors.redAccent,
      textColor: Colors.white
    );
  }

  Future<void> initCamera(){
    availableCameras().then((_cameras) {
      print("@@availableCameras: $_cameras, Dedc: ${_cameras.asMap().toString()}");
      if(_cameras.length > 0) {
        setState(() {
          _selectedCameraIndex= 0;
        });
        setupCamera(_cameras[_selectedCameraIndex]).then((void v) {});
      }
    }).catchError((error) {
      print("CAMERA ERROR: $error");
      showToastMsg(false, "CAMERA ERROR: $error");
    });
  }

  Future<void> setupCamera(CameraDescription cameraDescription) async {
    if(_cameraController != null) {
      await _cameraController.dispose();
    }
    _cameraController= new CameraController(cameraDescription, ResolutionPreset.medium);
    // if the controller is updated then update the UI
    _cameraController.addListener(() {
      if(mounted) {
        setState(() { });
      }
      if(_cameraController.value.hasError) {
        print("CAMERA ERROR: $_cameraController.value.hasError");
        showToastMsg(false, "CAMERA ERROR: ${_cameraController.value.errorDescription}");  
      }
    });
    
    try {
      await _cameraController.initialize();
    } on CameraException catch(error) {
      print("CAMERA ERROR: $error");
      showToastMsg(false, "CAMERA ERROR: $error");
    }
    if(mounted) {
      setState(() { });
    }
  }

  Future<String> getFilePath({String extension: ".jpg"}) async {
    String filePath= "";
    try {
      final Directory appExtDir = await getExternalStorageDirectory();
      print("@@appExtDir: $appExtDir");
      final String videoDir= (extension.toLowerCase() == ".mp4")
                            ? "${appExtDir.path}/Videos"
                            : "${appExtDir.path}/Photos";
      print("@@videoDir: $videoDir");
      final bool isVideoDirExist= await Directory(videoDir).exists();
      print("@@isVideoDirExist: $isVideoDirExist");
       if(!isVideoDirExist) {
         await new Directory(videoDir).create(recursive: true);
         print("@@directory created: $isVideoDirExist");
       }
       final String fineName= new DateTime.now().millisecondsSinceEpoch.toString();
       print("@@fineName: $fineName");
       filePath= "$videoDir/$fineName.$extension";
      print("@@filePath: $filePath");
    } catch(error) {
      print("ERROR: $error");
      showToastMsg(false, "ERROR: $error");
      filePath= null;
    }
    return filePath;
  }

  Future<String> startVideoCapture() async {
    if(!_cameraController.value.isInitialized) {
      showToastMsg(true, "Please wait");
      return null;
    }
    setState(() {
      _isRecordingOn = true;
    });
    startVideoTimer();
    // do nothing if a recording is in progress
    if(_cameraController.value.isRecordingVideo) {
      return null;
    }
    // create video file
    final String filePath= await getFilePath(extension: ".mp4");
    try {
      await _cameraController.startVideoRecording(filePath);
      showToastMsg(true, "Recording Started");
      _videoFilePath= filePath;
    } on CameraException catch(error) {
      print("CAMERA ERROR: $error");
      showToastMsg(false, "CAMERA ERROR: $error");
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoCapture() async {
    if(!_cameraController.value.isRecordingVideo) {
      return null;
    }
    stopVideoTimer();
    setState(() {
      _isRecordingOn= false;
    });

    try {
      await _cameraController.stopVideoRecording();
      showToastMsg(true, "Recording Stopped");
    } on CameraException catch(error) {
      print("CAMERA ERROR: $error");
      showToastMsg(false, "CAMERA ERROR: $error");
      return null;
    }
  }

  Widget buildCameraPreviewWidget() {
    if(_cameraController == null || !_cameraController.value.isInitialized) {
      return new Center(
        child: Text(
          'Loading',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    } else {
      /*return AspectRatio(
        aspectRatio: _cameraController.value.aspectRatio,
        child: new CameraPreview(_cameraController),
      );*/
      return new CameraPreview(_cameraController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Stack(
        children: <Widget>[
          buildCameraPreviewWidget(),
          Positioned.fill(
            top: 50,
            child: new Align(
              alignment: Alignment.topCenter,
              child: new Text(
                formatTime(Duration(seconds: _timeInSec)),
                style: new TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          /*new Positioned(
            left: 0,
            right: 0,
            top: 32.0,
            child: new Text(
              formatTime(Duration(seconds: _timeInSec)),
              style: new TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),*/
          new Positioned(
            left: 5.0,
            bottom: 5.0,
            child: new IconButton(
              icon: Icon(
                Icons.play_arrow,
                size: 30,
                color: _isRecordingOn ? Colors.grey : Colors.green
              ),
              onPressed: _isRecordingOn
                  ? null
                  : () async {
                        await startVideoCapture();
                        /*setState(() {
                          _isRecordingOn= true;
                        });*/
                        print("@@@@@@@@@@ started");
                      },
            ),
          ),
          new Positioned(
            right: 5.0,
            bottom: 5.0,
            child: new IconButton(
              icon: Icon(
                  Icons.stop,
                  size: 30,
                  color: _isRecordingOn ? Colors.redAccent : Colors.grey
              ),
              onPressed: _isRecordingOn
                    ? () async {
                        stopVideoCapture();
                        /*setState(() {
                          _isRecordingOn= false;
                        });*/
                        print("@@@@@@@@@@ stopped");
                      }
                    : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    _appLifecycleState= state;
    print("@@@@@@@@@@ _appLifecycleState: $_appLifecycleState");
    if(state == AppLifecycleState.resumed) {
      await initCamera();
    } else if(state == AppLifecycleState.inactive) {
      if(_cameraController != null && _cameraController.value.isRecordingVideo) {
        await stopVideoCapture();
      }
      _cameraController?.dispose();
    } else if(state == AppLifecycleState.paused) {

    } else if(state == AppLifecycleState.detached) {

    }
    super.didChangeAppLifecycleState(state);
  }
}

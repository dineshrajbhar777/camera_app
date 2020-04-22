import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:cameraappsample/camera_media_storage.dart';
import 'package:cameraappsample/common.dart';
import 'package:cameraappsample/gallery.dart';
import 'package:cameraappsample/video_timer.dart';
import 'package:flashlight/flashlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CameraType { FRONT, REAR }
enum CaptureType { VIDEO, PHOTO }

class CameraService extends StatefulWidget {
  final CaptureType captureType;
  final CameraType cameraType;
  const CameraService({key, this.cameraType, this.captureType}) : super(key: key);

  @override
  CameraServiceState createState() => CameraServiceState();
}

class CameraServiceState extends State<CameraService> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final _timerKey= new GlobalKey<VideoTimerState>();
  CameraController _cameraController;
  List<CameraDescription> _cameras;
  CameraType _cameraType;
  CaptureType _captureType;
  String _videoFilePath;
  String _imageFilePath;

  bool _isTorch= false;
  bool _isRecordingMode= false;
  bool _isRecordingVideo= false;
  Color _colorCameraPreviewBorder= Colors.grey;

  CameraMediaStorage _cameraMediaStorage= new CameraMediaStorage();

  @override
  void initState() {
    _cameraType=  widget.cameraType  == null ? CameraType.REAR   : widget.cameraType;
    _captureType= widget.captureType == null ? CaptureType.PHOTO : widget.captureType;
    initCamera();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameras= null;
    _videoFilePath= _imageFilePath= null;
    _cameraMediaStorage= null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initCamera(){
    var status= 0;
    availableCameras().then((_cameras) {
      print("@@availableCameras: $_cameras, Dedc: ${_cameras.asMap().toString()}");
      if(_cameras.length > 0) {
        int cameraIndex= 0;
        if(CameraType != null && _cameras.length > 1) {
          cameraIndex= CameraType.FRONT == _cameraType
                        ? 1   //  FRONT
                        : 0;  //  REAR
        }

        bool isCaptureVideo= false;
        if(CameraType != null) {
          isCaptureVideo= CaptureType.VIDEO == _captureType
                        ? true
                        : false;
        }
        setState(() {
          _isRecordingMode= isCaptureVideo;
        });
        setupCamera(_cameras[cameraIndex]).then((void v) {});
      }
    }).catchError((error) {
      print("CAMERA ERROR: $error");
      showToastMsg(msg: "CAMERA ERROR: $error");
    });
    return null;
  }

  Future<void> setupCamera(CameraDescription cameraDescription) async {
    if(_cameraController != null) {
      await _cameraController.dispose();
    }
    _cameraController= new CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: true,
    );
    // if the controller is updated then update the UI
    _cameraController.addListener(() {
      if(mounted) {
        setState(() { });
      }
      if(_cameraController.value.hasError) {
        print("CAMERA ERROR: $_cameraController.value.hasError");
        showToastMsg(msg: "CAMERA ERROR: ${_cameraController.value.errorDescription}");
      }
    });
    
    try {
      await _cameraController.initialize();
      print("SLEEP:@@@@ BEFORE SLEEP");
      sleep(Duration(milliseconds: 100));
      print("SLEEP:@@@@ AFTER  SLEEP");
    } on CameraException catch(error) {
      print("CAMERA ERROR: $error");
      showToastMsg(msg: "CAMERA ERROR: $error");
    }
    if(mounted) {
      setState(() { });
    }
    return null;
  }

  Future<void> switchFrontRearCamera() async {
    if(CameraType.REAR == _cameraType) { //REAR
      _cameraType= CameraType.FRONT;
    } else {
      _cameraType= CameraType.REAR;
    }
    await initCamera();
    return null;
  }

  Future<void> switchPhotoVideoCamera() async {
    if(CaptureType.VIDEO == _captureType) { //REAR
      _captureType= CaptureType.PHOTO;
    } else {
      _captureType= CaptureType.VIDEO;
    }
    await initCamera();
    return null;
  }

  Future<String> startVideoCapture() async {
    if(!_cameraController.value.isInitialized) {
      showToastMsg(msg: "Please wait");
      return null;
    }
    // do nothing if a recording is in progress
    if(_cameraController.value.isRecordingVideo) {
      return null;
    }
    setState(() {
      _isRecordingVideo = true;
      _colorCameraPreviewBorder= Colors.red;
    });
    _timerKey.currentState.startTimer();
    showToastMsg(msg: "Recording Started");
    // create video file
    final String filePath= await _cameraMediaStorage.getFilePath(extension: ".mp4");
    try {
      await _cameraController.startVideoRecording(filePath);
      _videoFilePath= filePath;
    } on CameraException catch(error) {
      print("CAMERA ERROR: $error");
      showToastMsg(msg: "CAMERA ERROR: $error");
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoCapture() async {
    if(!_cameraController.value.isRecordingVideo) {
      return null;
    }
    _timerKey.currentState.stopTimer();
    setState(() {
      _isRecordingVideo= false;
      _colorCameraPreviewBorder= Colors.grey;
    });

    try {
      await _cameraController.stopVideoRecording();
      showToastMsg(msg: "Recording Stopped");
    } on CameraException catch(error) {
      print("CAMERA ERROR: $error");
      showToastMsg(msg: "CAMERA ERROR: $error");
      return null;
    }
  }

  void capturePicture() async {
    if (_cameraController.value.isInitialized) {
      setState(() {
        _colorCameraPreviewBorder= Colors.red;
      });
      SystemSound.play(SystemSoundType.click);
      final String filePath= await _cameraMediaStorage.getFilePath(extension: ".jpeg");
      try {
        await _cameraController.takePicture(filePath);
        _imageFilePath= filePath;
        showToastMsg(msg: "Photo captured.");
        setState(() {
          _colorCameraPreviewBorder= Colors.grey;
        });
      } on CameraException catch(error) {
        print("CAMERA ERROR: $error");
        showToastMsg(msg: "CAMERA ERROR: $error");
        return null;
      }
    }
  }

  Widget buildCameraPreviewWidget(BuildContext context) {
    if(_cameraController == null || !_cameraController.value.isInitialized) {
      return Container(
        color: Colors.grey.shade800,
        child: new Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new CircularProgressIndicator(backgroundColor: Colors.white,),
              new SizedBox(height: 10,),
              new Text(
                'Loading',
                style: new TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      /*return AspectRatio(
        aspectRatio: _cameraController.value.aspectRatio,
        child: new CameraPreview(_cameraController),
      );*/
      return new Container(
        decoration: new BoxDecoration(
          border: new Border.all(color: _colorCameraPreviewBorder, width: 4.0),
        ),
        child: new CameraPreview(_cameraController)
      );
    }
  }

  Widget buildCaptureButton(BuildContext context) {
    return Positioned.fill(
      bottom: 10.0,
      child: new Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: new BoxDecoration(
            shape: BoxShape.circle,
            // The border you want
            border: new Border.all(
              width: 2.0,
              color: Colors.white,
            ),
            // The shadow you want
          ),
          child: new CircleAvatar(
            backgroundColor: Colors.grey.shade400.withOpacity(0.8),
            radius: 28.0,
            child: new IconButton(
              iconSize: 40.0,
              icon: new Icon(
                (_isRecordingMode)
                    ? (_isRecordingVideo) ? Icons.stop : Icons.videocam
                    : Icons.camera_alt,
                //size: 28.0,
                color: (_isRecordingMode) ? Colors.red : Colors.white,
              ),
              onPressed: () {
                if (!_isRecordingMode) {
                  capturePicture();
                } else {
                  if (_isRecordingVideo) {
                    stopVideoCapture();
                  } else {
                    startVideoCapture();
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTorch(BuildContext context) {
    return Positioned.fill(
      top: 32.0,
      left: 10.0,
      child: new Align(
        alignment: Alignment.topLeft,
        child: Container(
          decoration: new BoxDecoration(
            shape: BoxShape.circle,
            border: new Border.all(
              width: 1.0,
              color: Colors.white,
            ),
          ),
          child: new CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.2),
            radius: 18.0,
            child: new IconButton(
              iconSize: 20.0,
              icon: new Icon(
                _isTorch ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isTorch= !_isTorch;
                });
                if(_isTorch) {
                  Flashlight.lightOn();
                } else {
                  Flashlight.lightOff();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget buildSwitchFrontRear(BuildContext context) {
    print("@@@@@" + MediaQuery.of(context).orientation.toString());
    final height= MediaQuery.of(context).size.height;
    final width= MediaQuery.of(context).size.width;
    final rotate_angle= height > width ? 1 : 90;
    return Positioned.fill(
      bottom: 20.0,
      left: 10.0,
      child: new Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          decoration: new BoxDecoration(
            shape: BoxShape.circle,
            border: new Border.all(
              width: 1.0,
              color: Colors.white,
            ),
          ),
          child: new CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.2),
            radius: 18.0,
            child: Transform.rotate(
              angle: rotate_angle / 360 * pi * 2,
              child: new IconButton(
                iconSize: 20.0,
                icon: new Icon(
                  Icons.switch_camera,
                  color: Colors.white,
                ),
                onPressed: () {
                  switchFrontRearCamera();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSwitchPhotoVideo(BuildContext context) {
    return Positioned.fill(
      bottom: 20.0,
      left: 80.0,
      child: new Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          decoration: new BoxDecoration(
            shape: BoxShape.circle,
            border: new Border.all(
              width: 1.0,
              color: Colors.white,
            ),
          ),
          child: new CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.2),
            radius: 18.0,
            child: new IconButton(
              iconSize: 20.0,
              icon: new Icon(
                _isRecordingMode ? Icons.camera_alt : Icons.videocam,
                color: Colors.white,
              ),
              onPressed: () {
                switchPhotoVideoCamera();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildThumbnailPreview(BuildContext context) {
    return Positioned.fill(
      bottom: 10.0,
      right: 10.0,
      child: new Align(
        alignment: Alignment.bottomRight,
        child: Container(
          decoration: new BoxDecoration(
            //shape: BoxShape.circle,
            border: new Border.all(
              width: 1.0,
              color: Colors.white,
            ),
          ),
          child: new FutureBuilder(
            future: _cameraMediaStorage.getLastImage(),
            builder: (context, snapshot) {
              print("@@@@@@@@@@ snapshot.data: ${snapshot.data}");
              if (snapshot.data == null) {
                return Container(
                  width: 50.0,
                  height: 50.0,
                );
              }
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => new Gallery(),
                  ),
                ),
                child: Container(
                  width: 50.0,
                  height: 50.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1.0),
                    child: Image.file(
                      snapshot.data,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          )
        ),
      ),
    );
  }

  Widget buildCapturePhotoInVideoRecording(BuildContext context) {
    return Positioned.fill(
      bottom: 10.0,
      right: 10.0,
      child: new Align(
        alignment: Alignment.bottomRight,
        child: Container(
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              border: new Border.all(
                width: 1.0,
                color: Colors.white,
              ),
            ),
          child: new CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.2),
            radius: 18.0,
            child: new IconButton(
              iconSize: 20.0,
              icon: new Icon(
                Icons.camera,
                color: Colors.white,
              ),
              onPressed: () async {
                capturePicture();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return new Scaffold(
      body: new Stack(
        children: <Widget>[
          buildCameraPreviewWidget(context),
          _isRecordingMode
              ? new Positioned(
                left: 0,
                right: 0,
                top: 32.0,
                child: VideoTimer(
                  key: _timerKey,
                ),
              )
              : new Container(),
          //buildTorch(context),
          buildCaptureButton(context),
          buildSwitchFrontRear(context),
          _isRecordingVideo ? buildCapturePhotoInVideoRecording(context) : new Container(),
          _isRecordingVideo ? new Container() : buildSwitchPhotoVideo(context),
          _isRecordingVideo ? new Container() : buildThumbnailPreview(context),
        ],
      ),
    );
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
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

  @override
  void didChangeMetrics() {
    double width = window.physicalSize.width;
    double height = window.physicalSize.height;
    print("@@@@ width: $width");
    print("@@@@ height: $height");
    super.didChangeMetrics();
  }

  @override
  bool get wantKeepAlive => true;
}

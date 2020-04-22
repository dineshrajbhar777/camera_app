import 'dart:io';
import 'package:camera/new/camera.dart';
import 'package:cameraappsample/camera_media_storage.dart';
import 'package:cameraappsample/common.dart';
import 'package:flutter/material.dart';
import 'package:cameraappsample/video_preview.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class Gallery extends StatefulWidget {
  @override
  GalleryState createState() => GalleryState();
}

class GalleryState extends State<Gallery> {
  String _currentFilePath;
  CameraMediaStorage _cameraMediaStorage= new CameraMediaStorage();
  bool _isDirEmpty= false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade800,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: new FutureBuilder(
        future: _cameraMediaStorage.getAllDirFiles(),
        builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
          print("@@@@@ snapshot.length: ${snapshot?.data?.length}, snapshot.data: ${snapshot.data}");
          if(snapshot.data != null && snapshot.data.length > 0) {
            _isDirEmpty= false;
            return PageView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                _currentFilePath = snapshot.data[index].path;
                var extension = path.extension(snapshot.data[index].path);
                if (extension == '.jpeg') {
                  return Container(
                    height: 300,
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.file(
                      File(snapshot.data[index].path),
                    ),
                  );
                } else {
                  return VideoPreview(
                    videoPath: snapshot.data[index].path,
                  );
                }
              },
            );
          } else {
            _isDirEmpty= true;
            _currentFilePath= null;
            return new Center(
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new Icon(Icons.folder_open, size: 100, color: Colors.white,),
                  new SizedBox(height: 10,),
                  new Text(
                    "Empty",
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: new BottomAppBar(
        child: Container(
          height: 50.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  if(_isDirEmpty) {
                    showToastMsg(msg: "Directory is empty.");
                  } else {
                    _cameraMediaStorage.deleteFile(_currentFilePath);
                    setState(() {});
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  /*_shareFile() async {
    var extension = path.extension(_currentFilePath);
    await Share.file(
      'image',
      (extension == '.jpeg') ? 'image.jpeg' : '	video.mp4',
      File(_currentFilePath).readAsBytesSync(),
      (extension == '.jpeg') ? 'image/jpeg' : '	video/mp4',
    );
  }*/

  /*_deleteFile() {
    final dir = Directory(_currentFilePath);
    dir.deleteSync(recursive: true);
    print('deleted');
    setState(() {});
  }*/
}

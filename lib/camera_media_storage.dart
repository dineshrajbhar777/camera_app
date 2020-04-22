import 'dart:io';
import 'package:cameraappsample/common.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:thumbnails/thumbnails.dart';

class CameraMediaStorage {
  Future<Directory> getStorageDirectory() async {
    return await getExternalStorageDirectory();
  }

  Future<String> getFilePath({String extension: ".jpg"}) async {
    String filePath= "";
    try {
      final Directory appExtDir = await this.getStorageDirectory();
      print("@@appExtDir: $appExtDir");
      /*final String mediaDirPath= (extension.toLowerCase() == ".mp4")
                            ? "${appExtDir.path}/Videos"
                            : "${appExtDir.path}/Photos";*/

      final String mediaDirPath= "${appExtDir.path}/media";
      print("@@mediaDirPath: $mediaDirPath");
      final bool isMediaDirExist= await Directory(mediaDirPath).exists();
      print("@@isMediaDirExist: $isMediaDirExist");
      if(!isMediaDirExist) {
        await new Directory(mediaDirPath).create(recursive: true);
        print("@@directory created: $isMediaDirExist");
      }
      final String fineName= new DateTime.now().millisecondsSinceEpoch.toString();
      print("@@fineName: $fineName");
      filePath= "$mediaDirPath/$fineName.$extension";
      print("@@filePath: $filePath");
    } catch(error) {
      print("ERROR: $error");
      showToastMsg(msg: "ERROR: $error");
      filePath= null;
    }
    return filePath;
  }

  Future<FileSystemEntity> getLastImage() async {
    var lastFile;
    try {
      final Directory appExtDir = await this.getStorageDirectory();
      print("@@appExtDir: $appExtDir");
      final String mediaDirPath= "${appExtDir.path}/media";
      final bool isMediaDirExist= await Directory(mediaDirPath).exists();
      if(isMediaDirExist) {
        final Directory mediaDir = new Directory(mediaDirPath);
        List<FileSystemEntity> images;
        images= mediaDir.listSync(recursive: true, followLinks: false);
        if(images.length > 0) {
          images.sort((a, b) {
            return b.path.compareTo(a.path);
          });
          lastFile = images[0];
          var extension = path.extension(lastFile.path);
          if (extension == '.jpeg') {
            //return lastFile;
          } else {
            String thumb = await Thumbnails.getThumbnail(
                videoFile: lastFile.path,
                imageType: ThumbFormat.PNG,
                quality: 30);
            //return File(thumb);
            lastFile = File(thumb);
          }
        }
      }
    } catch(error) {
      print("ERROR: $error");
      showToastMsg(msg: "ERROR: $error");
    }
    return lastFile;
  }

  Future<List<FileSystemEntity>> getAllDirFiles() async {
    List<FileSystemEntity> images;
    try {
      final Directory appExtDir = await this.getStorageDirectory();
      final String mediaDirPath= "${appExtDir.path}/media";
      final bool isMediaDirExist= await Directory(mediaDirPath).exists();
      if(isMediaDirExist) {
        final Directory mediaDir= Directory(mediaDirPath);
        images= mediaDir.listSync(recursive: true, followLinks: false);
        images.sort((a, b) {
          return b.path.compareTo(a.path);
        });
      }
    } catch(error) {
      print("ERROR: $error");
      showToastMsg(msg: "ERROR: $error");
    }
    return images;
  }

  void deleteFile(String path) {
    if(path != null ) {
      final dir = Directory(path);
      dir.deleteSync(recursive: true);
    }
  }
}
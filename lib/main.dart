import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:file_utils/file_utils.dart';
import 'dart:math';

import 'package:whatsapp_share/whatsapp_share.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = new MyHttpOverrides();

  ByteData data =
      await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
  SecurityContext.defaultContext
      .setTrustedCertificatesBytes(data.buffer.asUint8List());

  runApp(Downloader());
}

class Downloader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: "File Downloader",
        debugShowCheckedModeBanner: false,
        home: FileDownloader(),
        theme: ThemeData(primarySwatch: Colors.blue),
      );
}

class FileDownloader extends StatefulWidget {
  @override
  _FileDownloaderState createState() => _FileDownloaderState();
}

class _FileDownloaderState extends State<FileDownloader> {
  bool downloading = false;
  var progress = "";
  var path = "No Data";
  var platformVersion = "Unknown";
  Permission permission1 = Permission.WriteExternalStorage;
  var _onPressed;
  static final Random random = Random();

  Future<void> downloadImage(imgUrl1) async {
    Dio dio = Dio();
    String dirloc = "";

    bool checkPermission1 =
        await SimplePermissions.checkPermission(permission1);
    // print(checkPermission1);
    if (checkPermission1 == false) {
      await SimplePermissions.requestPermission(permission1);
      checkPermission1 = await SimplePermissions.checkPermission(permission1);
    }
    if (checkPermission1 == true) {
      String dirloc = "";
      if (Platform.isAndroid) {
        dirloc = "/sdcard/download/";
      } else {
        dirloc = (await getApplicationDocumentsDirectory()).path;
      }

      var randid = random.nextInt(10000);

      try {
        FileUtils.mkdir([dirloc]);
        await dio.download(imgUrl1, dirloc + randid.toString() + ".jpg",
            onReceiveProgress: (receivedBytes, totalBytes) {
          setState(() {
            downloading = true;
            progress =
                ((receivedBytes / totalBytes) * 100).toStringAsFixed(0) + "%";
          });
        });
      } catch (e) {
        print(e);
      }

      setState(() {
        downloading = false;
        progress = "Download Completed.";
        path = dirloc + randid.toString() + ".jpg";
      });
    } else {
      setState(() {
        progress = "Permission Denied!";
        _onPressed = () {
          downloadImage(imgUrl1);
        };
      });
    }
  }

  // Future<void> isInstalled() async {
  //   final val = await WhatsappShare.isInstalled(package: Package.whatsapp);
  //   print('Whatsapp Business is installed: $val');
  // }

  // Future<void> shareFile() async {
  //   await WhatsappShare.shareFile(
  //       text: 'Whatsapp share text',
  //       phone: '+201103761776',
  //       filePath: [path],
  //       package: Package.whatsapp);
  // }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('File Downloader'),
        ),
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: () async {
                    const imgUrl =
                        "https://images.pexels.com/photos/2246476/pexels-photo-2246476.jpeg?auto=compress&cs=tinysrgb&w=400";
                    downloadImage(imgUrl);
                  },
                  child: Text('حمل اي صوره يا رايس')),
              downloading
                  ? Container(
                      height: 120.0,
                      width: 200.0,
                      child: Card(
                        color: Color.fromARGB(255, 172, 39, 39),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircularProgressIndicator(),
                            SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              'Downloading File: $progress',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(path),
                        MaterialButton(
                          child: Text('Request Permission Again.'),
                          onPressed: _onPressed,
                          disabledColor: Colors.indigo,
                          color: Colors.pink,
                          textColor: Colors.white,
                          height: 40.0,
                          minWidth: 100.0,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      );
}

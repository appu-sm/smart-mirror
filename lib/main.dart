import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const SmartMirror());
}

class SmartMirror extends StatefulWidget {
  const SmartMirror({super.key});

  @override
  State<SmartMirror> createState() => _SmartMirrorState();
}

class _SmartMirrorState extends State<SmartMirror> {
  late CameraController cameraCtrl;
  double _brightnessLevel = 0.3;
  double _zoomLevel = 1.0;
  bool flash = false;
  final double previewPadding = 100.0; // Adjust the padding as needed
  final double iconSize = 40.0;
  final Color iconDefaultColor = Colors.black;
  final Color iconEnabledColor = Colors.white;
  final double zoomSteps = 0.25;

  @override
  void initState() {
    super.initState();
    cameraCtrl = CameraController(_cameras[1], ResolutionPreset.ultraHigh, enableAudio: false);
    cameraCtrl.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      Map error = {};
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            error = {
              "title": "Camera Error",
              "content": "Camera permission not provided, App will exit now ${e.toString()}"
            };
            break;
          default:
            error = {"title": "Camera Error", "content": "Camera error occured: ${e.toString()}"};
            break;
        }
      } else {
        error = {
          "title": "Unknown Error",
          "content": "Unknown runtime error occured, App will exit now ${e.toString()}"
        };
      }
      AlertDialog(
        actions: [
          TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
                exit(0);
              })
        ],
        title: Text(error['title']),
        content: Text(error['content']),
      );
    });
  }

  @override
  void dispose() {
    cameraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!cameraCtrl.value.isInitialized) {
      return Container();
    }
    final CameraValue camera = cameraCtrl.value;
    final Size size = MediaQuery.of(context).size;
    final double aspectRatio = camera.aspectRatio < 1 ? 1 / camera.aspectRatio : camera.aspectRatio;

    return MaterialApp(
        home: Scaffold(
            body: Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                    padding: EdgeInsets.symmetric(vertical: previewPadding),
                    child: Stack(children: [
                      Positioned.fill(
                          child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: Transform.scale(scale: aspectRatio, child: CameraPreview(cameraCtrl)))),
                      Positioned(
                          left: size.width / 15,
                          bottom: size.height / 15,
                          child: InkWell(
                              child: Icon(Icons.lightbulb_circle_sharp,
                                  size: iconSize, color: flash ? iconEnabledColor : iconDefaultColor),
                              onTap: () {
                                setState(() {
                                  flash = !flash;
                                  cameraCtrl.setFlashMode(flash ? FlashMode.torch : FlashMode.off);
                                });
                              })),
                      Positioned(
                          left: size.width / 18,
                          bottom: size.height / 10,
                          child: RotatedBox(
                              quarterTurns: -1,
                              child: Slider(
                                  value: _brightnessLevel,
                                  min: 0,
                                  divisions: (zoomSteps * 100).toInt(),
                                  max: 1,
                                  onChanged: (double value) {
                                    setState(() {
                                      _brightnessLevel = value;
                                      ScreenBrightness().setScreenBrightness(_brightnessLevel);
                                    });
                                  }))),
                      Positioned(
                          left: size.width / 5,
                          bottom: size.height / 100,
                          child: Row(children: [
                            InkWell(
                                child: Icon(Icons.zoom_out,
                                    color: _zoomLevel > 1 ? iconEnabledColor : iconDefaultColor, size: iconSize),
                                onTap: () => setState(() {
                                      if (_zoomLevel > 1) {
                                        _zoomLevel -= zoomSteps;
                                        cameraCtrl.setZoomLevel(_zoomLevel);
                                      }
                                    })),
                            Slider(
                                value: _zoomLevel,
                                min: 1,
                                divisions: (zoomSteps * 100).toInt(),
                                max: 10,
                                onChanged: (double value) {
                                  setState(() {
                                    _zoomLevel = value;
                                    cameraCtrl.setZoomLevel(_zoomLevel);
                                  });
                                }),
                            InkWell(
                                child: Icon(Icons.zoom_in,
                                    color: _zoomLevel < 10 ? iconEnabledColor : iconDefaultColor, size: iconSize),
                                onTap: () => setState(() {
                                      if (_zoomLevel < 10) {
                                        _zoomLevel += zoomSteps;
                                        cameraCtrl.setZoomLevel(_zoomLevel);
                                      }
                                    }))
                          ]))
                    ])))));
  }
}

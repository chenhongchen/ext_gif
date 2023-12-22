import 'package:ext_gif/ext_image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _gifUrl =
      'http://img.mp.itc.cn/upload/20161107/5cad975eee9e4b45ae9d3c1238ccf91e.jpg';
  bool _canMultiFrame = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ExtImage(
                image: ExtendedNetworkImageProvider(_gifUrl),
                fit: BoxFit.cover,
                canMultiFrame: _canMultiFrame,
              ),
            ),
          ],
        ),
        floatingActionButton: GestureDetector(
          onTap: () {
            _canMultiFrame = !_canMultiFrame;
            setState(() {});
          },
          child: Container(
            color: Colors.red,
            width: 60,
            height: 60,
            child: const Icon(
              Icons.switch_access_shortcut,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

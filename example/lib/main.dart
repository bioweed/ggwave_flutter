import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:ggwave_flutter/ggwave_flutter.dart' as ggwave_flutter;

import 'package:flutter_sound/flutter_sound.dart';
// import 'package:sound_stream/sound_stream.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int sumResult;
  late Future<int> sumAsyncResult;
  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer(logLevel: Level.info);
  FlutterSoundRecorder _mRecorder = FlutterSoundRecorder(logLevel: Level.info);
  bool _mPlayerIsInited = false;
  final controller = StreamController<FoodData>.broadcast();
  List<Uint8List> buffer = [];
  Uint8List buffer2 = Uint8List(0);
  BytesBuilder buffer3 = BytesBuilder();
  String string = "";

  // PlayerStream _player = PlayerStream();

  @override
  void initState() {
    super.initState();
    sumResult = ggwave_flutter.sum(1, 2);
    sumAsyncResult = ggwave_flutter.sumAsync(3, 4);
    _mPlayer.openPlayer().then((value) {
      print("initialted");
      setState(() {
        _mPlayerIsInited = true;
      });
    });

    controller.stream.listen((event) {
      if (event.data != null) {
        // buffer2 = Uint8List.fromList(buffer2 + event.data! as Uint8List);
        buffer3.add(event.data!);
      }
    });

    string = ggwave_flutter.test("a");

    // _player.initialize().then((value) {
    //   print("initialted");

    //   setState(() {
    //     _mPlayerIsInited = true;
    //   });
    // });
  }

  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    _mPlayer.closePlayer();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    ggwave_flutter.init();
    ggwave_flutter.bar();
    var res = ggwave_flutter.convertDataToAudio("Hello Android!",
        protocol: ggwave_flutter
            .GGWaveTxProtocolId.GGWAVE_TX_PROTOCOL_ULTRASOUND_FASTEST);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                Text(
                  'sum(1, 2) = $sumResult',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                FutureBuilder<int>(
                  future: sumAsyncResult,
                  builder: (BuildContext context, AsyncSnapshot<int> value) {
                    final displayValue =
                        (value.hasData) ? value.data : 'loading';
                    return Text(
                      'await sumAsync(3, 4) = $displayValue',
                      style: textStyle,
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                FloatingActionButton.extended(
                  heroTag: "play",
                  onPressed: () {
                    if (_mPlayerIsInited) {
                      // _mPlayer.startPlayer(fromDataBuffer: res);
                      _mPlayer.startPlayer(
                          fromDataBuffer: res,
                          codec: Codec.pcm16,
                          sampleRate: 48000,
                          numChannels: 1);
                    }
                  },
                  label: Text("play"),
                ),
                Text(string),
                FloatingActionButton.extended(
                  heroTag: "rec",
                  onPressed: () async {
                    var status = await Permission.microphone.request();
                    if (status != PermissionStatus.granted) {
                      throw RecordingPermissionException(
                          'Microphone permission not granted');
                    }

                    await _mRecorder.openRecorder();
                    _mRecorder.startRecorder(
                        codec: Codec.pcm16,
                        sampleRate: 48000,
                        bitRate: 48000,
                        toStream: controller.sink);
                  },
                  label: Text("record"),
                ),
                FloatingActionButton.extended(
                  heroTag: "play2",
                  onPressed: () async {
                    await _mRecorder.stopRecorder();
                    if (_mPlayerIsInited) {
                      //buffer.fold(Uint8List(0), (previousValue, element) => Uint8List(previousValue!.length+ element.length))
                      // _mPlayer.startPlayer(fromDataBuffer: res);
                      // var b = BytesBuilder();
                      // b.add(buffer as List<int>);
                      _mPlayer.startPlayer(
                          fromDataBuffer: buffer3.toBytes(),
                          codec: Codec.pcm16,
                          sampleRate: 48000,
                          numChannels: 1);
                    }
                  },
                  label: Text("play recorded"),
                ),
                FloatingActionButton.extended(
                  heroTag: "convert",
                  onPressed: () async {
                    await _mRecorder.stopRecorder();

                    setState(() {
                      string = ggwave_flutter
                              .convertAudioToData(buffer3.toBytes()) ??
                          "N/A";
                    });
                  },
                  label: Text("processs"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

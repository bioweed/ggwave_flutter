import 'dart:developer';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:ggwave_flutter/ggwave_flutter.dart' as ggwave_flutter;

import 'package:flutter_sound/flutter_sound.dart';
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
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer(logLevel: Level.info);
  final FlutterSoundRecorder _mRecorder =
      FlutterSoundRecorder(logLevel: Level.info);
  bool _mPlayerIsInited = false;
  final controller = StreamController<FoodData>.broadcast();
  final controller2 = StreamController<FoodData>.broadcast();
  final controller3 = StreamController<FoodData>.broadcast();
  StreamSubscription? streamSubscription;
  StreamSubscription? streamSubscription2;
  StreamSubscription? streamSubscription3;
  BytesBuilder receivedAudioData = BytesBuilder();
  String _receivedMessage = "";
  final _rxTxProtocolID =
      ggwave_flutter.GGWaveTxProtocolId.GGWAVE_TX_PROTOCOL_AUDIBLE_FASTEST;
  Uint8List? _audioData;
  BytesBuilder bb = BytesBuilder(copy: false)..add(Uint8List(500000));
  BytesBuilder bb1 = BytesBuilder(copy: true);
  List<Uint8List> buffer = List.filled(400, Uint8List(0), growable: true);
  int counter = 0;

  @override
  void initState() {
    super.initState();
    print("inti");
    sumResult = ggwave_flutter.sum(1, 2);
    sumAsyncResult = ggwave_flutter.sumAsync(3, 4);
    _mPlayer.openPlayer().then((value) {
      debugPrint("initialted");
      setState(() {
        _mPlayerIsInited = true;
      });
    });

    streamSubscription = controller.stream.listen((foodData) {
      if (foodData.data != null) {
        receivedAudioData.add(foodData.data!);
      }
    });

    ggwave_flutter.init();
    ggwave_flutter.setRxProtocolID(_rxTxProtocolID);
    _audioData = ggwave_flutter.convertDataToAudio("Hello Android!",
        protocol: _rxTxProtocolID);
    ggwave_flutter.deinit();

    streamSubscription2 = controller2.stream.listen((foodData) {
      if (foodData.data != null) {
        // buffer.add(foodData.data!);

        bb.add(foodData.data!);
        // counter += foodData.data!.length;
        if (bb.length > 800000) {
          // if (buffer.length > 600) {
          Timeline.startSync("Doing Something");
          var data =
              // Uint8List.fromList(buffer.expand((element) => element).toList());
              bb.takeBytes();

          bb.add(data.sublist(300000));
          // buffer = buffer.sublist(200);
          // counter = 0;
          print(data.length);
          ggwave_flutter.init();

          var a = ggwave_flutter.convertAudioToData(data);
          ggwave_flutter.deinit();

          Timeline.finishSync();
          print(a);
          if (a != null) {
            setState(() {
              _receivedMessage = a;
            });
          }
        }
      }
    });

    streamSubscription3 = controller3.stream.listen((foodData) {
      if (foodData.data != null) {
        // buffer.add(foodData.data!);

        bb1.add(foodData.data!);
        // counter += foodData.data!.length;
        if (bb1.length > 500000) {
          // if (buffer.length > 600) {
          // Timeline.startSync("Doing Something");
          var data = bb1.takeBytes();

          print(data.length);
          // ggwave_flutter.init();

          var a = ggwave_flutter.convertAudioToData(data);
          // ggwave_flutter.deinit();

          // Timeline.finishSync();
          print(a);
          if (a != null) {
            setState(() {
              _receivedMessage = a;
            });
          }
        }
      }
    });
  }

  void stop() {
    _mPlayer.closePlayer();
    _mRecorder.stopRecorder();
    streamSubscription?.cancel();
    streamSubscription2?.cancel();
    streamSubscription3?.cancel();
  }

  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    stop();
    ggwave_flutter.deinit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
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
                      _mPlayer.startPlayer(
                          fromDataBuffer: _audioData,
                          codec: Codec.pcm16,
                          sampleRate: 48000,
                          numChannels: 1);
                    }
                  },
                  label: const Text("play"),
                ),
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
                  label: const Text("record"),
                ),
                FloatingActionButton.extended(
                  heroTag: "rec and dec",
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
                        toStream: controller2.sink);
                  },
                  label: const Text("record and decode"),
                ),
                FloatingActionButton.extended(
                  heroTag: "rec and dec2",
                  onPressed: () async {
                    var status = await Permission.microphone.request();
                    if (status != PermissionStatus.granted) {
                      throw RecordingPermissionException(
                          'Microphone permission not granted');
                    }
                    ggwave_flutter.init();

                    await _mRecorder.openRecorder();
                    _mRecorder.startRecorder(
                        codec: Codec.pcm16,
                        sampleRate: 48000,
                        bitRate: 48000,
                        toStream: controller3.sink);
                  },
                  label: const Text("record and decode2"),
                ),
                FloatingActionButton.extended(
                  heroTag: "play2",
                  onPressed: () async {
                    await _mRecorder.stopRecorder();
                    if (_mPlayerIsInited) {
                      _mPlayer.startPlayer(
                          fromDataBuffer: receivedAudioData.toBytes(),
                          codec: Codec.pcm16,
                          sampleRate: 48000,
                          numChannels: 1);
                    }
                  },
                  label: const Text("play recorded"),
                ),
                FloatingActionButton.extended(
                  heroTag: "play3",
                  onPressed: () async {
                    await _mRecorder.stopRecorder();
                    var data = receivedAudioData.toBytes();

                    if (_mPlayerIsInited) {
                      _mPlayer.startPlayer(
                          fromDataBuffer:
                              data.sublist(max(data.length - 500000, 0)),
                          codec: Codec.pcm16,
                          sampleRate: 48000,
                          numChannels: 1);
                    }
                  },
                  label: const Text("play recorded 2"),
                ),
                FloatingActionButton.extended(
                  heroTag: "convert",
                  onPressed: () async {
                    await _mRecorder.stopRecorder();
                    var bytes = receivedAudioData.toBytes();
                    print(bytes.length);
                    print(bytes.last);
                    var data = receivedAudioData.toBytes();
                    var decoded = ggwave_flutter.convertAudioToData(
                        data.sublist(max(data.length - 500000, 0)));
                    print(decoded);
                    setState(() {
                      _receivedMessage = decoded ?? "N/A";
                    });
                  },
                  label: const Text("process"),
                ),
                FloatingActionButton.extended(
                  heroTag: "convert2",
                  onPressed: () async {
                    await _mRecorder.stopRecorder();
                    var bytes = receivedAudioData.toBytes();
                    print(bytes.length);
                    print(bytes.last);
                    ggwave_flutter.init();
                    var decoded = ggwave_flutter
                        .convertAudioToData(receivedAudioData.toBytes());
                    print(decoded);
                    setState(() {
                      _receivedMessage = decoded ?? "N/A";
                    });
                  },
                  label: const Text("process"),
                ),
                FloatingActionButton.extended(
                  heroTag: "clear",
                  onPressed: () async {
                    await _mRecorder.stopRecorder();
                    receivedAudioData.clear();
                  },
                  label: const Text("clear"),
                ),
                FloatingActionButton.extended(
                  heroTag: "stop",
                  onPressed: () => stop(),
                  label: const Text("stop"),
                ),
                Text(_receivedMessage),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

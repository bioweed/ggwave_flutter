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
  StreamSubscription? streamSubscription;
  BytesBuilder receivedAudioData = BytesBuilder();
  String _receivedMessage = "";
  final _rxTxProtocolID =
      ggwave_flutter.GGWaveTxProtocolId.GGWAVE_TX_PROTOCOL_AUDIBLE_FASTEST;
  Uint8List? _audioData;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    _mPlayer.closePlayer();
    _mRecorder.stopRecorder();
    streamSubscription?.cancel();
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
                  heroTag: "convert",
                  onPressed: () async {
                    await _mRecorder.stopRecorder();

                    setState(() {
                      _receivedMessage = ggwave_flutter.convertAudioToData(
                              receivedAudioData.toBytes()) ??
                          "N/A";
                    });
                  },
                  label: const Text("process"),
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

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:ggwave_flutter/ggwave_flutter.dart' as ggwave_flutter;

import 'package:flutter_sound/flutter_sound.dart';
// import 'package:sound_stream/sound_stream.dart';

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
  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;
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
    var string = ggwave_flutter.test("a");
    ggwave_flutter.init();
    ggwave_flutter.bar();
    var res = ggwave_flutter.convertDataToAudio("Hello Android!");
    if (_mPlayerIsInited) {
      // _mPlayer.startPlayer(fromDataBuffer: res);
      _mPlayer.startPlayer(fromDataBuffer: res, codec: Codec.pcm16, sampleRate: 48000, numChannels: 1);
      // _player.start().then((value) => _player.writeChunk(res));
            

      // final fileUri =
      //     "https://upload.wikimedia.org/wikipedia/en/1/1e/City_vs._homer_song.ogg";

      // _mPlayer.startPlayer(
      //   fromURI: fileUri,
      //   codec: Codec.mp3,
      //   whenFinished: () {
      //     _mPlayer.startPlayer(fromDataBuffer: res, codec: Codec.pcm16, sampleRate: 48000, numChannels: 1);
      //     print('I hope you enjoyed listening to this song');
      //   },
      // );
    }
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
                Text(string),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

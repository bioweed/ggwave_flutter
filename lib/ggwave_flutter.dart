import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'ggwave_flutter_bindings_generated.dart';
import 'package:ffi/ffi.dart';

// TxProtocol ids
enum GGWaveTxProtocolId {
  GGWAVE_TX_PROTOCOL_AUDIBLE_NORMAL,
  GGWAVE_TX_PROTOCOL_AUDIBLE_FAST,
  GGWAVE_TX_PROTOCOL_AUDIBLE_FASTEST,
  GGWAVE_TX_PROTOCOL_ULTRASOUND_NORMAL,
  GGWAVE_TX_PROTOCOL_ULTRASOUND_FAST,
  GGWAVE_TX_PROTOCOL_ULTRASOUND_FASTEST,
  GGWAVE_TX_PROTOCOL_DT_NORMAL,
  GGWAVE_TX_PROTOCOL_DT_FAST,
  GGWAVE_TX_PROTOCOL_DT_FASTEST,

  // GGWAVE_TX_PROTOCOL_CUSTOM_0,
  // GGWAVE_TX_PROTOCOL_CUSTOM_1,
  // GGWAVE_TX_PROTOCOL_CUSTOM_2,
  // GGWAVE_TX_PROTOCOL_CUSTOM_3,
  // GGWAVE_TX_PROTOCOL_CUSTOM_4,
  // GGWAVE_TX_PROTOCOL_CUSTOM_5,
  // GGWAVE_TX_PROTOCOL_CUSTOM_6,
  // GGWAVE_TX_PROTOCOL_CUSTOM_7,
  // GGWAVE_TX_PROTOCOL_CUSTOM_8,
  // GGWAVE_TX_PROTOCOL_CUSTOM_9,
}

void init() => _bindings.initNative();

void deinit() => _bindings.deinit();

Uint8List? convertDataToAudio(String data,
    {GGWaveTxProtocolId protocol =
        GGWaveTxProtocolId.GGWAVE_TX_PROTOCOL_AUDIBLE_FAST}) {
  var dataPointer = data.toNativeUtf8().cast<Int8>();
  Pointer<Pointer<Int8>> out = malloc();
  int length = _bindings.convertDataToAudio(
      dataPointer, data.length, out, protocol.index);
  if (length < 0) {
    malloc.free(dataPointer);
    malloc.free(out.value);
    malloc.free(out);
    return null;
  }

  Uint8List audioDataInCMemory = out.value.cast<Uint8>().asTypedList(length);
  // create copy for dart GC
  // see https://github.com/dart-lang/ffi/issues/22
  Uint8List audioData = Uint8List.fromList(audioDataInCMemory);
  malloc.free(out.value);
  malloc.free(out);
  return audioData;
}

String? convertAudioToData(Uint8List audio) =>
    _convertAudioToData(audio, _bindings.processCaptureData);
String? convertAudioToDataOneShot(Uint8List audio, {List<int>? protocols}) {
  if (protocols != null) {
    Pointer<Int8> protocolPointer = malloc(protocols.length);
    protocolPointer.asTypedList(protocols.length).setAll(0, protocols);
    var res = _convertAudioToData(
        audio,
        (
          Pointer<Int8> payload,
          int payloadSize,
          Pointer<Pointer<Int8>> out,
        ) =>
            _bindings.processCaptureDataLocalwithProtocols(
                protocolPointer, payload, payloadSize, out));
    malloc.free(protocolPointer);
    return res;
  }

  return _convertAudioToData(audio, _bindings.processCaptureDataLocal);
}

String? _convertAudioToData(
  Uint8List audio,
  int Function(
    Pointer<Int8> payload,
    int payloadSize,
    Pointer<Pointer<Int8>> out,
  )
      converter,
) {
  Pointer<Int8> dataPointer = malloc(audio.length);
  // print(audio.length);
  Pointer<Pointer<Int8>> out = malloc();
  dataPointer.asTypedList(audio.length).setAll(0, audio);
  int length = converter(dataPointer, audio.length, out);
  // print(size);
  String? data;
  if (length > 0) {
    data = out.value.cast<Utf8>().toDartString(length: length);
  } else if (length < 0) {
    dev.log("error during decoding: $length", error: null);
  }
  malloc.free(dataPointer);
  malloc.free(out.value);
  malloc.free(out);
  return data;
}

void setRxProtocolID(GGWaveTxProtocolId? protocolID) {
  if (protocolID != null) {
    _bindings.setRxProtocolID(protocolID.index);
  } else {
    _bindings.setRxProtocolID(-1);
  }
}

void setRxProtocolIDs({
  List<int>? protocolSettings,
  bool GGWAVE_TX_PROTOCOL_AUDIBLE_NORMAL = false,
  bool GGWAVE_TX_PROTOCOL_AUDIBLE_FAST = false,
  bool GGWAVE_TX_PROTOCOL_AUDIBLE_FASTEST = false,
  bool GGWAVE_TX_PROTOCOL_ULTRASOUND_NORMAL = false,
  bool GGWAVE_TX_PROTOCOL_ULTRASOUND_FAST = false,
  bool GGWAVE_TX_PROTOCOL_ULTRASOUND_FASTEST = false,
  bool GGWAVE_TX_PROTOCOL_DT_NORMAL = false,
  bool GGWAVE_TX_PROTOCOL_DT_FAST = false,
  bool GGWAVE_TX_PROTOCOL_DT_FASTEST = false,
}) {
  protocolSettings ??= settingsToList(
      GGWAVE_TX_PROTOCOL_AUDIBLE_NORMAL,
      GGWAVE_TX_PROTOCOL_AUDIBLE_FAST,
      GGWAVE_TX_PROTOCOL_AUDIBLE_FASTEST,
      GGWAVE_TX_PROTOCOL_ULTRASOUND_NORMAL,
      GGWAVE_TX_PROTOCOL_ULTRASOUND_FAST,
      GGWAVE_TX_PROTOCOL_ULTRASOUND_FASTEST,
      GGWAVE_TX_PROTOCOL_DT_NORMAL,
      GGWAVE_TX_PROTOCOL_DT_FAST,
      GGWAVE_TX_PROTOCOL_DT_FASTEST);
  Pointer<Int8> settingsPointer = malloc(protocolSettings.length);
  settingsPointer
      .asTypedList(protocolSettings.length)
      .setAll(0, protocolSettings);
  _bindings.setRxProtocolIDs(settingsPointer);
  malloc.free(settingsPointer);
}

List<int> settingsToList(
    bool GGWAVE_TX_PROTOCOL_AUDIBLE_NORMAL,
    bool GGWAVE_TX_PROTOCOL_AUDIBLE_FAST,
    bool GGWAVE_TX_PROTOCOL_AUDIBLE_FASTEST,
    bool GGWAVE_TX_PROTOCOL_ULTRASOUND_NORMAL,
    bool GGWAVE_TX_PROTOCOL_ULTRASOUND_FAST,
    bool GGWAVE_TX_PROTOCOL_ULTRASOUND_FASTEST,
    bool GGWAVE_TX_PROTOCOL_DT_NORMAL,
    bool GGWAVE_TX_PROTOCOL_DT_FAST,
    bool GGWAVE_TX_PROTOCOL_DT_FASTEST) {
  List<int> settings = [
    GGWAVE_TX_PROTOCOL_AUDIBLE_NORMAL ? 1 : 0,
    GGWAVE_TX_PROTOCOL_AUDIBLE_FAST ? 1 : 0,
    GGWAVE_TX_PROTOCOL_AUDIBLE_FASTEST ? 1 : 0,
    GGWAVE_TX_PROTOCOL_ULTRASOUND_NORMAL ? 1 : 0,
    GGWAVE_TX_PROTOCOL_ULTRASOUND_FAST ? 1 : 0,
    GGWAVE_TX_PROTOCOL_ULTRASOUND_FASTEST ? 1 : 0,
    GGWAVE_TX_PROTOCOL_DT_NORMAL ? 1 : 0,
    GGWAVE_TX_PROTOCOL_DT_FAST ? 1 : 0,
    GGWAVE_TX_PROTOCOL_DT_FASTEST ? 1 : 0,
  ];
  return settings;
}

/// A very short-lived native function.
///
/// For very short-lived functions, it is fine to call them on the main isolate.
/// They will block the Dart execution while running the native function, so
/// only do this for native functions which are guaranteed to be short-lived.
int sum(int a, int b) => _bindings.sum(a, b);

/// A longer lived native function, which occupies the thread calling it.
///
/// Do not call these kind of native functions in the main isolate. They will
/// block Dart execution. This will cause dropped frames in Flutter applications.
/// Instead, call these native functions on a separate isolate.
///
/// Modify this to suit your own use case. Example use cases:
///
/// 1. Reuse a single isolate for various different kinds of requests.
/// 2. Use multiple helper isolates for parallel execution.
Future<int> sumAsync(int a, int b) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextSumRequestId++;
  final _SumRequest request = _SumRequest(requestId, a, b);
  final Completer<int> completer = Completer<int>();
  _sumRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

const String _libName = 'ggwave_flutter';

/// The dynamic library in which the symbols for [GgwaveFlutterBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final GgwaveFlutterBindings _bindings = GgwaveFlutterBindings(_dylib);

/// A request to compute `sum`.
///
/// Typically sent from one isolate to another.
class _SumRequest {
  final int id;
  final int a;
  final int b;

  const _SumRequest(this.id, this.a, this.b);
}

/// A response with the result of `sum`.
///
/// Typically sent from one isolate to another.
class _SumResponse {
  final int id;
  final int result;

  const _SumResponse(this.id, this.result);
}

/// Counter to identify [_SumRequest]s and [_SumResponse]s.
int _nextSumRequestId = 0;

/// Mapping from [_SumRequest] `id`s to the completers corresponding to the correct future of the pending request.
final Map<int, Completer<int>> _sumRequests = <int, Completer<int>>{};

/// The SendPort belonging to the helper isolate.
Future<SendPort> _helperIsolateSendPort = () async {
  // The helper isolate is going to send us back a SendPort, which we want to
  // wait for.
  final Completer<SendPort> completer = Completer<SendPort>();

  // Receive port on the main isolate to receive messages from the helper.
  // We receive two types of messages:
  // 1. A port to send messages on.
  // 2. Responses to requests we sent.
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is SendPort) {
        // The helper isolate sent us the port on which we can sent it requests.
        completer.complete(data);
        return;
      }
      if (data is _SumResponse) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<int> completer = _sumRequests[data.id]!;
        _sumRequests.remove(data.id);
        completer.complete(data.result);
        return;
      }
      throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
    });

  // Start the helper isolate.
  await Isolate.spawn((SendPort sendPort) async {
    final ReceivePort helperReceivePort = ReceivePort()
      ..listen((dynamic data) {
        // On the helper isolate listen to requests and respond to them.
        if (data is _SumRequest) {
          final int result = _bindings.sum_long_running(data.a, data.b);
          final _SumResponse response = _SumResponse(data.id, result);
          sendPort.send(response);
          return;
        }
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      });

    // Send the the port to the main isolate on which we can receive requests.
    sendPort.send(helperReceivePort.sendPort);
  }, receivePort.sendPort);

  // Wait until the helper isolate has sent us back the SendPort on which we
  // can start sending requests.
  return completer.future;
}();

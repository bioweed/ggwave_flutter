#include "ggwave_flutter.h"

ggwave_Instance g_ggwave;

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT intptr_t sum(intptr_t a, intptr_t b) { return a + b; }

// A longer-lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT intptr_t sum_long_running(intptr_t a, intptr_t b)
{
  // Simulate work.
#if _WIN32
  Sleep(5000);
#else
  usleep(5000 * 1000);
#endif
  return a + b;
}

FFI_PLUGIN_EXPORT void initNative()
{
  ggwave_Parameters parameters = ggwave_getDefaultParameters();
  parameters.sampleFormatInp = GGWAVE_SAMPLE_FORMAT_I16;
  parameters.sampleFormatOut = GGWAVE_SAMPLE_FORMAT_I16;
  parameters.sampleRateInp = 48000;
  g_ggwave = ggwave_init(parameters);
  // turn off custom RX protocols
  ggwave_toggleRxProtocol(g_ggwave, 9, 0);
  ggwave_toggleRxProtocol(g_ggwave, 10, 0);
  ggwave_toggleRxProtocol(g_ggwave, 11, 0);
  ggwave_toggleRxProtocol(g_ggwave, 12, 0);
  ggwave_toggleRxProtocol(g_ggwave, 13, 0);
  ggwave_toggleRxProtocol(g_ggwave, 14, 0);
  ggwave_toggleRxProtocol(g_ggwave, 15, 0);
  ggwave_toggleRxProtocol(g_ggwave, 16, 0);
  ggwave_toggleRxProtocol(g_ggwave, 17, 0);
  ggwave_toggleRxProtocol(g_ggwave, 18, 0);
}

FFI_PLUGIN_EXPORT void deinit()
{
  ggwave_free(g_ggwave);
}

FFI_PLUGIN_EXPORT int convertDataToAudio(const char *dataBuffer, int dataSize, char **out, int protocolID)
{
  const int n = ggwave_encode(g_ggwave, dataBuffer, dataSize, protocolID, 10, NULL, 1);
  char *waveform = malloc(sizeof(char) * n);
  const int samples = ggwave_encode(g_ggwave, dataBuffer, dataSize, protocolID, 10, waveform, 0);
  if (2 * samples != n)
  {
    free(waveform);
    return -1;
  }
  *out = waveform;
  return n;
}

FFI_PLUGIN_EXPORT int processCaptureData(const char *dataBuffer, int dataSize, char **out)
{
  char *output = malloc(sizeof(char) * 256);
  int ret = ggwave_decode(g_ggwave, dataBuffer, dataSize, output);
  *out = output;
  return ret;
}

FFI_PLUGIN_EXPORT int processCaptureDataLocal(const char *dataBuffer, int dataSize, char **out)
{
  ggwave_Parameters parameters = ggwave_getDefaultParameters();
  parameters.sampleFormatInp = GGWAVE_SAMPLE_FORMAT_I16;
  parameters.sampleFormatOut = GGWAVE_SAMPLE_FORMAT_I16;
  parameters.sampleRateInp = 48000;
  ggwave_Instance local_ggwave = ggwave_init(parameters);
  char *output = malloc(sizeof(char) * 256);
  int ret = ggwave_decode(local_ggwave, dataBuffer, dataSize, output);
  ggwave_free(local_ggwave);
  *out = output;
  return ret;
}

FFI_PLUGIN_EXPORT int processCaptureDataLocalwithProtocols(char *protocolIDs, const char *dataBuffer, int dataSize, char **out)
{
  ggwave_Parameters parameters = ggwave_getDefaultParameters();
  parameters.sampleFormatInp = GGWAVE_SAMPLE_FORMAT_I16;
  parameters.sampleFormatOut = GGWAVE_SAMPLE_FORMAT_I16;
  parameters.sampleRateInp = 48000;
  ggwave_Instance local_ggwave = ggwave_init(parameters);
  ggwave_toggleRxProtocol(local_ggwave, 0, protocolIDs[0]);
  ggwave_toggleRxProtocol(local_ggwave, 1, protocolIDs[1]);
  ggwave_toggleRxProtocol(local_ggwave, 2, protocolIDs[2]);
  ggwave_toggleRxProtocol(local_ggwave, 3, protocolIDs[3]);
  ggwave_toggleRxProtocol(local_ggwave, 4, protocolIDs[4]);
  ggwave_toggleRxProtocol(local_ggwave, 5, protocolIDs[5]);
  ggwave_toggleRxProtocol(local_ggwave, 6, protocolIDs[6]);
  ggwave_toggleRxProtocol(local_ggwave, 7, protocolIDs[7]);
  ggwave_toggleRxProtocol(local_ggwave, 8, protocolIDs[8]);
  ggwave_toggleRxProtocol(local_ggwave, 9, protocolIDs[9]);
  char *output = malloc(sizeof(char) * 256);
  int ret = ggwave_decode(local_ggwave, dataBuffer, dataSize, output);
  ggwave_free(local_ggwave);
  *out = output;
  return ret;
}

FFI_PLUGIN_EXPORT void setRxProtocolID(int protocolID)
{
  if (protocolID >= 0 && protocolID < 10)
  {
    ggwave_toggleRxProtocol(g_ggwave, 0, 0);
    ggwave_toggleRxProtocol(g_ggwave, 1, 0);
    ggwave_toggleRxProtocol(g_ggwave, 2, 0);
    ggwave_toggleRxProtocol(g_ggwave, 3, 0);
    ggwave_toggleRxProtocol(g_ggwave, 4, 0);
    ggwave_toggleRxProtocol(g_ggwave, 5, 0);
    ggwave_toggleRxProtocol(g_ggwave, 6, 0);
    ggwave_toggleRxProtocol(g_ggwave, 7, 0);
    ggwave_toggleRxProtocol(g_ggwave, 8, 0);
    ggwave_toggleRxProtocol(g_ggwave, 9, 0);
    ggwave_toggleRxProtocol(g_ggwave, protocolID, 1);
  }
  else
  {
    ggwave_toggleRxProtocol(g_ggwave, 0, 1);
    ggwave_toggleRxProtocol(g_ggwave, 1, 1);
    ggwave_toggleRxProtocol(g_ggwave, 2, 1);
    ggwave_toggleRxProtocol(g_ggwave, 3, 1);
    ggwave_toggleRxProtocol(g_ggwave, 4, 1);
    ggwave_toggleRxProtocol(g_ggwave, 5, 1);
    ggwave_toggleRxProtocol(g_ggwave, 6, 1);
    ggwave_toggleRxProtocol(g_ggwave, 7, 1);
    ggwave_toggleRxProtocol(g_ggwave, 8, 1);
    ggwave_toggleRxProtocol(g_ggwave, 9, 1);
  }
}

FFI_PLUGIN_EXPORT void setRxProtocolIDs(char *protocolIDs)
{
  ggwave_toggleRxProtocol(g_ggwave, 0, protocolIDs[0]);
  ggwave_toggleRxProtocol(g_ggwave, 1, protocolIDs[1]);
  ggwave_toggleRxProtocol(g_ggwave, 2, protocolIDs[2]);
  ggwave_toggleRxProtocol(g_ggwave, 3, protocolIDs[3]);
  ggwave_toggleRxProtocol(g_ggwave, 4, protocolIDs[4]);
  ggwave_toggleRxProtocol(g_ggwave, 5, protocolIDs[5]);
  ggwave_toggleRxProtocol(g_ggwave, 6, protocolIDs[6]);
  ggwave_toggleRxProtocol(g_ggwave, 7, protocolIDs[7]);
  ggwave_toggleRxProtocol(g_ggwave, 8, protocolIDs[8]);
  ggwave_toggleRxProtocol(g_ggwave, 9, protocolIDs[9]);
}

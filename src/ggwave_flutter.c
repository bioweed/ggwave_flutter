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
FFI_PLUGIN_EXPORT intptr_t sum_long_running(intptr_t a, intptr_t b) {
  // Simulate work.
#if _WIN32
  Sleep(5000);
#else
  usleep(5000 * 1000);
#endif
  return a + b;
}

int test(char * out ){
        // __android_log_print(ANDROID_LOG_DEBUG, "ggwave (native)", "test");
    int len = 8;
    // *out = * static_cast<char *>(calloc(7, sizeof(char)));
    strncpy(out, "hello", len);
    // __android_log_print(ANDROID_LOG_DEBUG, "ggwave (native)", "%s", out);
return len;
}

void bar(int** x)
{
   *x = calloc(10,sizeof(int));
   (*x)[4] = 3;
}

void initNative(){
//      __android_log_print(ANDROID_LOG_DEBUG, "ggwave (native)", "Initializing native module");

    ggwave_Parameters parameters = ggwave_getDefaultParameters();
    parameters.sampleFormatInp = GGWAVE_SAMPLE_FORMAT_I16;
    parameters.sampleFormatOut = GGWAVE_SAMPLE_FORMAT_I16;
    parameters.sampleRateInp = 48000;
    g_ggwave = ggwave_init(parameters);
}

int getRequiredBufferSize(const char * dataBuffer, int dataSize){
    return ggwave_encode(g_ggwave, dataBuffer, dataSize, GGWAVE_TX_PROTOCOL_AUDIBLE_FAST, 10, NULL, 1);
}

int convertDataToAudio(const char * dataBuffer, int dataSize, char * out ){

    const int ret = ggwave_encode(g_ggwave,dataBuffer, dataSize, GGWAVE_TX_PROTOCOL_AUDIBLE_FAST, 10, out, 0);

    // if (2*ret != n) {
    //   return -1;
    // }

    return ret;
}

int convertDataToAudio2(const char * dataBuffer, int dataSize, char ** out ){

    const int n = ggwave_encode(g_ggwave, dataBuffer, dataSize, GGWAVE_TX_PROTOCOL_AUDIBLE_FAST, 10, NULL, 1);

    char * waveform = malloc(sizeof(char) * n);

    const int ret = ggwave_encode(g_ggwave,dataBuffer,dataSize, GGWAVE_TX_PROTOCOL_AUDIBLE_FAST, 10, waveform, 0);

    if (2*ret != n) {
      free(waveform);
      return -1;
    }

    * out = waveform;

    return n;
}

char * sendMessage(const char * dataBuffer, int dataSize){
    //convertToAudio

    const int n = ggwave_encode(g_ggwave, dataBuffer, dataSize, GGWAVE_TX_PROTOCOL_AUDIBLE_FAST, 10, NULL, 1);

    char * waveform = malloc(sizeof(char) * n);

    const int ret = ggwave_encode(g_ggwave,dataBuffer,dataSize, GGWAVE_TX_PROTOCOL_AUDIBLE_FAST, 10, waveform, 0);

    if (2*ret != n) {
      free(waveform);
      return NULL;
    }

    return waveform;
}



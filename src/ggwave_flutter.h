#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ggwave/include/ggwave/ggwave.h"

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT intptr_t sum(intptr_t a, intptr_t b);

// A longer lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT intptr_t sum_long_running(intptr_t a, intptr_t b);

FFI_PLUGIN_EXPORT void initNative();

FFI_PLUGIN_EXPORT char *sendMessage(const char *dataBuffer, int dataSize);

FFI_PLUGIN_EXPORT int convertDataToAudio(const char *dataBuffer, int dataSize, char *out);

FFI_PLUGIN_EXPORT int convertDataToAudio2(const char *dataBuffer, int dataSize, char **out);

FFI_PLUGIN_EXPORT int getRequiredBufferSize(const char *dataBuffer, int dataSize);

FFI_PLUGIN_EXPORT int test(char *out);

FFI_PLUGIN_EXPORT void bar(int **x);
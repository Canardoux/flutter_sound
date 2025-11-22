#ifndef FLUTTER_PLUGIN_TAUDIO_PLUGIN_H_
#define FLUTTER_PLUGIN_TAUDIO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace taudio {

class TaudioPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  TaudioPlugin();

  virtual ~TaudioPlugin();

  // Disallow copy and assign.
  TaudioPlugin(const TaudioPlugin&) = delete;
  TaudioPlugin& operator=(const TaudioPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace taudio

#endif  // FLUTTER_PLUGIN_TAUDIO_PLUGIN_H_

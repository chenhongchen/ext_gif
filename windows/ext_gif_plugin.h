#ifndef FLUTTER_PLUGIN_EXT_GIF_PLUGIN_H_
#define FLUTTER_PLUGIN_EXT_GIF_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace ext_gif {

class ExtGifPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ExtGifPlugin();

  virtual ~ExtGifPlugin();

  // Disallow copy and assign.
  ExtGifPlugin(const ExtGifPlugin&) = delete;
  ExtGifPlugin& operator=(const ExtGifPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace ext_gif

#endif  // FLUTTER_PLUGIN_EXT_GIF_PLUGIN_H_

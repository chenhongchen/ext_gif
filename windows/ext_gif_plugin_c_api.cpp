#include "include/ext_gif/ext_gif_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ext_gif_plugin.h"

void ExtGifPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ext_gif::ExtGifPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

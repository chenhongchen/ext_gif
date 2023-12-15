//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <ext_gif/ext_gif_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) ext_gif_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ExtGifPlugin");
  ext_gif_plugin_register_with_registrar(ext_gif_registrar);
}

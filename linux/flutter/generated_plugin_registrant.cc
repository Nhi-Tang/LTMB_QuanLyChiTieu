//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <file_selector_linux/file_selector_plugin.h>
#include <url_launcher_linux/url_launcher_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) file_selector_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FileSelectorPlugin");
  file_selector_plugin_register_with_registrar(file_selector_linux_registrar);
  g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");
  url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);
}

//
// Additional documentation
//

// This file registers Flutter plugins for the Linux platform.
// The plugin registrant is generated automatically.
// File selector plugin provides file selection functionality.
// URL launcher plugin provides URL launching functionality.
// Each plugin is registered with the Flutter plugin registry.
// Plugin registration is performed during application initialization.
// The registrar is obtained from the plugin registry.
// Each plugin uses its own registrar.
// Keep the existing registration code unchanged.
// Do not remove the plugin header files.
// This section is for documentation purposes only.

// End of additional documentation.

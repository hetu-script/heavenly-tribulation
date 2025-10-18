//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audioplayers_windows/audioplayers_windows_plugin.h>
#include <display_metrics_windows/display_metrics_windows_plugin_c_api.h>
#include <flutter_custom_cursor/flutter_custom_cursor_plugin.h>
#include <flutter_platform_alert/flutter_platform_alert_plugin.h>
#include <screen_retriever_windows/screen_retriever_windows_plugin_c_api.h>
#include <video_player_win/video_player_win_plugin_c_api.h>
#include <window_manager/window_manager_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AudioplayersWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AudioplayersWindowsPlugin"));
  DisplayMetricsWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DisplayMetricsWindowsPluginCApi"));
  FlutterCustomCursorPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterCustomCursorPlugin"));
  FlutterPlatformAlertPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterPlatformAlertPlugin"));
  ScreenRetrieverWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ScreenRetrieverWindowsPluginCApi"));
  VideoPlayerWinPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("VideoPlayerWinPluginCApi"));
  WindowManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowManagerPlugin"));
}

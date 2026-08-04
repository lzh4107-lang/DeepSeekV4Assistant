#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {
void ConfigureDataDirectories() {
  if (::GetDriveTypeW(L"D:\\") != DRIVE_FIXED) return;

  const wchar_t* root = L"D:\\DeepSeekV4AssistantData";
  const wchar_t* roaming = L"D:\\DeepSeekV4AssistantData\\Roaming";
  const wchar_t* local = L"D:\\DeepSeekV4AssistantData\\Local";
  const wchar_t* temp = L"D:\\DeepSeekV4AssistantData\\Temp";
  ::CreateDirectoryW(root, nullptr);
  ::CreateDirectoryW(roaming, nullptr);
  ::CreateDirectoryW(local, nullptr);
  ::CreateDirectoryW(temp, nullptr);
  ::SetEnvironmentVariableW(L"APPDATA", roaming);
  ::SetEnvironmentVariableW(L"LOCALAPPDATA", local);
  ::SetEnvironmentVariableW(L"TEMP", temp);
  ::SetEnvironmentVariableW(L"TMP", temp);
}
}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  ConfigureDataDirectories();
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Enforce a single running instance on Windows using a named mutex.
  HANDLE instance_mutex =
      ::CreateMutexW(nullptr, TRUE, L"DeepSeekV4AssistantMutex");
  if (instance_mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    // Another instance is already running; try to bring its window to front
    // instead of creating a new one.
    Win32Window::SendAppLinkToInstance(L"deepseek_v4_assistant");
    return 0;
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  // https://github.com/flutter/flutter/issues/175135
  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnSeparateThread);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"DeepSeek V4 Assistant", origin, size)) {
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

#include <algorithm>
#include <cctype>
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Wait until the existing window's Dart link listener reports readiness.
// Returns true when ready, false on timeout.
bool WaitForLinkReady(HWND window) {
  for (int attempt = 0; attempt < 100; ++attempt) {
    if (::GetPropW(window, L"YakiHonneLinkReady")) {
      return true;
    }
    ::Sleep(50);
  }
  return ::GetPropW(window, L"YakiHonneLinkReady") != nullptr;
}

enum class ForwardResult { kForwarded, kTimedOut, kSendFailed };

// Hand a Nostr URL to a running window. The link is never logged.
ForwardResult ForwardLink(HWND window, const std::string& link) {
  if (!WaitForLinkReady(window)) {
    return ForwardResult::kTimedOut;
  }
  if (!::IsWindow(window)) {
    return ForwardResult::kSendFailed;
  }
  // app_links 6.3.2 listens for this WM_COPYDATA message. Include the
  // terminating byte and use the actual UTF-8 byte count.
  COPYDATASTRUCT data{};
  data.dwData = WM_USER + 2;
  data.cbData = static_cast<DWORD>(link.size() + 1);
  data.lpData = const_cast<char*>(link.c_str());
  DWORD_PTR result = 0;
  if (!::SendMessageTimeoutW(window, WM_COPYDATA, 0,
                             reinterpret_cast<LPARAM>(&data),
                             SMTO_ABORTIFHUNG, 2000, &result) ||
      !result) {
    return ForwardResult::kSendFailed;
  }
  if (::IsIconic(window)) {
    ::ShowWindow(window, SW_RESTORE);
  }
  ::SetForegroundWindow(window);
  return ForwardResult::kForwarded;
}

// User-facing retry when the first attempt could not reach a ready window.
// Retry re-locates the window because the first one may have exited meanwhile.
bool OfferRetry(const std::string& link) {
  while (true) {
    int choice = ::MessageBoxW(
        nullptr,
        L"YakiHonne could not deliver this Nostr link to the running window "
        L"(it may still be starting).\n\nRetry delivery?",
        L"YakiHonne", MB_RETRYCANCEL | MB_ICONWARNING | MB_DEFBUTTON1);
    if (choice != IDRETRY) {
      return false;
    }
    HWND existing = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"YakiHonne");
    if (existing == nullptr) {
      // The previous window closed; let this launch become the new instance,
      // which receives the link through its own startup arguments.
      return true;
    }
    if (ForwardLink(existing, link) == ForwardResult::kForwarded) {
      ::MessageBoxW(nullptr, L"The Nostr link was delivered to YakiHonne.",
                    L"YakiHonne", MB_OK | MB_ICONINFORMATION);
      return false;
    }
  }
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Forward a Nostr URL to an existing window. A normal launch still opens a
  // new window, matching the existing runner behavior.
  const auto arguments = GetCommandLineArguments();
  std::string scheme = arguments.size() == 1 ? arguments[0].substr(0, 6) : "";
  std::transform(scheme.begin(), scheme.end(), scheme.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  if (scheme == "nostr:") {
    HWND existing = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"YakiHonne");
    if (existing != nullptr) {
      // Do not forward until Dart has subscribed, or open a second profile
      // against the same account storage while the first window is starting.
      const auto result = ForwardLink(existing, arguments[0]);
      if (result == ForwardResult::kForwarded) {
        return EXIT_SUCCESS;
      }
      // A timeout or failed send is recoverable: offer a retry instead of
      // silently exiting with no feedback.
      if (!OfferRetry(arguments[0])) {
        return EXIT_FAILURE;
      }
      // The original window is gone, so continue as a normal launch below and
      // let app_links pick up this process's startup argument.
    }
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"YakiHonne", origin, size)) {
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

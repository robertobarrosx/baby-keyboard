param(
  [switch]$CheckOnly
)

Add-Type -AssemblyName System.Windows.Forms

$source = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class KeyboardKioskLock {
  private const int WH_KEYBOARD_LL = 13;
  private const int WM_KEYDOWN = 0x0100;
  private const int WM_KEYUP = 0x0101;
  private const int WM_SYSKEYDOWN = 0x0104;
  private const int WM_SYSKEYUP = 0x0105;
  private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
  private const uint MOUSEEVENTF_LEFTUP = 0x0004;
  private const int SM_CXSCREEN = 0;
  private const int SM_CYSCREEN = 1;
  private const int WM_LBUTTONDOWN = 0x0201;
  private const int WM_LBUTTONUP = 0x0202;
  private const int MK_LBUTTON = 0x0001;

  private static IntPtr hookId = IntPtr.Zero;
  private static IntPtr targetWindow = IntPtr.Zero;
  private static LowLevelKeyboardProc proc = HookCallback;

  public static event Action EscapePressed;

  public static void Start() {
    hookId = SetHook(proc);
    Application.Run();
    UnhookWindowsHookEx(hookId);
  }

  public static void Stop() {
    Application.ExitThread();
  }

  public static void FocusWindow(IntPtr window) {
    if (window != IntPtr.Zero) SetForegroundWindow(window);
  }

  public static void SetTargetWindow(IntPtr window) {
    targetWindow = window;
    FocusWindow(targetWindow);
  }

  public static void PulseGame() {
    IntPtr window = targetWindow;
    if (window != IntPtr.Zero) {
      SetForegroundWindow(window);

      RECT rect;
      if (GetClientRect(window, out rect)) {
        int clientX = Math.Max(1, (rect.Right - rect.Left) / 2);
        int clientY = Math.Max(1, (rect.Bottom - rect.Top) / 2);
        IntPtr lParam = (IntPtr)((clientY << 16) | (clientX & 0xFFFF));
        PostMessage(window, WM_LBUTTONDOWN, (IntPtr)MK_LBUTTON, lParam);
        PostMessage(window, WM_LBUTTONUP, IntPtr.Zero, lParam);
        return;
      }
    }

    int x = Math.Max(1, GetSystemMetrics(SM_CXSCREEN) / 2);
    int y = Math.Max(1, GetSystemMetrics(SM_CYSCREEN) / 2);
    SetCursorPos(x, y);
    mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, UIntPtr.Zero);
    mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, UIntPtr.Zero);
  }

  private static IntPtr SetHook(LowLevelKeyboardProc proc) {
    using (Process curProcess = Process.GetCurrentProcess())
    using (ProcessModule curModule = curProcess.MainModule) {
      return SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(curModule.ModuleName), 0);
    }
  }

  private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

  private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
    if (nCode >= 0) {
      int msg = wParam.ToInt32();
      bool down = msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN;
      bool up = msg == WM_KEYUP || msg == WM_SYSKEYUP;

      int vkCode = Marshal.ReadInt32(lParam);
      Keys key = (Keys)vkCode;

      bool alt = (Control.ModifierKeys & Keys.Alt) == Keys.Alt;
      bool ctrl = (Control.ModifierKeys & Keys.Control) == Keys.Control;
      bool shift = (Control.ModifierKeys & Keys.Shift) == Keys.Shift;

      if (down && key == Keys.Escape) {
        if (EscapePressed != null) EscapePressed();
        return (IntPtr)1;
      }

      if (down || up) {
        if (ShouldBlock(key, alt, ctrl, shift)) {
          if (down) PulseGame();
          return (IntPtr)1;
        }
      }
    }

    return CallNextHookEx(hookId, nCode, wParam, lParam);
  }

  private static bool ShouldBlock(Keys key, bool alt, bool ctrl, bool shift) {
    if (key == Keys.LWin || key == Keys.RWin) return true;
    if (key == Keys.Menu || key == Keys.LMenu || key == Keys.RMenu) return true;
    if (key == Keys.Apps) return true;

    if (alt) return true;
    if (ctrl) return true;

    if (key >= Keys.F1 && key <= Keys.F24) return true;

    switch (key) {
      case Keys.Tab:
      case Keys.PrintScreen:
      case Keys.Print:
      case Keys.Scroll:
      case Keys.Pause:
      case Keys.Insert:
      case Keys.Delete:
      case Keys.Home:
      case Keys.End:
      case Keys.PageUp:
      case Keys.PageDown:
      case Keys.BrowserBack:
      case Keys.BrowserForward:
      case Keys.BrowserRefresh:
      case Keys.BrowserStop:
      case Keys.BrowserSearch:
      case Keys.BrowserFavorites:
      case Keys.BrowserHome:
      case Keys.VolumeMute:
      case Keys.VolumeDown:
      case Keys.VolumeUp:
      case Keys.MediaNextTrack:
      case Keys.MediaPreviousTrack:
      case Keys.MediaStop:
      case Keys.MediaPlayPause:
      case Keys.LaunchMail:
      case Keys.SelectMedia:
      case Keys.LaunchApplication1:
      case Keys.LaunchApplication2:
        return true;
    }

    return false;
  }

  [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
  private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

  [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
  [return: MarshalAs(UnmanagedType.Bool)]
  private static extern bool UnhookWindowsHookEx(IntPtr hhk);

  [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
  private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

  [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
  private static extern IntPtr GetModuleHandle(string lpModuleName);

  [DllImport("user32.dll")]
  private static extern bool SetForegroundWindow(IntPtr hWnd);

  [DllImport("user32.dll")]
  private static extern bool SetCursorPos(int X, int Y);

  [DllImport("user32.dll")]
  private static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);

  [DllImport("user32.dll")]
  private static extern int GetSystemMetrics(int nIndex);

  [DllImport("user32.dll")]
  private static extern bool PostMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);

  [DllImport("user32.dll")]
  private static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);

  private struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
  }
}
"@

Add-Type -TypeDefinition $source -ReferencedAssemblies System.Windows.Forms -ErrorAction Stop

if ($CheckOnly) {
  "Kiosk lock OK"
  exit 0
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$file = Join-Path $root "index.html"
$url = "file:///" + ($file -replace "\\", "/")

$edge = Get-Command msedge -ErrorAction SilentlyContinue
$chrome = Get-Command chrome -ErrorAction SilentlyContinue

if ($edge) {
  $browser = Start-Process -FilePath $edge.Source -ArgumentList @("--kiosk", $url, "--edge-kiosk-type=fullscreen", "--no-first-run") -PassThru
  $processName = "msedge"
} elseif ($chrome) {
  $browser = Start-Process -FilePath $chrome.Source -ArgumentList @("--kiosk", $url, "--no-first-run", "--disable-pinch", "--overscroll-history-navigation=0") -PassThru
  $processName = "chrome"
} else {
  $browser = Start-Process -FilePath $file -PassThru
  $processName = $browser.ProcessName
}

Start-Sleep -Milliseconds 900
try {
  for ($i = 0; $i -lt 20; $i++) {
    $browser.Refresh()
    if ($browser.MainWindowHandle -ne 0) { break }

    $candidate = Get-Process -Name $processName -ErrorAction SilentlyContinue |
      Where-Object { $_.MainWindowHandle -ne 0 } |
      Select-Object -First 1

    if ($candidate) {
      $browser = $candidate
      break
    }

    Start-Sleep -Milliseconds 150
  }

  [KeyboardKioskLock]::SetTargetWindow($browser.MainWindowHandle)
  [KeyboardKioskLock]::PulseGame()
} catch {}

[KeyboardKioskLock]::add_EscapePressed({
  try {
    if ($browser -and -not $browser.HasExited) {
      Stop-Process -Id $browser.Id -Force
    }
  } catch {}

  [KeyboardKioskLock]::Stop()
})

try {
  [KeyboardKioskLock]::Start()
} finally {
  try {
    if ($browser -and -not $browser.HasExited) {
      Stop-Process -Id $browser.Id -Force
    }
  } catch {}
}

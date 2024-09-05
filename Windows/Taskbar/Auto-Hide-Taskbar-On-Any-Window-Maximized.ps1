<#
  .SYNOPSIS
  Auto Hide Taskbar On Any Window Maximized v1.0.1

  .DESCRIPTION
  This script will automatically turn on/off the taskbar auto hide setting, when a maximized
  window is detected.
  
  When a maximized window if found, auto hide is turned on.

  When no maximized windows are found, auto hide is turned off.

  .PARAMETER Help
  Brings up this help page, but won't run script.

  .INPUTS
  None.

  .OUTPUTS
  None.

  .EXAMPLE
  .\Auto-Hide-Taskbar-On-Any-Window-Maximized.ps1

  .EXAMPLE
  .\Auto-Hide-Taskbar-On-Any-Window-Maximized.ps1 -Help

  .EXAMPLE
  .\Auto-Hide-Taskbar-On-Any-Window-Maximized.ps1 -h

  .LINK
  Script from: https://github.com/Andrew-J-Larson/OS-Scripts/blob/main/Windows/Taskbar/Auto-Hide-Taskbar-On-Any-Window-Maximized.ps1
#>

<# Copyright (C) 2024  Andrew Larson (github@andrew-larson.dev)

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>. #>

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("WindowsFormsIntegration") 
   
# Create object for the systray 
$Systray_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
   
# Text displayed when you pass the mouse over the systray icon
$Systray_Tool_Icon.Text = "Auto Hide Taskbar"
   
# Create object for the systray 
$contextmenu = New-Object System.Windows.Forms.ContextMenuStrip
$Systray_Tool_Icon.ContextMenuStrip = $contextmenu
   
#Systray icon
$IconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAeCAYAAAA7MK6iAAABqUlEQVRIS+1WPU/DMBBtqEB8SDDBAKLAwMTChPgnCLGwsPQHscBYdeg/YerGwAACISFlAzHwJcpzFBvncne2I0GWZmiV890937vnc7JOS0/WEm5nCvxvzP8Z1ZPztYmpIuvne/i7phUlA9uEtUT93OXyfQDMYsQAbyLRQ5MeSKAFE0rCVQDmTGVd2L6JvQvfL9+mgYrAlM5QEpOI0DtjTNbOxdcqjujPPnzGElM+iJarAhwClYRlN8FVJuWsKRHBl0h0RiuKAHX0MmwMEX9cHq8Cs/gJVUp9tKMktYBiGOAlGF/93aRUy/VUEqM3VBYz70U8WsrQqKhX67Vdc3gxNJ8czN8PTpd70jn1c4zG7y9HF88rHOUVLL9/oGgd70/BIGE8au3C2gaAH60Pp+ros821IKK/v6ouK9xBottyR3P4/9QUnwA6C9+PMq+7qWh1u3C64aiWJlLC8DiE75XzZ0DcDgMqNYo2D70wCiMR7QJMbxVxpgiJ8/VtCfTXr0XpeIVGJt1U6EYTFcwEbgP8TqsaMVtYj/poiPkCCTHcaH0K3Ii2JkGtUf0Dn1PufARNmbgAAAAASUVORK5CYII='
$IconBytes = [Convert]::FromBase64String($IconBase64)
$Stream = [System.IO.MemoryStream]::new($IconBytes, 0, $IconBytes.Length)
$Systray_Tool_Icon.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($Stream).GetHIcon()))
$Systray_Tool_Icon.Visible = $true
   
$Menu_Exit = $contextmenu.Items.Add("Exit")
$IconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAApklEQVRIS2NkQAPGxsb/0cVI4Z89e5YRWT0Kh1LDYQYjW4LVAnRXEOsDmANHLcAZYlQPIpCB6PGFLkZRJMNc/PHjR447d+78xOY1qlgANfg30Dds6JYQZQEp+YOojIasiBTDycpo5FgAsgjmSIJBNCgtILmoIMUXJEcyvoIOzWLykykuS+iS0WhaVOCqDUmO5NEKBx4CpKR3fMGGMw5Amii1BD1VAQBT08IZ4lLZJwAAAABJRU5ErkJggg=='
$IconBytes = [Convert]::FromBase64String($IconBase64)
$Stream = [System.IO.MemoryStream]::new($IconBytes, 0, $IconBytes.Length)
$Menu_Exit_Picture = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($Stream).GetHIcon()))
$Menu_Exit.Image = $Menu_Exit_Picture
   
Start-Job -ScriptBlock {
  # CONSTANTS
  $LOOP_SECONDS = 1
   
  # IMPORTS
  Add-Type -TypeDefinition @"
     /// code below includes modifications from:
     /// - https://stackoverflow.com/q/44389752/7312536
     /// - https://github.com/gfody/ToggleTaskbar/blob/8ddf69ec2a8f3eb53208322073f51f5ca89a00f1/Program.cs
   
     using System;
     using System.Collections.Generic;
     using System.Runtime.InteropServices;
   
     public class Taskbar
     {
       [StructLayout(LayoutKind.Sequential)]
       private struct RECT
       {
         public int left;
         public int top;
         public int right;
         public int bottom;
       }
   
       [StructLayout(LayoutKind.Sequential)]
       private struct APPBARDATA
       {
         public int cbSize;
         public IntPtr hWnd;
         public uint uCallbackMessage;
         public uint uEdge;
         public RECT rc;
         public int lParam;
       }
   
       [DllImport("shell32.dll")]
       private static extern int SHAppBarMessage(int msg, ref APPBARDATA data);
       [DllImport("user32.dll")]
       private static extern IntPtr GetForegroundWindow();
       [DllImport("user32.dll")]
       private static extern IntPtr SetForegroundWindow(IntPtr hWnd);
   
       private const int ABS_AUTOHIDE = 1;
       private const int ABS_ALWAYSONTOP = 2;
       private const int ABM_GETSTATE = 4;
       private const int ABM_SETSTATE = 10;
   
       public static bool GetTaskbarAutoHide()
       {
         var data = new APPBARDATA { cbSize = Marshal.SizeOf(typeof(APPBARDATA)) };
         return SHAppBarMessage(ABM_GETSTATE, ref data) == ABS_AUTOHIDE ? true : false;
       }
   
       public static void SetTaskbarAutoHide(bool enableAutoHide)
       {
         var data = new APPBARDATA { cbSize = Marshal.SizeOf(typeof(APPBARDATA)) };
         if (enableAutoHide)
         {
           data.lParam = ABS_AUTOHIDE;
           SHAppBarMessage(ABM_SETSTATE, ref data);
         }
         else
         {
           var foregroundWindow = GetForegroundWindow();
           data.lParam = ABS_ALWAYSONTOP;
           SHAppBarMessage(ABM_SETSTATE, ref data);
           SetForegroundWindow(foregroundWindow);
         }
       }
     }
   
     /// code below includes modifications from:
     /// - https://stackoverflow.com/a/11065126/7312536
     /// - https://pinvoke.net/default.aspx/user32.EnumDesktopWindows
   
     public class Window
     {
       private delegate bool EnumDesktopWindowsDelegate(IntPtr hWnd, int lParam);
   
       [DllImport("user32.dll")]
       private static extern bool EnumDesktopWindows(IntPtr hDesktop,
      EnumDesktopWindowsDelegate lpfn, IntPtr lParam);
       [DllImport("user32.dll")]
       [return: MarshalAs(UnmanagedType.Bool)]
       private static extern bool IsWindowVisible(IntPtr hWnd);
       [DllImport("user32.dll", SetLastError=true)]
       private static extern int GetWindowLong(IntPtr hWnd, int nIndex);
   
       private const int GWL_STYLE = -16;
       private const long WS_MAXIMIZE = 0x01000000L;
   
       private static bool IsWindowMaximized(IntPtr hWnd)
       {
         int windowStyle = GetWindowLong(hWnd, GWL_STYLE);
         return (windowStyle & WS_MAXIMIZE) == WS_MAXIMIZE;
       }
   
       public static bool AnyWindowsMaximized()
       {
         var allHwnd = new List<IntPtr>();
         EnumDesktopWindowsDelegate filter = delegate(IntPtr hWnd, int lParam)
         {
           if (Window.IsWindowMaximized(hWnd))
           {
             allHwnd.Add(hWnd);
           }
           return true;
         };
   
         if (EnumDesktopWindows(IntPtr.Zero, filter, IntPtr.Zero))
         {
           return allHwnd.Count > 0;
         }
         return false;
       }
     }
"@
   
  # constantly check for maximized windows
  while ($True) {
    # logic to turn taskbar auto hide on/off based on conditions of previous variables
    if ([Window]::AnyWindowsMaximized() -And (-Not [Taskbar]::GetTaskbarAutoHide())) {
      [Taskbar]::SetTaskbarAutoHide($True)
    }
    elseif ((-Not [Window]::AnyWindowsMaximized()) -And [Taskbar]::GetTaskbarAutoHide()) {
      [Taskbar]::SetTaskbarAutoHide($false)
    }
    Start-Sleep -Seconds $LOOP_SECONDS
  }
}
   
# Make PowerShell Disappear
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)
$Menu_Exit.add_Click({
    $Systray_Tool_Icon.Visible = $false
    $window.Close()
    # $window_Config.Close() 
    Stop-Process $pid -ErrorAction 'SilentlyContinue'
  })
   
# Force garbage collection just to start slightly lower RAM usage.
[void][System.GC]::Collect()
    
# Create an application context for it to all run within.
# This helps with responsiveness, especially when clicking Exit.
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)
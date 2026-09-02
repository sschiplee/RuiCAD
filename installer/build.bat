@echo off
rem ============================================================
rem  RuiCAD 安装器一键编译脚本 (Windows 自带 .NET Framework csc, 无需安装)
rem  双击或在本目录执行: build.bat
rem  产物: dist\RuiCAD-Setup.exe
rem ============================================================
cd /d "%~dp0"

rem ---- 1. 自动同步最新源码到嵌入资源目录 res ----
if not exist res\core     mkdir res\core
if not exist res\commands mkdir res\commands
copy /y "..\core\*.lsp"     "res\core\"     >nul
copy /y "..\commands\*.lsp" "res\commands\" >nul
copy /y "..\init.lsp" "..\install.lsp" "..\LICENSE" "res\" >nul

rem ---- 2. 编译 (嵌入全部插件文件为资源) ----
if not exist dist mkdir dist
set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
"%CSC%" /nologo /target:winexe /platform:anycpu /optimize+ ^
 /reference:System.Windows.Forms.dll /reference:System.Drawing.dll ^
 /out:dist\RuiCAD-Setup.exe Setup.cs ^
 /resource:res\init.lsp,rc.init.lsp ^
 /resource:res\install.lsp,rc.install.lsp ^
 /resource:res\LICENSE,rc.LICENSE ^
 /resource:res\core\settings.lsp,rc.core.settings.lsp ^
 /resource:res\core\utils.lsp,rc.core.utils.lsp ^
 /resource:res\commands\draw.lsp,rc.commands.draw.lsp ^
 /resource:res\commands\parts.lsp,rc.commands.parts.lsp ^
 /resource:res\commands\view.lsp,rc.commands.view.lsp ^
 /resource:res\commands\dim.lsp,rc.commands.dim.lsp ^
 /resource:res\commands\hardware.lsp,rc.commands.hardware.lsp ^
 /resource:res\commands\edit.lsp,rc.commands.edit.lsp ^
 /resource:res\commands\panel.lsp,rc.commands.panel.lsp

echo.
if exist dist\RuiCAD-Setup.exe (echo 编译成功: dist\RuiCAD-Setup.exe) else (echo 编译失败, 请查看上方报错)
pause

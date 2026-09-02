@echo off
rem ============================================================
rem  RuiCAD 无头自测一键脚本（需要本机装有 AutoCAD）
rem  自动定位项目根、查找 accoreconsole.exe 并运行 run_tests.scr
rem ============================================================
setlocal
set "RC_ROOT=%~dp0.."
pushd "%RC_ROOT%"
set "RC_ROOT=%CD%"
popd

set ACC=
where accoreconsole.exe >nul 2>nul && set ACC=accoreconsole.exe
if not defined ACC for /d %%V in ("C:\Program Files\Autodesk\AutoCAD *") do (
  if exist "%%V\accoreconsole.exe" set ACC=%%V\accoreconsole.exe
)
if not defined ACC (
  echo [错误] 未找到 accoreconsole.exe，请确认已安装 AutoCAD。
  pause & exit /b 1
)
echo 项目根: %RC_ROOT%
echo 使用: %ACC%
"%ACC%" /s "%~dp0run_tests.scr"
pause

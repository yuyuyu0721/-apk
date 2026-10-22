@echo off
REM ============================================================
REM  在当前 cmd 窗口激活 Flutter / JDK / Android SDK
REM  用法：  env.bat        然后照常使用 flutter 命令
REM  环境变量已写入「用户级」，新开的终端其实不需要这个脚本；
REM  只有当前这个已打开的窗口才需要手动激活。
REM ============================================================

set "FLUTTER_ROOT=D:\tools\flutter"
set "JAVA_HOME=D:\tools\jdk-17"
set "ANDROID_HOME=D:\tools\android-sdk"
set "ANDROID_SDK_ROOT=%ANDROID_HOME%"

REM 国内镜像：拉 pub 依赖与 Flutter 产物更快
set "PUB_HOSTED_URL=https://pub.flutter-io.cn"
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"

set "PATH=%FLUTTER_ROOT%\bin;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin;%PATH%"

echo [env] Flutter / JDK 17 / Android SDK 已就绪
echo         FLUTTER_ROOT = %FLUTTER_ROOT%
echo         JAVA_HOME    = %JAVA_HOME%
echo         ANDROID_HOME = %ANDROID_HOME%
echo.

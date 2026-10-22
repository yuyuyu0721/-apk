@echo off
chcp 65001 >nul
REM ============================================================
REM  一键把「智慧客房」跑到安卓真机上
REM  后端已内置进 App，不需要另起 Node 服务
REM  前置：手机开启 USB 调试 + 已插数据线
REM ============================================================

call "%~dp0env.bat" >nul 2>&1

echo [1/3] 检查手机是否已连接...
adb devices
echo.
echo        上面没有设备的话，请先在手机上：
echo          设置 - 关于手机 - 连点"版本号"7 次
echo          设置 - 开发者选项 - 打开"USB 调试"
echo          插线后手机上点"允许调试"
echo.

echo [2/3] 编译并安装（首次约 1-3 分钟）...
cd /d "%~dp0smart_hotel_flutter"
call flutter run
if errorlevel 1 goto :fail

echo.
echo [3/3] 完成。App 内置后端监听 127.0.0.1:3000，登录用 1209 / 乔安
pause
exit /b 0

:fail
echo.
echo [!] 失败。常见原因：
echo     1) 没有设备 - 看上面 adb devices
echo     2) 手机未授权 - 手机上点"允许调试"
echo     3) 手机系统限制安装 - 打开"允许安装未知来源应用"
echo.
echo 也可以只装包不调试：
echo   adb install -r smart_hotel_flutter\build\app\outputs\flutter-apk\app-debug.apk
echo   adb shell am start -n com.smart.smart_hotel/.MainActivity
pause
exit /b 1

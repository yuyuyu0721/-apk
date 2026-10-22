# 在当前 PowerShell 窗口激活 Flutter / JDK / Android SDK
# 用法：  . .\env.ps1     （注意前面的点，表示在当前会话执行）

$env:FLUTTER_ROOT = 'D:\tools\flutter'
$env:JAVA_HOME = 'D:\tools\jdk-17'
$env:ANDROID_HOME = 'D:\tools\android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME

# 国内镜像：拉 pub 依赖与 Flutter 产物更快
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'

$env:Path = "$($env:FLUTTER_ROOT)\bin;$($env:JAVA_HOME)\bin;$($env:ANDROID_HOME)\platform-tools;$($env:ANDROID_HOME)\cmdline-tools\latest\bin;$env:Path"

Write-Host '[env] Flutter / JDK 17 / Android SDK 已就绪' -ForegroundColor Green
Write-Host "        FLUTTER_ROOT = $env:FLUTTER_ROOT"
Write-Host "        JAVA_HOME    = $env:JAVA_HOME"
Write-Host "        ANDROID_HOME = $env:ANDROID_HOME"

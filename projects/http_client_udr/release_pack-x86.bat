set ARCH_DIR=C:\Program Files\7-Zip
set OUTPUT_DIR=%1build
set BUILD_DIR=%1build\http_client_udr\windows-x86\Release

del "%OUTPUT_DIR%\HttpClientUdr_Win_x86.zip"
"%ARCH_DIR%\7z.exe" a -tzip "%OUTPUT_DIR%\HttpClientUdr_Win_x86.zip" "%BUILD_DIR%\http_client_udr.dll" "%BUILD_DIR%\libcurl.dll" "%BUILD_DIR%\zlib1.dll" ^
 "%1README.md" "%1sql" 


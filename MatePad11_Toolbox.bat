@echo off
chcp 936 >nul 2>&1
title 华为MatePad 11 综合工具箱
setlocal enabledelayedexpansion
cd /d "%~dp0"

:: ========== 请修改为你的 Gitee 仓库配置文件地址（末尾带/） ==========
set "JSON_BASE_URL=https://gitee.com/fanyantao4110/matepad11-system-config/releases/download/1/"

:: 检查核心工具
if not exist "%~dp0tools\7z.exe" (echo [错误] 缺少 tools\7z.exe & pause >nul & exit /b)
if not exist "%~dp0tools\fastboot.exe" (echo [错误] 缺少 tools\fastboot.exe & pause >nul & exit /b)
if not exist "%~dp0tools\adb.exe" (echo [错误] 缺少 tools\adb.exe & pause >nul & exit /b)

:: 创建必备目录
if not exist "%~dp0screenshots" md "%~dp0screenshots"
if not exist "%~dp0system" md "%~dp0system"
if not exist "%~dp0cache" md "%~dp0cache"
if not exist "%~dp0tmp" md "%~dp0tmp"
if not exist "%~dp0out" md "%~dp0out"
if not exist "%~dp0base" md "%~dp0base"

:: ==================== 免责声明 ====================
:disclaimer
cls
echo ===============================================
echo           华为MatePad 11 综合工具箱
echo ===============================================
echo/
echo   【免责声明】
echo/
echo   本工具仅供学习与研究使用，刷机、解锁等操作
echo   存在风险，可能导致设备变砖、数据丢失或失去
echo   保修。使用本工具即表示您自愿承担所有后果，
echo   开发者不对任何损坏或损失负责。
echo/
echo   请确认您已充分了解风险并愿意继续。
echo ===============================================
echo/
set /p agree=是否同意并继续？(Y/N): 
if /i "%agree%"=="Y" goto main_menu
if /i "%agree%"=="N" exit /b
goto disclaimer

:: ==================== 主菜单 ====================
:main_menu
cls
echo ===============================================
echo           华为MatePad 11 综合工具箱
echo ===============================================
echo/
echo   如果你已经安装驱动程序并且解锁bl了，那么可以直接从第三步开始！
echo/
echo   [1] 安装驱动程序（第一步）
echo   [2] 解锁BL（第二步）
echo   [3] 刷入底层（第三步）
echo   [4] 刷入鸿蒙系统（第四步）
echo   [5] ADB命令行
echo   [6] 设备管理器
echo   [Q] 退出
echo/
set /p choice=请输入选项 [1-6/Q]: 
if "%choice%"=="1" goto install_driver
if "%choice%"=="2" goto unlock_submenu
if "%choice%"=="3" goto flash_base
if "%choice%"=="4" goto flash_menu
if "%choice%"=="5" goto adb_cmd
if "%choice%"=="6" goto device_mgr
if /i "%choice%"=="Q" exit /b
goto main_menu

:: ==================== 解锁子菜单 ====================
:unlock_submenu
cls
echo ==========================================================
echo                       解锁BL
echo ==========================================================
echo     [警告]  本工具仅限设备型号为DBY-W09使用！
echo     请在备份好数据后再使用本工具！若数据丢失，概不负责！
echo/
echo     [1] 一键解锁BL (鸿蒙2-鸿蒙3)
echo     [2] 一键解锁BL (鸿蒙4)
echo     [B] 返回主菜单
echo ==========================================================
echo/
set /p unlock_opt=请输入选项 [1-2/B]: 
if "%unlock_opt%"=="1" goto unlock_os23
if "%unlock_opt%"=="2" goto unlock_os4
if /i "%unlock_opt%"=="B" goto main_menu
echo [错误] 无效选项
ping 127.0.0.1 -n 2 >nul
goto unlock_submenu

:: ==================== 安装驱动（内置） ====================
:install_driver
cls
echo ==========================================================
echo              安装驱动程序
echo ==========================================================
echo/
echo [1] 安装 ADB 驱动
echo [2] 安装 Qualcomm 9008 驱动
echo [B] 返回主菜单
echo/
set /p drv_opt=请选择要安装的驱动: 
if "%drv_opt%"=="1" goto install_adb_driver
if "%drv_opt%"=="2" goto install_qc_driver
if /i "%drv_opt%"=="B" goto main_menu
echo [错误] 无效选项
ping 127.0.0.1 -n 2 >nul
goto install_driver

:install_adb_driver
if exist "%~dp0tools\driver\adbdriver.exe" (
    echo 正在启动 ADB 驱动安装程序...
    start /wait "" "%~dp0tools\driver\adbdriver.exe"
    echo 安装完成。
) else (
    echo [错误] 未找到 tools\driver\adbdriver.exe
)
echo 按任意键返回...
pause >nul
goto install_driver

:install_qc_driver
if exist "%~dp0tools\driver\qcdriver.exe" (
    echo 正在启动 9008 驱动安装程序...
    start /wait "" "%~dp0tools\driver\qcdriver.exe"
    echo 安装完成。
) else (
    echo [错误] 未找到 tools\driver\qcdriver.exe
)
echo 按任意键返回...
pause >nul
goto install_driver

:: ==================== 解锁BL (OS2-OS3) ====================
:unlock_os23
cls
echo ==========================================================
echo       一键解锁BL (鸿蒙2-鸿蒙3版本)
echo ==========================================================
echo/
echo [警告] 解锁BL可能会丢失数据，请先备份！
echo [前提] 平板已开启USB调试，并连接电脑
echo/
if not exist "%~dp0unlock\Huawei865870_devprg.elf" (
    echo [错误] 缺少底层文件 unlock\Huawei865870_devprg.elf
    pause
    goto unlock_submenu
)
if not exist "%~dp0unlock\Huawei865870_abl_unlock.img" (
    echo [错误] 缺少ABL解锁文件 unlock\Huawei865870_abl_unlock.img
    pause
    goto unlock_submenu
)
echo [OK] 文件检查通过
echo/
set /p confirm=是否继续？(Y/N): 
if /i not "%confirm%"=="Y" goto unlock_submenu
echo/
echo 检测设备...
call :wait_adb_device
if errorlevel 1 goto unlock_submenu
echo [OK] 设备已连接
echo/
echo 正在进入9008模式...
"%~dp0tools\adb.exe" reboot edl
echo 等待8秒...
ping 127.0.0.1 -n 9 >nul
echo/
echo 请输入9008设备的COM端口号（如 3、5 等）:
set /p COMPORT=COM端口号: 
if "%COMPORT%"=="" (
    echo [错误] 未输入端口号！
    pause
    goto unlock_submenu
)
echo/
echo 开始发送底层文件...
"%~dp0tools\QSaharaServer.exe" -p \\.\COM%COMPORT% -s 13:"%~dp0unlock\Huawei865870_devprg.elf" 1>nul 2>&1
if errorlevel 1 (
    echo [错误] 发送底层文件失败！
    pause
    goto unlock_submenu
)
echo [OK] 底层文件发送成功
echo/
echo 正在配置端口...
echo ^<?xml version="1.0" ?^>^<data^>^<configure MemoryName="ufs" Verbose="0" AlwaysValidate="0" MaxDigestTableSizeInBytes="8192" MaxPayloadSizeToTargetInBytes="1048576" ZlpAwareHost="1" SkipStorageInit="0" /^>^</data^>> "%~dp0tmp\configure.xml"
"%~dp0tools\fh_loader.exe" --port=\\.\COM%COMPORT% --memoryname=ufs --configure="%~dp0tmp\configure.xml" --search_path="%~dp0unlock" --mainoutputdir="%~dp0log" --noprompt 1>nul 2>&1
if errorlevel 1 (
    echo [错误] 配置端口失败！
    pause
    goto unlock_submenu
)
echo [OK] 端口配置成功
echo/
echo 开始刷写解锁文件...
echo ^<?xml version="1.0" ?^>^<data^>^<program filename="Huawei865870_abl_unlock.img" label="abl" physical_partition_number="4" start_sector="49670" num_partition_sectors="1024" SECTOR_SIZE_IN_BYTES="4096"/^>^</data^>> "%~dp0tmp\rawprogram0.xml"
"%~dp0tools\fh_loader.exe" --port=\\.\COM%COMPORT% --memoryname=ufs --sendxml="%~dp0tmp\rawprogram0.xml" --search_path="%~dp0unlock" --mainoutputdir="%~dp0log" --skip_configure --noprompt 1>nul 2>&1
if errorlevel 1 (
    echo [错误] 刷写失败！
    pause
    goto unlock_submenu
)
echo [OK] 刷写成功
echo/
echo 正在重启设备...
echo ^<?xml version="1.0" ?^>^<data^>^<power DelayInSeconds="0" value="reset" /^>^</data^>> "%~dp0tmp\reboot.xml"
"%~dp0tools\fh_loader.exe" --port=\\.\COM%COMPORT% --memoryname=ufs --sendxml="%~dp0tmp\reboot.xml" --search_path="%~dp0unlock" --mainoutputdir="%~dp0log" --skip_configure --noprompt 1>nul 2>&1
echo [OK] 设备正在重启...
echo/
echo ==========================================================
echo  解锁完成！如果设备没有重启，请拔掉线，然后长按电源键加下键重启
echo ==========================================================
pause
goto unlock_submenu

:: ==================== 解锁BL (OS4) ====================
:unlock_os4
cls
echo ==========================================================
echo         一键解锁BL (鸿蒙4版本)
echo ==========================================================
echo/
echo [警告] 解锁BL可能会丢失数据，请先备份！
echo [前提] 平板已进入9008模式 (探针或9008按键进入)
echo/
if not exist "%~dp0unlock\Huawei865870_devprg.elf" (
    echo [错误] 缺少底层文件 unlock\Huawei865870_devprg.elf
    pause
    goto unlock_submenu
)
if not exist "%~dp0unlock\Huawei865870_abl_unlock.img" (
    echo [错误] 缺少ABL解锁文件 unlock\Huawei865870_abl_unlock.img
    pause
    goto unlock_submenu
)
echo [OK] 文件检查通过
echo/
set /p confirm=是否继续？(Y/N): 
if /i not "%confirm%"=="Y" goto unlock_submenu
echo/
echo [检查] 检测设备是否在9008模式...
set FOUND_9008=0
:check_9008_loop
wmic path Win32_PnPEntity where "Name like '%%9008%%'" get Name 2>nul | find "COM" >nul
if not errorlevel 1 set FOUND_9008=1
if "%FOUND_9008%"=="1" goto found_9008
echo/
echo [提示] 未检测到9008设备
echo 请通过探针/短接或9008按键进入9008模式
echo 连接后在设备管理器中查看COM端口号
echo/
echo 等待9008设备连接中... (输入 Q 返回)
set /p userinput=
if /i "%userinput%"=="Q" goto unlock_submenu
goto check_9008_loop
:found_9008
echo [OK] 已检测到9008设备
echo/
echo 请输入9008设备的COM端口号（如 3、5 等）:
set /p COMPORT=COM端口号: 
if "%COMPORT%"=="" (
    echo [错误] 未输入端口号！
    pause
    goto unlock_submenu
)
echo/
echo 开始发送底层文件...
"%~dp0tools\QSaharaServer.exe" -p \\.\COM%COMPORT% -s 13:"%~dp0unlock\Huawei865870_devprg.elf" 1>nul 2>&1
if errorlevel 1 (
    echo [错误] 发送底层文件失败！
    pause
    goto unlock_submenu
)
echo [OK] 底层文件发送成功
echo/
echo 正在配置端口...
echo ^<?xml version="1.0" ?^>^<data^>^<configure MemoryName="ufs" Verbose="0" AlwaysValidate="0" MaxDigestTableSizeInBytes="8192" MaxPayloadSizeToTargetInBytes="1048576" ZlpAwareHost="1" SkipStorageInit="0" /^>^</data^>> "%~dp0tmp\configure.xml"
"%~dp0tools\fh_loader.exe" --port=\\.\COM%COMPORT% --memoryname=ufs --configure="%~dp0tmp\configure.xml" --search_path="%~dp0unlock" --mainoutputdir="%~dp0log" --noprompt 1>nul 2>&1
if errorlevel 1 (
    echo [错误] 配置端口失败！
    pause
    goto unlock_submenu
)
echo [OK] 端口配置成功
echo/
echo 开始刷写解锁文件...
echo ^<?xml version="1.0" ?^>^<data^>^<program filename="Huawei865870_abl_unlock.img" label="abl" physical_partition_number="4" start_sector="49670" num_partition_sectors="1024" SECTOR_SIZE_IN_BYTES="4096"/^>^</data^>> "%~dp0tmp\rawprogram0.xml"
"%~dp0tools\fh_loader.exe" --port=\\.\COM%COMPORT% --memoryname=ufs --sendxml="%~dp0tmp\rawprogram0.xml" --search_path="%~dp0unlock" --mainoutputdir="%~dp0log" --skip_configure --noprompt 1>nul 2>&1
if errorlevel 1 (
    echo [错误] 刷写失败！
    pause
    goto unlock_submenu
)
echo [OK] 刷写成功
echo/
echo 正在重启设备...
echo ^<?xml version="1.0" ?^>^<data^>^<power DelayInSeconds="0" value="reset" /^>^</data^>> "%~dp0tmp\reboot.xml"
"%~dp0tools\fh_loader.exe" --port=\\.\COM%COMPORT% --memoryname=ufs --sendxml="%~dp0tmp\reboot.xml" --search_path="%~dp0unlock" --mainoutputdir="%~dp0log" --skip_configure --noprompt 1>nul 2>&1
echo [OK] 设备正在重启...
echo/
echo ==========================================================
echo  解锁完成！如果设备没有重启，请拔掉线，然后长按电源键加下键重启
echo ==========================================================
pause
goto unlock_submenu

:: ==================== ADB命令行 ====================
:adb_cmd
cls
echo ==========================================================
echo                  ADB/Fastboot 命令行工具
echo ==========================================================
echo/
echo   [常用命令]
echo     adb devices    - 查看设备
echo     adb shell      - 进入终端
echo     adb reboot     - 重启设备
echo     fastboot flash - 刷入分区
echo     fastboot reboot - 重启设备
echo/
echo   提示：可以用 cls 清屏
echo ==========================================================
start cmd /k "cd /d %~dp0tools"
goto main_menu

:: ==================== 设备管理器 ====================
:device_mgr
start devmgmt.msc
goto main_menu

:: ==================== 刷入系统菜单 ====================
:flash_menu
cls
echo ===============================================
echo               刷入系统 - 选择版本
echo ===============================================
echo/
echo   [1] 鸿蒙2.0
echo   [2] 鸿蒙3.0
echo   [3] 鸿蒙4.0
echo   [4] 鸿蒙4.2
echo   [5] 刷入本地系统镜像
echo   [U] 在线更新配置文件
echo   [B] 返回主菜单
echo/
set /p ver_choice=请输入选项 [1-5/U/B]: 
if "%ver_choice%"=="1" set "selected_ver=2.0" & goto load_rom_list
if "%ver_choice%"=="2" set "selected_ver=3.0" & goto load_rom_list
if "%ver_choice%"=="3" set "selected_ver=4.0" & goto load_rom_list
if "%ver_choice%"=="4" set "selected_ver=4.2" & goto load_rom_list
if "%ver_choice%"=="5" call :manual_flash_img & goto main_menu
if /i "%ver_choice%"=="U" call :update_json_files & goto flash_menu
if /i "%ver_choice%"=="B" goto main_menu
goto flash_menu

:: ==================== 读取JSON并显示ROM列表（已删除查看截图选项） ====================
:load_rom_list
cls
set "rom_file=%~dp0system\%selected_ver%.json"
if not exist "%rom_file%" (
    echo [提示] 未找到 %selected_ver%.json，尝试从 Gitee 下载...
    call :download_json "%selected_ver%.json"
    if errorlevel 1 (
        echo [错误] 下载失败，请手动将 %selected_ver%.json 放入 %~dp0system\
        pause
        goto flash_menu
    )
)

set /a rom_total=0
for /f "usebackq delims=" %%a in ("%rom_file%") do (
    set "line=%%a"
    set "line=!line: =!"
    if not "!line!"=="" (
        if "!line:~0,1!"=="{" (
            set "obj=!line!"
            set "obj=!obj:{=!"
            set "obj=!obj:}=!"
            set "obj=!obj: =!"
            for /f "tokens=1,2 delims=," %%i in ("!obj!") do (
                set "field1=%%i"
                set "field2=%%j"
                set "name=!field1:*:=!"
                set "name=!name:"=!"
                set "url=!field2:*:=!"
                set "url=!url:"=!"
                set /a rom_total+=1
                set "rom_name_!rom_total!=!name!"
                set "rom_url_!rom_total!=!url!"
            )
        )
    )
)

if %rom_total% equ 0 (
    echo [错误] 没有找到任何系统选项，请检查JSON文件内容。
    pause
    goto flash_menu
)

echo ===============================================
echo        鸿蒙%selected_ver% - 选择系统版本
echo ===============================================
echo/
for /l %%i in (1,1,%rom_total%) do echo   [%%i] !rom_name_%%i!
echo   [B] 返回上级
echo/
set /p rom_choice=请输入选项: 
if /i "%rom_choice%"=="B" goto flash_menu
set /a rom_choice_num=%rom_choice% 2>nul
if "%rom_choice_num%" neq "%rom_choice%" goto load_rom_list
if %rom_choice_num% lss 1 goto load_rom_list
if %rom_choice_num% gtr %rom_total% goto load_rom_list

set "rom_name=!rom_name_%rom_choice_num%!"
set "rom_url=!rom_url_%rom_choice_num%!"
goto download_rom

:: ==================== 下载流程 ====================
:download_rom
cls
echo ===============================================
echo  您选择的系统：%rom_name%
echo ===============================================
echo/
echo   [警告] 刷入系统将导致设备恢复出厂设置，
echo           所有数据将被清除！
echo/
set /p confirm_flash=是否继续？(Y/N): 
if /i not "%confirm_flash%"=="Y" goto flash_menu

echo/
echo   即将打开下载链接，请自行下载。
echo   下载完成后，请将 super.img 文件放入以下目录：
echo   %~dp0system\
echo/
echo   按任意键打开下载链接...
pause >nul
start "" "%rom_url%"
echo/
echo   请等待下载完成，将 super.img 文件放入上述目录后，
echo   按任意键继续...
pause >nul
call :check_and_flash_img
goto main_menu

:: ==================== 刷系统：仅 img 模式（带容错和Fastboot等待） ====================
:check_and_flash_img
cls
echo ===============================================
echo           检测 img 刷机包并开始刷机
echo ===============================================
echo/

set "img_found=0"
for %%f in ("%~dp0system\*.img") do set "img_found=1" & goto img_mode
:img_mode
if "%img_found%"=="1" (
    echo 检测到以下 img 镜像文件，将直接刷入：
    echo/
    dir /b "%~dp0system\*.img" 2>nul
    echo/
    call :prepare_fastboot_mode
    if errorlevel 1 goto :eof

    echo 设备已就绪，开始刷入镜像...
    set "failed_parts="
    set "fail_count=0"
    for %%f in ("%~dp0system\*.img") do (
        echo 正在刷入 %%~nf 分区...
        "%~dp0tools\fastboot.exe" flash %%~nf "%%f"
        if !errorlevel! neq 0 (
            echo [警告] 刷入 %%~nf 失败，继续处理下一个...
            set "failed_parts=!failed_parts! %%~nf"
            set /a fail_count+=1
        )
    )

    if !fail_count! gtr 0 (
        echo/
        echo ===============================================
        echo   刷入完成，但以下 !fail_count! 个分区失败：
        echo   !failed_parts!
        echo ===============================================
    ) else (
        echo ===============================================
        echo   所有镜像刷入成功！
        echo ===============================================
    )

    echo 正在恢复出厂...
    "%~dp0tools\fastboot.exe" -w
    if errorlevel 1 (
        echo [警告] 恢复出厂设置可能未完全成功，请稍后在 Recovery 中手动清除数据。
    )
    echo/
    echo 正在重启至 Recovery 模式...
    "%~dp0tools\fastboot.exe" reboot recovery
    echo/
    echo ===============================================
    echo   设备正在重启至 Recovery 界面。
    echo   请手动点击“清除数据”选项以确保系统正常启动。
    echo   完成后可按任意键返回主菜单...
    pause >nul
    goto :eof
)

echo [错误] 未在 system 目录下找到任何 .img 文件！
echo 请确保已将下载的 img 文件放入：
echo %~dp0system\
pause
goto :eof

:: ==================== 手动刷入本地系统镜像（自动重启，提示 Recovery 进入方法） ====================
:manual_flash_img
cls
echo ===============================================
echo        刷入本地系统镜像
echo ===============================================
echo/

set "img_found=0"
for %%f in ("%~dp0system\*.img") do set "img_found=1" & goto manual_img_mode
:manual_img_mode
if "%img_found%"=="1" (
    echo 检测到以下 img 镜像文件，将直接刷入：
    echo/
    dir /b "%~dp0system\*.img" 2>nul
    echo/
    call :prepare_fastboot_mode
    if errorlevel 1 goto :eof

    echo 设备已就绪，开始刷入镜像...
    set "failed_parts="
    set "fail_count=0"
    for %%f in ("%~dp0system\*.img") do (
        echo 正在刷入 %%~nf 分区...
        "%~dp0tools\fastboot.exe" flash %%~nf "%%f"
        if !errorlevel! neq 0 (
            echo [警告] 刷入 %%~nf 失败，继续处理下一个...
            set "failed_parts=!failed_parts! %%~nf"
            set /a fail_count+=1
        )
    )

    if !fail_count! gtr 0 (
        echo/
        echo ===============================================
        echo   刷入完成，但以下 !fail_count! 个分区失败：
        echo   !failed_parts!
        echo ===============================================
    ) else (
        echo ===============================================
        echo   所有镜像刷入成功！
        echo ===============================================
    )

    echo/
    echo 正在重启设备...
    "%~dp0tools\fastboot.exe" reboot
    echo ===============================================
    echo   设备正在重启。
    echo   如果无法正常进入系统，请手动进入 Recovery
    echo   模式并清除数据。
    echo   进入方法：关机状态下，同时按住 音量上键 +
    echo   电源键，出现 logo 后松开电源键，继续按住
    echo   音量上键直至进入 Recovery 界面。
    echo   完成后可按任意键返回主菜单...
    pause >nul
    goto :eof
)

echo [错误] 未在 system 目录下找到任何 .img 文件！
echo 请确保已将下载的 img 文件放入：
echo %~dp0system\
pause
goto :eof

:: ==================== 刷入底层（从 base 目录 ZIP，带容错和Fastboot等待） ====================
:flash_base
cls
echo ===============================================
echo               刷入底层固件
echo ===============================================
echo/
echo 正在扫描 base 目录下的底层包...

set "base_count=0"
for %%f in ("%~dp0base\*.zip") do (
    set /a base_count+=1
    set "base_file_!base_count!=%%f"
    set "base_name_!base_count!=%%~nxf"
)

if %base_count% equ 0 (
    echo [错误] 未在 base 目录下找到任何 ZIP 底层包！
    echo 请将底层包放入 %~dp0base\
    pause
    goto main_menu
)

echo 检测到以下底层包：
echo/
for /l %%i in (1,1,%base_count%) do echo   [%%i] !base_name_%%i!
echo   [B] 返回主菜单
echo/
set /p base_choice=请选择要刷入的底层包: 
if /i "%base_choice%"=="B" goto main_menu
set /a base_idx=%base_choice% 2>nul
if "%base_idx%" neq "%base_choice%" goto flash_base
if %base_idx% lss 1 goto flash_base
if %base_idx% gtr %base_count% goto flash_base

set "selected_zip=!base_file_%base_idx%!"
echo/
echo 已选择: !base_name_%base_idx%!

echo 正在清空 cache 目录...
if exist "%~dp0cache" rd /s /q "%~dp0cache" >nul 2>&1
md "%~dp0cache" >nul 2>&1

echo 正在解压到 cache 目录...
"%~dp0tools\7z.exe" x "%selected_zip%" -o"%~dp0cache" -y >nul
if %errorlevel% neq 0 (
    echo [错误] 解压失败！
    pause
    goto main_menu
)
echo 解压完成。

echo/
call :prepare_fastboot_mode
if errorlevel 1 goto main_menu

echo 设备已就绪，开始刷入底层镜像...
set "failed_parts="
set "fail_count=0"
for %%f in ("%~dp0cache\*.img") do (
    echo 正在刷入 %%~nf 分区...
    "%~dp0tools\fastboot.exe" flash %%~nf "%%f"
    if !errorlevel! neq 0 (
        echo [警告] 刷入 %%~nf 失败，继续处理下一个...
        set "failed_parts=!failed_parts! %%~nf"
        set /a fail_count+=1
    )
)

echo 正在清空 cache 目录...
if exist "%~dp0cache" rd /s /q "%~dp0cache" >nul 2>&1
md "%~dp0cache" >nul 2>&1

if !fail_count! gtr 0 (
    echo/
    echo ===============================================
    echo   刷入完成，但以下 !fail_count! 个分区失败：
    echo   !failed_parts!
    echo ===============================================
) else (
    echo ===============================================
    echo   底层刷入全部成功！
    echo ===============================================
)

:: 询问是否继续刷入系统
echo/
echo 底层刷入已完成。是否继续刷入系统？
echo   [1] 继续刷入系统
echo   [2] 返回主菜单
echo/
set /p next_step=请选择 [1-2]: 
if "%next_step%"=="1" goto flash_menu
if "%next_step%"=="2" goto main_menu
goto main_menu

:: ==================== 准备Fastboot模式（询问设备状态并自动重启） ====================
:prepare_fastboot_mode
echo ===============================================
echo   请确认设备当前状态：
echo   [1] 设备可以正常开机（通过ADB重启至Fastboot）
echo   [2] 设备无法正常开机（请手动进入Fastboot）
echo   [B] 返回
echo ===============================================
set /p state_choice=请选择: 
if "%state_choice%"=="1" (
    echo 正在尝试通过ADB连接设备...
    call :wait_adb_device
    if errorlevel 1 (
        exit /b 1
    )
    echo 设备已连接，正在重启至Fastboot模式...
    "%~dp0tools\adb.exe" reboot bootloader
    if errorlevel 1 (
        echo [错误] 重启失败，请手动进入Fastboot模式。
        pause
    )
    echo 等待设备进入Fastboot模式（10秒）...
    ping 127.0.0.1 -n 11 >nul
)
if "%state_choice%"=="2" (
    echo 请手动将设备进入Fastboot模式（按住音量下+电源键），然后按任意键继续...
    pause >nul
)
if /i "%state_choice%"=="B" (
    exit /b 1
)
call :wait_fastboot_device
exit /b %errorlevel%

:: ==================== 等待 Fastboot 设备子过程 ====================
:wait_fastboot_device
echo 正在检测 Fastboot 设备...
:fastboot_check
"%~dp0tools\fastboot.exe" devices > "%~dp0tmp\fastboot_out.txt" 2>&1
type "%~dp0tmp\fastboot_out.txt"
findstr /i "fastboot" "%~dp0tmp\fastboot_out.txt" >nul
if not errorlevel 1 (
    del "%~dp0tmp\fastboot_out.txt" >nul 2>&1
    exit /b 0
)
echo/
echo [错误] 未检测到 Fastboot 设备，请检查连接和驱动。
echo 按任意键重试，或输入 Q 返回...
set /p retry_opt=
if /i "%retry_opt%"=="Q" (
    del "%~dp0tmp\fastboot_out.txt" >nul 2>&1
    exit /b 1
)
goto fastboot_check

:: ==================== 等待 ADB 设备子过程（可重试） ====================
:wait_adb_device
echo 正在检测 ADB 设备...
:adb_check
"%~dp0tools\adb.exe" devices > "%~dp0tmp\adb_out.txt" 2>&1
type "%~dp0tmp\adb_out.txt"
findstr /r "device$" "%~dp0tmp\adb_out.txt" >nul
if not errorlevel 1 (
    del "%~dp0tmp\adb_out.txt" >nul 2>&1
    exit /b 0
)
echo/
echo [错误] 未检测到 ADB 设备，请开启USB调试并连接。
echo 按任意键重试，或输入 Q 返回...
set /p adb_retry=
if /i "%adb_retry%"=="Q" (
    del "%~dp0tmp\adb_out.txt" >nul 2>&1
    exit /b 1
)
goto adb_check

:: ==================== 下载单个 JSON 文件 ====================
:download_json
set "file_name=%~1"
echo 正在下载 %file_name% ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$url = '%JSON_BASE_URL%%file_name%';" ^
  "$out = '%~dp0system\%file_name%';" ^
  "try { Invoke-WebRequest -Uri $url -OutFile $out -ErrorAction Stop; Write-Host '下载成功'; exit 0 } catch { Write-Host \"下载失败: $_\"; exit 1 }"
exit /b %errorlevel%

:: ==================== 在线更新所有 JSON 配置文件 ====================
:update_json_files
cls
echo ===============================================
echo           在线更新系统配置文件
echo ===============================================
echo/
echo 正在更新全部配置文件（2.0.json、3.0.json、4.0.json、4.2.json）...
echo 请稍候，这可能需要一点时间...
echo/

set "update_failed=0"
for %%v in (2.0 3.0 4.0 4.2) do (
    echo 正在下载 %%v.json ...
    call :download_json "%%v.json"
    if errorlevel 1 set "update_failed=1"
)

if "%update_failed%"=="0" (
    echo/
    echo ===============================================
    echo   全部配置文件更新成功！
    echo ===============================================
) else (
    echo/
    echo ===============================================
    echo   部分配置文件更新失败，请检查网络后重试，
    echo   或手动放置文件到 system 目录。
    echo ===============================================
)
echo 按任意键返回刷入系统菜单...
pause >nul
goto :eof
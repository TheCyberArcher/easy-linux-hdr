
#!/bin/bash

SEPERATOR="------------------------------------------------------------------------------------------------"
COMMON_OVERRIDES="d3d8 d3d9 d3d11 ddraw dinput8 dxgi opengl32"
REQUIRED_EXECUTABLES="7z curl git grep"
XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
MAIN_PATH=${MAIN_PATH:-"$XDG_DATA_HOME/reshade"}
RESHADE_PATH="$MAIN_PATH/reshade"
WINE_MAIN_PATH="$(echo "$MAIN_PATH" | sed "s#/home/$USER/##" | sed 's#/#\\\\#g')"
UPDATE_RESHADE=${UPDATE_RESHADE:-1}
MERGE_SHADERS=${MERGE_SHADERS:-1}
VULKAN_SUPPORT=${VULKAN_SUPPORT:-0}
GLOBAL_INI=${GLOBAL_INI:-"ReShade.ini"}
SHADER_REPOS=${SHADER_REPOS:-"https://github.com/CeeJayDK/SweetFX|sweetfx-shaders;https://github.com/martymcmodding/qUINT|martymc-shaders;https://github.com/BlueSkyDefender/AstrayFX|astrayfx-shaders;https://github.com/prod80/prod80-ReShade-Repository|prod80-shaders;https://github.com/crosire/reshade-shaders|reshade-shaders|slim"}
RESHADE_VERSION=${RESHADE_VERSION:-"latest"}
RESHADE_ADDON_SUPPORT=1
FORCE_RESHADE_UPDATE_CHECK=${FORCE_RESHADE_UPDATE_CHECK:-0}
RESHADE_URL="https://reshade.me"
RESHADE_URL_ALT="http://static.reshade.me"

echo ''
echo '=========== Game Linux HDR Patch ==========='
echo ''

function checkStdin() {
    while true; do
        read -rp "$1" userInput
        if [[ $userInput =~ $2 ]]; then
            break
        fi
    done
    echo "$userInput"
}

function getGamePath() {
    echo 'Supply the folder path where the main executable (exe file) for the game is.'
    echo '(Control+c to exit)'
    while true; do
        read -rp 'Game path: ' gamePath
        eval gamePath="$gamePath" &> /dev/null
        gamePath=$(realpath "$gamePath")
        [[ -f $gamePath ]] && gamePath=$(dirname "$gamePath")
        if ! ls "$gamePath" > /dev/null 2>&1 || [[ -z $gamePath ]]; then
            echo "Incorrect or empty path supplied. You supplied \"$gamePath\"."
            continue
        fi
        if ! ls "$gamePath/"*.exe > /dev/null 2>&1; then
            echo "No .exe file found in \"$gamePath\"."
            echo "Do you still want to use this directory?"
            [[ $(checkStdin "(y/n) " "^(y|n)$") != "y" ]] && continue
        fi
        echo "Is this path correct? \"$gamePath\""
        [[ $(checkStdin "(y/n) " "^(y|n)$") == "y" ]] && break
    done
}

function downloadD3dcompiler_47() {
    ! [[ $1 =~ ^(32|64)$ ]] && printErr "(downloadD3dcompiler_47): Wrong system architecture."
    [[ -f $MAIN_PATH/d3dcompiler_47.dll.$1 ]] && return
    echo "Downloading d3dcompiler_47.dll for $1 bits."
    createTempDir
    # Based on https://github.com/Winetricks/winetricks/commit/bc5c57d0d6d2c30642efaa7fee66b60f6af3e133
    curl -sLO "https://download-installer.cdn.mozilla.net/pub/firefox/releases/62.0.3/win$1/ach/Firefox%20Setup%2062.0.3.exe" \
        || echo "Could not download Firefox setup file (which contains d3dcompiler_47.dll)"
    [[ $1 -eq 32 ]] && hash="d6edb4ff0a713f417ebd19baedfe07527c6e45e84a6c73ed8c66a33377cc0aca" || hash="721977f36c008af2b637aedd3f1b529f3cfed6feb10f68ebe17469acb1934986"
    ffhash=$(sha256sum Firefox*.exe | cut -d\  -f1)
    [[ "$ffhash" != "$hash" ]] && printErr "(downloadD3dcompiler_47) Firefox integrity check failed. (Expected: $hash ; Calculated: $ffhash)"
    7z -y e Firefox*.exe 1> /dev/null || printErr "(dowloadD3dcompiler_47) Failed to extract Firefox using 7z."
    cp d3dcompiler_47.dll "$MAIN_PATH/d3dcompiler_47.dll.$1" || printErr "(downloadD3dcompiler_47): Unable to find d3dcompiler_47.dll"
    removeTempDir
}

if [[ $GLOBAL_INI != 0 ]] && [[ $GLOBAL_INI == ReShade.ini ]] && [[ ! -f $MAIN_PATH/$GLOBAL_INI ]]; then
    cd "$MAIN_PATH" || exit
    curl -sLO https://github.com/kevinlekiller/reshade-steam-proton/raw/ini/ReShade.ini
    if [[ -f ReShade.ini ]]; then
        sed -i "s/_USERSED_/$USER/g" "$MAIN_PATH/$GLOBAL_INI"
        if [[ $MERGE_SHADERS == 1 ]]; then
            sed -i "s#_SHADSED_#$WINE_MAIN_PATH\\\ReShade_shaders\\\Merged\\\Shaders#g" "$MAIN_PATH/$GLOBAL_INI"
            sed -i "s#_TEXSED_#$WINE_MAIN_PATH\\\ReShade_shaders\\\Merged\\\Textures#g" "$MAIN_PATH/$GLOBAL_INI"
        fi
    fi
fi

if [[ $VULKAN_SUPPORT == 1 ]]; then
    echo "Does the game use the Vulkan API?"
    if [[ $(checkStdin "(y/n): " "^(y|n)$") == "y" ]]; then
        echo 'Supply the WINEPREFIX path for the game.'
        echo '(Control+c to exit)'
        while true; do
            read -rp 'WINEPREFIX path: ' WINEPREFIX
            eval WINEPREFIX="$WINEPREFIX"
            WINEPREFIX=$(realpath "$WINEPREFIX")
            if ! ls "$WINEPREFIX" > /dev/null 2>&1 || [[ -z $WINEPREFIX ]]; then
                echo "Incorrect or empty path supplied. You supplied \"$WINEPREFIX\"."
                continue
            fi
            echo "Is this path correct? \"$WINEPREFIX\""
            [[ $(checkStdin "(y/n) " "^(y|n)$") == "y" ]] && break
        done
        echo "Specify if the game's EXE file architecture is 32 or 64 bits:"
        [[ $(checkStdin "(32/64) " "^(32|64)$") == 64 ]] && exeArch=64 || exeArch=32
        export WINEPREFIX="$WINEPREFIX"
        echo "Do you want to (i)nstall or (u)ninstall HDR mod ?"
        if [[ $(checkStdin "(i/u): " "^(i|u)$") == "i" ]]; then
            wine reg ADD HKLM\\SOFTWARE\\Khronos\\Vulkan\\ImplicitLayers /d 0 /t REG_DWORD /v "Z:\\home\\$USER\\$WINE_MAIN_PATH\\reshade\\$RESHADE_VERSION\\ReShade$exeArch.json" -f /reg:"$exeArch"
        else
            wine reg DELETE HKLM\\SOFTWARE\\Khronos\\Vulkan\\ImplicitLayers -f /reg:"$exeArch"
        fi
        [[ $? == 0 ]] && echo "Done." || echo "An error has occured."
        exit 0
    fi
fi

echo "Do you want to (i)nstall or (u)ninstall HDR features for a DirectX or OpenGL game?"
if [[ $(checkStdin "(i/u): " "^(i|u)$") == "u" ]]; then
    getGamePath
    echo "Unlinking ReShade files."
    LINKS="$(echo "$COMMON_OVERRIDES" | sed 's/ /.dll /g' | sed 's/$/.dll/') ReShade.ini ReShade32.json ReShade64.json d3dcompiler_47.dll Shaders Textures ReShade_shaders ${LINK_PRESET}"
    for link in $LINKS; do
        if [[ -L $gamePath/$link ]]; then
            echo "Unlinking \"$gamePath/$link\"."
            unlink "$gamePath/$link"
        fi
    done
    if [[ $DELETE_RESHADE_FILES == 1 ]]; then
        echo "Deleting ReShade.log and ReShadePreset.ini"
        rm -f "$gamePath/ReShade.log" "$gamePath/ReShadePreset.ini"
    fi
    echo "Finished uninstalling ReShade for '$gamePath'."
    echo -e "\e[40m\e[32mMake sure to remove or change the \e[34mWINEDLLOVERRIDES\e[32m environment variable.\e[0m"
    exit 0
fi

getGamePath
echo "Do you want $0 to attempt to automatically detect the right dll files to use for ReShade?"
[[ $(checkStdin "(y/n) " "^(y|n)$") == "y" ]] && wantedDll="auto" || wantedDll="manual"
exeArch=32
if [[ $wantedDll == "auto" ]]; then
    for file in "$gamePath/"*.exe; do
        if [[ $(file "$file") =~ x86-64 ]]; then
            exeArch=64
            break
        fi
    done
    [[ $exeArch -eq 32 ]] && wantedDll="d3d9" || wantedDll="dxgi"
    echo "We have detected the game is $exeArch bits, we will use $wantedDll.dll as the override, is this correct?"
    [[ $(checkStdin "(y/n) " "^(y|n)$") == "n" ]] && wantedDll="manual"
else
    echo "Specify if the game's EXE file architecture is 32 or 64 bits:"
    [[ $(checkStdin "(32/64) " "^(32|64)$") == 64 ]] && exeArch=64
fi
if [[ $wantedDll == "manual" ]]; then
    echo "Manually enter the dll override for ReShade, common values are one of: $COMMON_OVERRIDES"
    while true; do
        read -rp 'Override: ' wantedDll
        wantedDll=${wantedDll//.dll/}
        echo "You have entered '$wantedDll', is this correct?"
        read -rp '(y/n): ' ynCheck
        [[ $ynCheck =~ ^(y|Y|yes|YES)$ ]] && break
    done
fi

downloadD3dcompiler_47 "$exeArch"

echo "Linking ReShade files to game directory."
[[ -L $gamePath/$wantedDll.dll ]] && unlink "$gamePath/$wantedDll.dll"
if [[ $exeArch == 32 ]]; then
    echo "Linking ReShade32.dll to $wantedDll.dll."
    ln -is "$(realpath "$RESHADE_PATH/$RESHADE_VERSION"/ReShade32.dll)" "$gamePath/$wantedDll.dll"
    cp $HOME/.local/share/reshade/hdr_addon/AutoHDR.addon32 $gamePath
else
    echo "Linking ReShade64.dll to $wantedDll.dll."
    ln -is "$(realpath "$RESHADE_PATH/$RESHADE_VERSION"/ReShade64.dll)" "$gamePath/$wantedDll.dll"
    cp $HOME/.local/share/reshade/hdr_addon/AutoHDR.addon64 $gamePath
fi
[[ -L $gamePath/d3dcompiler_47.dll ]] && unlink "$gamePath/d3dcompiler_47.dll"
ln -is "$(realpath "$MAIN_PATH/d3dcompiler_47.dll.$exeArch")" "$gamePath/d3dcompiler_47.dll"
[[ -L $gamePath/ReShade_shaders ]] && unlink "$gamePath/ReShade_shaders"
ln -is "$(realpath "$MAIN_PATH"/ReShade_shaders)" "$gamePath/"
if [[ $GLOBAL_INI != 0 ]] && [[ -f $MAIN_PATH/$GLOBAL_INI ]]; then
    [[ -L $gamePath/$GLOBAL_INI ]] && unlink "$gamePath/$GLOBAL_INI"
    ln -is "$(realpath "$MAIN_PATH/$GLOBAL_INI")" "$gamePath/$GLOBAL_INI"
fi
if [[ -f $MAIN_PATH/$LINK_PRESET ]]; then
    echo "Linking $LINK_PRESET to game directory."
    [[ -L $gamePath/$LINK_PRESET ]] && unlink "$gamePath/$LINK_PRESET"
    ln -is "$(realpath "$MAIN_PATH/$LINK_PRESET")" "$gamePath/$LINK_PRESET"
fi

cat > $gamePath/ReShadePreset.ini <<SETTINGS
Techniques=AdvancedAutoHDR@AdvancedAutoHDR.fx
TechniqueSorting=AdvancedAutoHDR@AdvancedAutoHDR.fx

[AdvancedAutoHDR.fx]
AUTO_HDR_MAX_NITS=750.000000
AUTO_HDR_METHOD=1
AUTO_HDR_SHOULDER_POW=2.500000
AUTO_HDR_SHOULDER_START_ALPHA=0.000000
BLACK_FLOOR_LUMINANCE=0.000000
EXTRA_HDR_SATURATION=0.000000
FIX_SRGB_2_2_GAMMA_MISMATCH_TYPE=0
HDR_HIGHLIGHTS_SHOULDER_START_ALPHA=0.500000
HDR_PEAK_WHITE=750.000000
HDR_SOURCE_PEAK_WHITE=0.000000
HDR_TONEMAP=0
HIGHLIGHT_SATURATION=1.000000
INVERSE_TONEMAP_COLOR_CONSERVATION=0.000000
INVERSE_TONEMAP_METHOD=0
IN_COLOR_SPACE=2
OUTPUT_WHITE_LEVEL_NITS=400.000000
OUT_COLOR_SPACE=0
OUT_OF_GAMUT_COLORS_BEHAVIOUR=0
SHADOW_TUNING=1.000000
SOURCE_HDR_WHITE_LEVEL_NITS=80.000000
TONEMAPPER_WHITE_LEVEL=2.000000
SETTINGS

echo -e "$SEPERATOR\nDone game patched with HDR support !"
echo -e "\e[40m\e[32mIf you're using Steam, right click the game, click properties, set the 'LAUNCH OPTIONS' to: \e[34m$gameEnvVar"
echo -e "\e[32mTo modify HDR settings, press HOME hey and go to AdvancedAutoHdr parameters to ajust with your choice" \

#!/bin/bash

SEPERATOR="------------------------------------------------------------------------------------------------"
COMMON_OVERRIDES="d3d8 d3d9 d3d11 ddraw dinput8 dxgi opengl32"
REQUIRED_EXECUTABLES="7z curl git grep"
#XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
MAIN_PATH=${MAIN_PATH:-"$HOME/.local/share/reshade"}
RESHADE_PATH="$MAIN_PATH/reshade"
WINE_MAIN_PATH="$(echo "$MAIN_PATH" | sed "s#/home/$USER/##" | sed 's#/#\\\\#g')"
UPDATE_RESHADE=${UPDATE_RESHADE:-1}
MERGE_SHADERS=${MERGE_SHADERS:-1}
VULKAN_SUPPORT=${VULKAN_SUPPORT:-0}
GLOBAL_INI=${GLOBAL_INI:-"ReShade.ini"}
SHADER_REPOS=${SHADER_REPOS:-"https://github.com/CeeJayDK/SweetFX|sweetfx-shaders;https://github.com/martymcmodding/qUINT|martymc-shaders;https://github.com/BlueSkyDefender/AstrayFX|astrayfx-shaders;https://github.com/prod80/prod80-ReShade-Repository|prod80-shaders;https://github.com/crosire/reshade-shaders|reshade-shaders|slim;"}
RESHADE_VERSION=${RESHADE_VERSION:-"latest"}
RESHADE_ADDON_SUPPORT=${RESHADE_ADDON_SUPPORT:-0}
FORCE_RESHADE_UPDATE_CHECK=${FORCE_RESHADE_UPDATE_CHECK:-0}
RESHADE_URL="https://reshade.me"
RESHADE_URL_ALT="http://static.reshade.me"
HDR_LINUX_ADDON="https://github.com/EndlesslyFlowering/AutoHDR-ReShade/releases/download/2024.04.17/AutoHDR.addon64"


zenity --info --title "Easy HDR Linux Installer" --width 300 --text "Welcome to Easy HDR Installer for Linux. All the components include the installation of Gamescope, Kwin HDR Mods, Reshade Linux Fork, HDR Injection Mods"

zenity --question --width 300 --text "Do you want to proceed?";
[[ "$?" != "0" ]] && exit 1

PACKAGE1=gamescope-plus
PACKAGE2=vk-hdr-layer-kwin6-git

if pacman -Qs $PACKAGE1 > /dev/null ; then
  zenity --info --title "Easy HDR Linux Installer" --width 300 --text "Check : Good ! The package $PACKAGE1 is installed"
else
  zenity --info --title "Easy HDR Linux Installer" --width 300 --text "Check : The package $PACKAGE1 is not installed"
  zenity --question --text="Do you want to install this package?"
  if [[ $? -eq 0 ]]; then $TERM --command /bin/sh -c "yay --answerdiff None --answerclean None --mflags "--noconfirm" -S gamescope-plus" | zenity --progress --title="Easy HDR Linux Installer" --text="Gamescope-plus installation" --pulsate --width=450 --auto-close
else zenity --warning
fi
  fi 
if pacman -Qs $PACKAGE2 > /dev/null ; then
  zenity --info --title "Easy HDR Linux Installer" -c-width 300 --text "Check : Good ! The package $PACKAGE2 is installed"
else
  zenity --info --title "Easy HDR Linux Installer" --width 300 --text "Check : The package $PACKAGE2 is not installed"
  zenity --question --text="Do you want to install this package?"
  if [[ $? -eq 0 ]]; then $TERM --command /bin/sh -c "yay --answerdiff None --answerclean None --mflags "--noconfirm" -S vk-hdr-layer-kwin6-git" | zenity --progress --title="Easy HDR Linux Installer" --text="Vulkan HDR layer for Kwin installation" --pulsate --width=450 --auto-close
else zenity --warning
fi
  fi

function printErr() {
    removeTempDir
    echo -e "\e[40m\e[31mError: $1\nExiting.\e[0m"
    [[ -z $2 ]] && exit 1 || exit "$2"
}

function createTempDir() {
    tmpDir=$(mktemp -d)
    cd "$tmpDir" || printErr "Failed to create temp directory."
}

function removeTempDir() {
    cd "$MAIN_PATH" || exit
    [[ -d $tmpDir ]] && rm -rf "$tmpDir"
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

function downloadReshade() {
    createTempDir
    curl -sLO "$2" || printErr "Could not download version $1 of ReShade."
    exeFile="$(find . -name "*.exe")"
    ! [[ -f $exeFile ]] && printErr "Download of ReShade exe file failed."
    [[ $(file "$exeFile" | grep -o executable) == "" ]] && printErr "The ReShade exe file is not an executable file, does the ReShade version exist?"
    7z -y e "$exeFile" 1> /dev/null || printErr "Failed to extract ReShade using 7z."
    rm -f "$exeFile"
    resCurPath="$RESHADE_PATH/$1"
    [[ -e $resCurPath ]] && rm -rf "$resCurPath"
    mkdir -p "$resCurPath"
    mv ./* "$resCurPath"
    removeTempDir
}

for REQUIRED_EXECUTABLE in $REQUIRED_EXECUTABLES; do
    if ! which "$REQUIRED_EXECUTABLE" &> /dev/null; then
        echo -ne "Program '$REQUIRED_EXECUTABLE' is missing, but it is required.\nExiting.\n"
        exit 1
    fi
done

mkdir -p "$MAIN_PATH"
mkdir -p "$RESHADE_PATH"
mkdir -p "$MAIN_PATH/ReShade_shaders"
mkdir -p "$MAIN_PATH/External_shaders"

[[ -f LASTUPDATED ]] && LASTUPDATED=$(cat LASTUPDATED) || LASTUPDATED=0
[[ ! $LASTUPDATED =~ ^[0-9]+$ ]] && LASTUPDATED=0
[[ $LASTUPDATED -gt 0 && $(($(date +%s)-LASTUPDATED)) -lt 14400 ]] && UPDATE_RESHADE=0
[[ $UPDATE_RESHADE == 1 ]] && date +%s > LASTUPDATED

zenity --info --title "Easy HDR Linux Installer" --width 300 --text "Install of ReShade HDR mods for Linux games"

mv ./hdr_patch.sh $HOME/.local/share/reshade/ | zenity --progress --title="Easy HDR Linux Installer" --text="Installing hdr_patch" --pulsate --width=450 --auto-close

mv ./hdr_autoswitch.sh $HOME/.local/share/reshade/ | zenity --progress --title="Easy HDR Linux Installer" --text="Installing hdr_autoswitch for kde" --pulsate --width=450 --auto-close

function linkShaderFiles() {
    [[ ! -d $1 ]] && return
    cd "$1" || return
    for file in *; do
        [[ ! -f $file ]] && continue
        [[ -L "$MAIN_PATH/ReShade_shaders/Merged/$2/$file" ]] && continue
        INFILE="$(realpath "$1/$file")"
        OUTDIR="$(realpath "$MAIN_PATH/ReShade_shaders/Merged/$2/")"
        [[ ! -d $OUTDIR ]] && mkdir -p "$OUTDIR"
        echo "Linking $INFILE to $OUTDIR"
        ln -s "$INFILE" "$OUTDIR"
    done
}

function mergeShaderDirs() {
    [[ $1 != ReShade_shaders && $1 != External_shaders ]] && return
    for dirName in Shaders Textures; do
        [[ $1 == "ReShade_shaders" ]] && dirPath=$(find "$MAIN_PATH/$1/$2" ! -path . -type d -name "$dirName") || dirPath="$MAIN_PATH/$1/$dirName"
        linkShaderFiles "$dirPath" "$dirName" |  zenity --progress --title="Easy HDR Linux Installer" --text="Reshade Shaders updates" --pulsate --width=450 --auto-close
        # Check if there are any extra directories inside the Shaders or Texture folder, and link them.
        while IFS= read -rd '' anyDir; do
            linkShaderFiles "$dirPath/$anyDir" "$dirName/$anyDir"
        done < <(find . ! -path . -type d -print0)
    done
}
if [[ -n $SHADER_REPOS ]]; then
    [[ $REBUILD_MERGE == 1 ]] && rm -rf "$MAIN_PATH/ReShade_shaders/Merged/"
    [[ $MERGE_SHADERS == 1 ]] && mkdir -p "$MAIN_PATH/ReShade_shaders/Merged/Shaders" &&  mkdir -p "$MAIN_PATH/ReShade_shaders/Merged/Textures"
    for URI in $(echo "$SHADER_REPOS" | tr ';' '\n'); do
        localRepoName=$(echo "$URI" | cut -d'|' -f2)
        branchName=$(echo "$URI" | cut -d'|' -f3)
        URI=$(echo "$URI" | cut -d'|' -f1)
        if [[ -d "$MAIN_PATH/ReShade_shaders/$localRepoName" ]]; then
            if [[ $UPDATE_RESHADE -eq 1 ]]; then
                cd "$MAIN_PATH/ReShade_shaders/$localRepoName" || continue
                echo "Updating ReShade shader repository $URI."
                git pull || echo "Could not update shader repo: $URI."
            fi
        else
            cd "$MAIN_PATH/ReShade_shaders" || exit
            [[ -n $branchName ]] && branchName="--branch $branchName" || branchName=
            eval git clone "$branchName" "$URI" "$localRepoName" || echo "Could not clone Shader repo: $URI."
        fi
        [[ $MERGE_SHADERS == 1 ]] && mergeShaderDirs "ReShade_shaders" "$localRepoName" | zenity --progress --title="Easy HDR Linux Installer" --text="Merging Shaders" --pulsate --width=450 --auto-close
    done
    if [[ $MERGE_SHADERS == 1 ]] && [[ -d "$MAIN_PATH/External_shaders" ]]; then
        mergeShaderDirs "External_shaders" |  zenity --progress --title="Easy HDR Linux Installer" --text="Checking for external Shader updates" --pulsate --width=450 --auto-close
        # Link loose files.
        cd "$MAIN_PATH/External_shaders" || exit 1
        for file in *; do
            [[ ! -f $file || -L "$MAIN_PATH/ReShade_shaders/Merged/Shaders/$file" ]] && continue
            INFILE="$(realpath "$MAIN_PATH/External_shaders/$file")"
            OUTDIR="$MAIN_PATH/ReShade_shaders/Merged/Shaders/"
            echo "Linking $INFILE to $OUTDIR"
            ln -s "$INFILE" "$OUTDIR"
        done
    fi
fi
echo "$SEPERATOR"

cd "$MAIN_PATH" || exit
[[ -f LVERS ]] && LVERS=$(cat LVERS) || LVERS=0
if [[ $RESHADE_VERSION == latest ]]; then
    # Check if user wants reshade without addon support and we're currently using reshade with addon support.
    [[ $LVERS =~ Addon && $RESHADE_ADDON_SUPPORT -eq 0 ]] && UPDATE_RESHADE=1
    # Check if user wants reshade with addon support and we're not currently using reshade with addon support.
    [[ ! $LVERS =~ Addon ]] && [[ $RESHADE_ADDON_SUPPORT -eq 1 ]] && UPDATE_RESHADE=1
fi
if [[ $FORCE_RESHADE_UPDATE_CHECK -eq 1 ]] || [[ $UPDATE_RESHADE -eq 1 ]] || [[ ! -e reshade/latest/ReShade64.dll ]] || [[ ! -e reshade/latest/ReShade32.dll ]]; then
    RHTML=$(curl --max-time 10 -sL "$RESHADE_URL")
    ALT_URL=0
    if [[ $? != 0 || $RHTML =~ '<h2>Something went wrong.</h2>' ]]; then
        ALT_URL=1
        echo "Error: Failed to connect to '$RESHADE_URL' after 10 seconds. Trying to connect to '$RESHADE_URL_ALT'."
        RHTML=$(curl -sL "$RESHADE_URL_ALT")
        [[ $? != 0 ]] && echo "Error: Failed to connect to '$RESHADE_URL_ALT'."
    fi
    [[ $RESHADE_ADDON_SUPPORT -eq 1 ]] && VREGEX="[0-9][0-9.]*[0-9]_Addon" || VREGEX="[0-9][0-9.]*[0-9]"
    RLINK="$(echo "$RHTML" | grep -o "/downloads/ReShade_Setup_${VREGEX}\.exe" | head -n1)"
    [[ $RLINK == "" ]] && printErr "Could not fetch ReShade version."
    [[ $ALT_URL -eq 1 ]] && RLINK="${RESHADE_URL_ALT}${RLINK}" || RLINK="${RESHADE_URL}${RLINK}"
    RVERS=$(echo "$RLINK" | grep -o "$VREGEX")
    if [[ $RVERS != "$LVERS" ]]; then
        [[ -L $RESHADE_PATH/latest ]] && unlink "$RESHADE_PATH/latest"
        echo -e "Updating ReShade to latest version."
        downloadReshade "$RVERS" "$RLINK"
        ln -is "$(realpath "$RESHADE_PATH/$RVERS")" "$(realpath "$RESHADE_PATH/latest")"
        echo "$RVERS" > LVERS
        LVERS="$RVERS"
        echo "Updated ReShade to version $RVERS."
    fi
fi

cd "$MAIN_PATH" || exit
if [[ $RESHADE_VERSION != latest ]]; then
    [[ $RESHADE_ADDON_SUPPORT -eq 1 ]] && RESHADE_VERSION="${RESHADE_VERSION}_Addon"
    if [[ ! -f reshade/$RESHADE_VERSION/ReShade64.dll ]] || [[ ! -f reshade/$RESHADE_VERSION/ReShade32.dll ]]; then
        echo -e "Downloading version $RESHADE_VERSION of ReShade.\n$SEPERATOR\n"
        [[ -e reshade/$RESHADE_VERSION ]] && rm -rf "reshade/$RESHADE_VERSION"
        downloadReshade "$RESHADE_VERSION" "$RESHADE_URL/downloads/ReShade_Setup_$RESHADE_VERSION.exe" | zenity --progress --title="Easy HDR Linux Installer" --text="Reshade Downloading" --pulsate --width=450 --auto-close
    fi
    echo -e "Using version $RESHADE_VERSION of ReShade.\n"
else
    echo -e "Using the latest version of ReShade ($LVERS).\n"
fi

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

for url in https://raw.githubusercontent.com/Filoppi/PumboAutoHDR/refs/heads/master/Shaders/Pumbo/AdvancedAutoHDR.fx https://raw.githubusercontent.com/Filoppi/PumboAutoHDR/refs/heads/master/Shaders/Pumbo/Color.fxh https://raw.githubusercontent.com/Filoppi/PumboAutoHDR/refs/heads/master/Shaders/Pumbo/ConvertColorSpace.fx
do
 curl -sLO $url --output-dir "$MAIN_PATH/ReShade_shaders/Merged/Shaders/" | zenity --progress --title="Easy HDR Linux Installer" --text="Transfering Auto-HDR shaders" --pulsate --width=450 --auto-close
done
for url in https://raw.githubusercontent.com/EndlesslyFlowering/ReShade_HDR_shaders/refs/heads/master/Shaders/lilium__cas_hdr.fx https://raw.githubusercontent.com/EndlesslyFlowering/ReShade_HDR_shaders/refs/heads/master/Shaders/lilium__filmgrain.fx https://raw.githubusercontent.com/EndlesslyFlowering/ReShade_HDR_shaders/refs/heads/master/Shaders/lilium__hdr_and_sdr_analysis.fx https://raw.githubusercontent.com/EndlesslyFlowering/ReShade_HDR_shaders/refs/heads/master/Shaders/lilium__hdr_black_floor_fix.fx https://raw.githubusercontent.com/EndlesslyFlowering/ReShade_HDR_shaders/refs/heads/master/Shaders/lilium__inverse_tone_mapping.fx https://raw.githubusercontent.com/EndlesslyFlowering/ReShade_HDR_shaders/refs/heads/master/Shaders/lilium__map_sdr_into_hdr.fx https://raw.githubusercontent.com/EndlesslyFlowering/ReShade_HDR_shaders/refs/heads/master/Shaders/lilium__rcas_hdr.fx https://raw.githubusercontent.com/EndlesslyFlowering/ReShade_HDR_shaders/refs/heads/master/Shaders/lilium__sdr_trc_fix.fx https://github.com/EndlesslyFlowering/ReShade_HDR_shaders/blob/master/Shaders/lilium__test_pattern_generator.fx https://raw.githubusercontent.com/EndlesslyFlowering/ReShade_HDR_shaders/refs/heads/master/Shaders/lilium__tone_mapping.fx
do
 curl -sLO $url --output-dir "$MAIN_PATH/ReShade_shaders/Merged/Shaders/" | zenity --progress --title="Easy HDR Linux Installer" --text="Transfering Lilium HDR shaders" --pulsate --width=450 --auto-close
done
for url in https://raw.githubusercontent.com/MaxG2D/ReshadeSimpleHDRShaders/refs/heads/main/Shaders/HDRBloom.fx https://raw.githubusercontent.com/MaxG2D/ReshadeSimpleHDRShaders/refs/heads/main/Shaders/HDRMotionBlur.fx https://raw.githubusercontent.com/MaxG2D/ReshadeSimpleHDRShaders/refs/heads/main/Shaders/HDRSaturation.fx https://raw.githubusercontent.com/MaxG2D/ReshadeSimpleHDRShaders/refs/heads/main/Shaders/HDRShadersFunctions.fxh
do
 curl -sLO $url --output-dir "$MAIN_PATH/ReShade_shaders/Merged/Shaders/" | zenity --progress --title="Easy HDR Linux Installer" --text="Transfering maxG2D HDR  shaders" --pulsate --width=450 --auto-close
done
for url in https://github.com/EndlesslyFlowering/AutoHDR-ReShade/releases/download/2024.04.17/AutoHDR.addon64 https://github.com/EndlesslyFlowering/AutoHDR-ReShade/releases/download/2024.04.17/AutoHDR.addon32
do curl -sLO $url --create-dirs --output-dir "$MAIN_PATH/hdr_addon/" | zenity --progress --title="Easy HDR Linux Installer" --text="HDR addon installation (for hdr game patching)" --pulsate --width=450 --auto-close
done
echo "alias hdr_patch=/$HOME/.local/share/reshade/hdr_patch.sh" >> $HOME/.bashrc
zenity --password | sudo -S echo "export HDR=/$HOME/.local/share/reshade/hdr_autoswitch.sh" >> $HOME/.config/plasma-workspace/env/hdr-env.sh | zenity --progress --title="Easy HDR Linux Installer" --text="HDR environment variable installation" --pulsate --width=450 --auto-close
zenity --info --title "Easy HDR Linux Installer" --width 300 --text "Installation completed, remember to read the manual and use the HDR patch for games. Thank you Pumboautohdr and Lilium for these incredible mods and all the work done. Use the hdr_patch to make your games compatible. Linux ♥ HDR!"
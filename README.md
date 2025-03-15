>This script is there to make it easier to set up HDR under Linux, the resources are lacking and it is tedious to install everything manually. The objective is to provide a simple, transparent and accessible experience for a user and allow him to take advantage of his uncompromising equipment, while remaining in the free and opensource world.

[![image.png](https://i.postimg.cc/t44Ft80x/image.png)](https://postimg.cc/vcC1GqZY)

>It is important to take into account that this installer is planned for an [Archlinux](https://archlinux.org/) distribution (and its derivatives) with a [KDE](https://kde.org/fr/plasma-desktop/) desktop environment. For what ? It is the only desktop for the HDR and the features are mature enough to allow a correct experience with the [Wayland](https://wayland.freedesktop.org/) protocol.

>It is important to note that to take advantage of the HDR, it is necessary to be equipped with an OLED or mini-LED screen (local diming), with minimum certification [VESA TRUEBLACK 400](https://screenresolutiontest.com/hdr-true-black-400-500-600/) or [HDR1000](https://screenresolutiontest.com/hdr10-vs-hdr400-vs-hdr600-vs-hdr1000/).

### Components:

- [Gamescope-Plus](https://github.com/ChimeraOS/gamescope) (Enhanced version of gamescope, the valve microcompositor)
- [Reshade](https://reshade.me/) (Enable visuals mods on DirectX games, work on linux, all requests are translated to the vulkan layer)
- [Auto-hdr-mod](https://github.com/Filoppi/PumboAutoHDR) (Inject HDR into SDR games, replace rtx-hdr and microsoft-hdr on linux)
- [HDR variables]() (setting to make Steam launch options easier)
- [HDR profile autoswitch]() (script automatically activating HDR only when the game is launched)
- [Linux Alias]() (A simple alias to patch SDR games)
- [Vulkan HDR Layer]() (Experimental kwin HDR compatibility layer)

### Requirements:

- Arch based distribution
- KDE Desktop Environment
- ProtonGE
- Steam
  
### Installation:

```
git clone https://github.com/TheCyberArcher/easy-linux-hdr
chmod -R +x easy-linux-hdr
cd ./easy-linux-hdr
RESHADE_ADDON_SUPPORT=1 ./install.sh
``` 

---

### HDR supported games:

To launch a game with HDR, paste this on steam launch options : 

``` $HDR on && gamescope --hdr-enabled -W 3840 -H 2160 -f -e --force-grab-cursor -- %command%; $HDR off ```

At the launch, this will switch to the HDR profile, adjust your brightness and launch Gamescope. \
The game closure will automatically turn off the game session, will have you go back to SDR with normal brightness.

When you are in a game, check in the options if the **HDR is available** and activate it. \
Remember to adjust your gamma to avoid an overly denatured image.

---

### Auto-HDR in SDR games: 

To patch a no-hdr game and add reshade mods support, open a terminal and write ``` hdr_patch ``` or run the .sh

Follow instructions, reply **yes** for all and indicate the path of your game.

To get the path, go to steam game properties

[![1.png](https://i.postimg.cc/G2rHnTrX/1.png)](https://postimg.cc/Ty7RrwKb)

Browse the files

[![2.png](https://i.postimg.cc/pXyQ64sp/2.png)](https://postimg.cc/YhKm4nKH)

Copy the path in your file manager

[![path.png](https://i.postimg.cc/3RjgQHGH/path.png)](https://postimg.cc/ygdJ0tnf)

(This must be the file or your .exe is present, sometimes at the root of the game file, but also possible to be in /Binaries/Win64/ )


-> **The software will automatically patch your game with best HDR mods settings 😁** \
-> **The games are already configured and HDR enabled, you don't need to touch the settings (Peak brightness at 750 nits max)

Add this at steam launch options :

```$HDR on && gamescope --hdr-enabled -W 3840 -H 2160 -f -e --force-grab-cursor -WINEDLLOVERRIDES="d3dcompiler_47=n;dxgi=n,b" -- %command%; $HDR off```

---

</br>

>UPDATE : This part is now automated with the hdr_patch.sh script. Only follow the guide if you want to make manual changes

</br>

-> **Download the [HDR addon](https://github.com/EndlesslyFlowering/AutoHDR-ReShade/releases/tag/2024.04.17) and paste in the game folder**

-> In the game press **"Home"** keyboard key to open reshade.

Go the the **addon** section : 

[![addon-option.png](https://i.postimg.cc/9FxrmJSn/addon-option.png)](https://postimg.cc/tYxXDt93)

**Enable HDR** in the options : 

[![enable-HDR.png](https://i.postimg.cc/X7WwGHsN/enable-HDR.png)](https://postimg.cc/JtTySqwS)


Select the **AdvancedAutoHDR mod**.

[![autohdr.png](https://i.postimg.cc/9FX96Z0z/autohdr.png)](https://postimg.cc/Lh7hfqzM)


On HDR options, use in input the  **SDR Rec. 709 gamma 2.2**. Ajust output at **400**.

[![SDR-REC.png](https://i.postimg.cc/RhSpRSvG/SDR-REC.png)](https://postimg.cc/xJZPjSJb)


For the method, use **Auto HDR (SDR->HDR)** and set By luminance (color hue conserving). Ajust the max autohdr brightness at **750**.

[![SDRTOHDR.png](https://i.postimg.cc/KvgBWX45/SDRTOHDR.png)](https://postimg.cc/gnmxwTVw)


Enable **autosave** for the profile.

[![autosave.png](https://i.postimg.cc/QMn2gpzP/autosave.png)](https://postimg.cc/CZkrSfSH)

---

### renoDX support: 

This reshade installation support [addons](https://reshade.me/forum/addons-section) : 

>RenoDX, short for "Renovation Engine for DirectX Games", is a toolset to mod games. Currently it can replace shaders, inject buffers, add overlays, upgrade swapchains, upgrade texture resources, and write user settings to disk. Because RenoDX uses Reshade's add-on system, compatibility is expected to be pretty wide. Using Reshade simplifies all the hooks necessary to tap into DirectX without worrying about patching version-specific exe files.

Go to the [RenoDX](https://github.com/clshortfuse/renodx/wiki/Mods) HDR mod page and select desired game. \
Download the add-on and paste on the game-folder.

Press the **"Home"** key to open reshade, renodx is present in the addon section and can be combined with the native HDR.

[![renodx2.png](https://i.postimg.cc/JnmFyYWZ/renodx2.png)](https://postimg.cc/p9GC4ZrL)

---

### Credits:

| Team | Description |
| --- | --- |
| [Reshade-Steam-Proton](https://github.com/kevinlekiller/reshade-steam-proton) | Thanks to Kevinlekiller for making it possible and easy to run Reshade with Proton 🤘 |
| [PumboAutoHDR](https://github.com/Filoppi/PumboAutoHDR) | Thanks to Filoppi, have created a Auto-HDR mod, it is incredible! Especially under Linux or are absent the car from Microsoft and the RTX-HDR ❤️ |
| [renoDX](https://github.com/clshortfuse/renodx) | Special Thanks to the renodx team, having done incredible job for HDR 🙏 |
| [Gamescope-plus](https://github.com/ChimeraOS/gamescope) | To ChimeraOS team, with gamescope-plus, which improve gaming under Linux 😁  |
| [HDR-Addon](https://github.com/EndlesslyFlowering/AutoHDR-ReShade) | Lilium, for this addon, improved version of AutoHDR |
| [VK_hdr_layer](https://github.com/Zamundaaa/VK_hdr_layer) | Thank Zamundaaa, for the incredible work on the HDR Vulkan compatibility layer for kwin |



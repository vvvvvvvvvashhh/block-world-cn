# 来源与署名 / Third-party notices

方块世界是 Luanti 与 Mineclonia 上的中文本地整合/定制项目，不是独立原创引擎或完整自研生存游戏。维护者：N1n3VASthR33H（GitHub 账号 vvvvvvvvvashhh）。与 Mojang/Microsoft 没有关联或背书；未包含其专有安装文件和材质。

| 组件 | 固定版本 / 许可 | 来源与本包位置 |
|---|---|---|
| Luanti | 5.17.0，LGPL-2.1-or-later，媒体另见许可 | https://github.com/luanti-org/luanti ；离线包 downloads/luanti-5.17.0-source.zip |
| Mineclonia | 0.123.1，整体 GPL-3.0-or-later | https://codeberg.org/mineclonia/mineclonia ；downloads/mineclonia-0.123.1.zip 含全部 Lua、素材及署名 |
| 本地 Lua、启动和发布脚本 | GPL-3.0-or-later | 本仓库 src、scripts |
| 几何 HUD 与生成器 | CC0-1.0 | assets/LICENSE.txt、src/generate_ui.py |
| 默认像素材质 | 多数 CC BY-SA 4.0，其他逐文件许可 | XSSheep 的 Pixel Perfection、Nova Wostra 的 Pixel Perfection Legacy；详见 licenses/Mineclonia-LEGAL.md、Mineclonia-CREDITS.md |
| Contributor Covenant | 2.1，CC BY 4.0 | https://www.contributor-covenant.org/version/2/1/code_of_conduct/ |

本地变更包括中文菜单/术语、HUD、光照和操作默认值、体验模组，以及红石坐标兼容修复。修改后的上游文件完整保留在 src；原始游戏源码和差异对照见 downloads/mineclonia-0.123.1.zip、docs/upstream.patch。上游全部媒体许可保留在游戏各目录中，LICENSE 不重新授权这些素材。

Windows 官方二进制附带的第三方 DLL 保留原授权；licenses 中附加 curl、FreeType、libjpeg-turbo、LevelDB、libpng、Ogg/Vorbis、Zstandard、SDL2、zlib、LuaJIT、LLVM/libc++/libunwind、MinGW-w64 的许可材料。SQLite 属于公有领域，见 https://www.sqlite.org/copyright.html 。本产品部分使用 FreeType（https://freetype.org/），其版权见 licenses/freetype.txt；本软件部分基于 Independent JPEG Group 的工作，见 licenses/libjpeg-README.ijg。

OpenAL Soft 1.25.1、GNU libiconv 1.17 与 GNU gettext 0.20.2 的未修改源码也随离线包提供，许可在 licenses 中。对应版本来自 Luanti 的 util/buildbot/common.sh 和 DLL 版本信息；引擎源码含构建脚本与依赖版本，不是可重复编译已认证声明。字体及游戏内其他素材按原包随附许可使用。

完整下载地址与校验值见 dependencies.lock.json。请在再分发时一并保留源码、许可、修改说明及署名；不要仅复制可执行文件。源代码与离线发行包均从同一 GitHub Release 提供。

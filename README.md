# ScribbyMac

> A tiny, native macOS overlay for drawing arrows, boxes, and text on top of your screen.

ScribbyMac 是一个轻量的 macOS 菜单栏屏幕标注工具，适合演示、教学、远程协作和录屏讲解。它不截图、不读取其他应用内容，标注直接绘制在屏幕上；结束绘图后，标注仍然可见，鼠标可以继续操作下方应用。

## 功能

- 箭头、矩形框、单行文字
- 红、黄、绿、蓝、白、黑六种颜色
- 图形线宽：2、4、8 pt
- 文字字号：18、24、36 pt（与线宽共用同一组工具栏控件）
- `⌘⇧D` 开始／结束绘图
- `Esc`：输入文字时取消；没有输入框时结束绘图
- `⌘Z` 撤销最近操作；清空全部也可以撤销
- 文字按 Enter、失去焦点或点击其他位置提交
- 菜单栏显示，默认不显示 Dock 图标

## 安装与运行

从 [Releases](../../releases) 下载最新的 `ScribbyMac.app`，拖到“应用程序”后打开。

本项目目前提供本地 ad-hoc 构建，未经过 Apple 公证或 Mac App Store 审核。首次打开时如果 macOS 显示安全提示，请在“系统设置 → 隐私与安全性”中允许打开。

## 从源码构建

要求：Apple Silicon Mac、macOS 13 或更高版本、Xcode 26。

```sh
git clone https://github.com/Marxss/ScribbyMac.git
cd ScribbyMac
bash scripts/build-local-app.sh
open dist/ScribbyMac.app
```

运行测试：

```sh
xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac \
  -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
```

也可以直接用 Xcode 打开 `ScribbyMac.xcodeproj`，选择 `ScribbyMac` scheme 后运行。

## 使用说明

1. 启动应用后，点击菜单栏中的铅笔图标，或按 `⌘⇧D`。
2. 在顶部工具栏选择箭头、矩形或文字。
3. 图形工具拖动鼠标完成绘制；文字工具点击屏幕后直接输入。
4. 选择颜色，以及图形线宽或文字字号。
5. 按 `Esc` 结束绘图；标注会保留并让鼠标穿透到下方应用。
6. 从菜单栏可以重新显示、隐藏、撤销、清空或退出。

## 配合 macOS 自带录屏

macOS 自带的“截屏”工具可以把 ScribbyMac 的标注一起录入视频。推荐录制整个屏幕；如果只想录制部分内容，也可以框选一个包含目标应用和标注区域的范围。

### 录屏快捷键

- `Shift + Command + 5`：打开截屏与录屏控制栏。
- `Shift + Command + 3`：截取整个屏幕的静态图片，不是录屏。
- `Shift + Command + 4`：截取选定区域的静态图片，不是录屏。

### 推荐操作流程

1. 打开需要演示或讲解的应用，并整理好窗口位置。
2. 按 `Shift + Command + 5` 打开 macOS 截屏控制栏。
3. 选择“录制整个屏幕”，或者选择“录制选定部分”并调整录制范围。
4. 点击“选项”设置麦克风、保存位置和倒计时等录制选项。
5. 点击“录制”开始录屏。
6. 按 `Command + Shift + D` 进入 ScribbyMac 绘图模式，使用箭头、矩形和文字进行讲解。
7. 按 `Esc` 结束绘图。已完成的标注继续显示，同时鼠标恢复操作下方应用。
8. 点击菜单栏中的停止按钮，或按 `Command + Control + Esc`，结束录屏。

> [!IMPORTANT]
> 不要使用“录制所选窗口／指定窗口”的方式。只捕获目标应用窗口时，位于它上方的 ScribbyMac 透明标注层可能不会被录入。`Shift + Command + 5` 控制栏中的窗口图标用于截取窗口静态图片，也不是录屏按钮。请认准带圆点的“录制整个屏幕”或“录制选定部分”按钮。

如果使用“录制选定部分”，请确保录制框覆盖所有需要出现的标注。录制开始后再移动目标窗口，可能会让窗口或标注超出录制范围。

## 设计取舍与限制

- 仅覆盖系统主显示器。
- 普通桌面和应用窗口是目标场景；全屏游戏、系统安全界面和受保护窗口不保证覆盖。
- 标注只保存在当前进程内存，退出应用后丢失，不写入磁盘。
- 当前不支持选择、移动、缩放、导入、导出、重做或持久化。
- 不联网，不请求辅助功能、屏幕录制、麦克风、摄像头、位置或通讯录权限。

## 技术栈

Swift 6、AppKit、Core Graphics、Carbon、XCTest。项目不依赖第三方库。

## 参与贡献

欢迎提交 Issue 和 Pull Request。提交代码前请：

1. 为新行为补充或更新 XCTest。
2. 运行完整测试和 `git diff --check`。
3. 在 Issue 或 PR 中说明 macOS 版本、芯片型号和复现步骤。

## 许可证

项目暂未选择开源许可证。正式公开仓库前，请在根目录加入 `LICENSE` 文件；在没有许可证之前，默认不授予他人复制、修改或分发代码的权利。

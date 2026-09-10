# ScribbyMac

原生 macOS 菜单栏屏幕标注工具。要求 Apple Silicon、macOS 13 或更高版本。

## 运行

双击 `dist/ScribbyMac.app`，菜单栏出现铅笔图标。按 **⌘⇧D** 开始或结束绘图。
更新应用后需从菜单栏退出旧进程再重新打开，当前内存中的标注会随退出丢失；仅重新双击不会替换正在运行的代码。
工具栏提供箭头、矩形、单行文字；红、黄、绿、蓝、白、黑六色；2、4、8 point 三档线宽。
拖动绘制图形；文字工具单击后输入，Enter、点击其他位置、失去焦点、切换工具或结束绘图均提交非空文字，Escape 取消。未完成的图形仍取消。
文字工具下，原线宽按钮切换为字号 18／24／36；图形工具下为线宽 2／4／8。字号和线宽分别记忆，调整字号即时更新正在编辑的文字，已提交文字不改变。
⌘Z 或撤销按钮撤销最近操作，清空也可撤销。结束绘图后标注保留，鼠标可操作下方应用。
菜单栏提供开始／结束绘图、隐藏／显示标注、撤销、清空和退出。

## 构建

使用 Xcode 26 和随附 Swift 工具链，无第三方依赖：

```sh
bash scripts/build-local-app.sh
xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
```

也可用 Xcode 打开 `ScribbyMac.xcodeproj`，选择 `ScribbyMac` scheme。
构建脚本可从任意目录运行，产物为 `dist/ScribbyMac.app`，使用本地 ad-hoc 签名。
产物未公证、未上架。若系统阻止打开，可在系统设置的“隐私与安全性”检查提示并选择打开；无需关闭 Gatekeeper。

## 范围与限制

仅覆盖主显示器。普通桌面和窗口为目标场景，标准全屏兼容性需在实际设备验证；全屏游戏、系统安全界面和受保护窗口不保证覆盖。
改变显示器配置后需重新进入绘图，标注坐标不会迁移。
标注仅在本次进程内存，退出即丢失；不支持导出、保存、选择、移动、缩放或重做。
不联网，不请求辅助功能或屏幕录制权限，不包含开机启动、账号或付费功能。

验收记录见 `docs/manual-test-checklist.md`。自动测试通过不等同于全部手动交互已经验收。

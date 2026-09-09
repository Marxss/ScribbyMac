# 手动界面验收

日期：2026-09-09。BLOCKED 表示尚未完成手动验证，不表示已确认功能失败。

环境：Apple Silicon，macOS 26.6.2，Xcode 26.6。
本次电脑控制工具返回 `timeoutReached (-10005)`，没有取得应用界面；进程检查确认本地 app 曾启动，随后已结束该测试进程。不能据此认定绘图交互已验收。
Release 构建成功；arm64 架构、macOS 13.0 最低版本、LSUIElement 和 ad-hoc 签名校验通过。
最终自动测试：28 项、0 失败。记录：`build/Tests/Logs/Test/Test-ScribbyMac-2026.09.09_09-01-24-+0800.xcresult`。最初运行受沙箱限制，随后运行受已有 app 实例影响；结束本次启动的实例后重跑通过。
Xcode 仍有 AppIntents 元数据扫描提示和 XCTest 工具链警告，未达到计划中“全部日志零警告”的标准。
独立代码审查发现的完成按钮焦点恢复、画布 Command-Z、稳定主显示器选择问题已修复并通过静态复审。

实现偏差记录：主显示器使用 `NSScreen.screens.first`；计划写出的 `NSScreen.main` 会跟随 key window，不能代表固定主显示器。工具栏以 visibleFrame 顶部定位，避免被菜单栏遮挡。

| 项目 | 状态 | 证据和备注 |
| --- | --- | --- |
| 1. 双击 app 启动 | BLOCKED | 待验证 |
| 2. 菜单栏图标、无 Dock 图标 | BLOCKED | 待验证 |
| 3. 无辅助功能／屏幕录制请求 | BLOCKED | 待验证 |
| 4. ⌘⇧D 进入／退出 | BLOCKED | 待验证 |
| 5. 顶部居中工具栏和红框 | BLOCKED | 待验证 |
| 6. 任意方向箭头和矩形 | BLOCKED | 待验证 |
| 7. 单行文字、Enter、Escape | BLOCKED | 待验证 |
| 8. 六色、三线宽 | BLOCKED | 待验证 |
| 9. 退出保留标注并鼠标穿透 | BLOCKED | 待验证 |
| 10. 隐藏／显示、清空、退出 | BLOCKED | 待验证 |
| 11. ⌘Z 撤销添加和清空 | BLOCKED | 待验证 |
| 12. 普通窗口及标准全屏应用 | BLOCKED | 待验证 |
| 13. 快捷键冲突提示及菜单入口 | BLOCKED | 待验证 |
| 14. 重启不恢复标注 | BLOCKED | 待验证 |

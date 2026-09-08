# ScribbyMac 屏幕标注 MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个仅在 Apple Silicon、macOS 13+ 运行的原生菜单栏应用，让用户通过固定快捷键在主显示器上绘制箭头、矩形和单行文字，并在退出绘图后保留可穿透标注。

**Architecture:** 使用 AppKit 管理菜单栏、透明覆盖窗口、悬浮工具栏和文字输入，以 Core Graphics 渲染不可变矢量标注，以纯 Swift 的 store、几何函数和状态机承载可单元测试的核心行为。应用不持久化、不联网、不请求 Accessibility 或 Screen Recording 权限；Carbon 只注册 `Command + Shift + D` 单一全局热键。

**Tech Stack:** Swift 6、AppKit、Core Graphics、Carbon、OSLog、XCTest、Xcode 26；不使用第三方依赖。

**Spec:** `docs/superpowers/specs/2026-09-08-macos-screen-annotation-mvp-design.md`

## Global Constraints

- 支持架构仅为 `arm64`，最低部署目标为 macOS 13.0。
- 第一版只覆盖 `NSScreen.main`，不实现多显示器。
- 工作名称、target、scheme 和产物名称统一为 `ScribbyMac`。
- 应用只显示菜单栏图标，`LSUIElement = true`，不显示 Dock 图标。
- 不加入网络、持久化、登录项、付费、遥测、截图、辅助功能和 Mac App Store 配置。
- 固定热键为 `Command + Shift + D`，没有设置界面。
- 首版工具只有箭头、矩形和单行文字；颜色为红、黄、绿、蓝、白、黑，线宽为 2、4、8 point。
- 不实现选择、移动、缩放、单独删除、重做、导入或导出。
- 不修改或提交 `iScribby-Setup-v0.0.11.exe`。
- 所有生产行为先写失败测试并确认 RED，再写最小实现并确认 GREEN。

## Planned File Structure

```text
ScribbyMac.xcodeproj/
  project.pbxproj                       # App/Test targets、构建设置、scheme 元数据
  project.xcworkspace/contents.xcworkspacedata
  xcshareddata/xcschemes/ScribbyMac.xcscheme
ScribbyMac/
  App/AppDelegate.swift                 # 应用生命周期、依赖组装、焦点恢复
  App/main.swift                        # NSApplication 入口
  HotKey/GlobalHotKeyController.swift   # Carbon 热键注册与错误
  Menu/StatusMenuController.swift       # 菜单栏状态和动作
  Model/Annotation.swift                # 三种标注、工具、颜色、线宽
  Model/AnnotationStore.swift           # 内存标注与撤销命令
  Model/OverlayStateMachine.swift       # hidden/passThrough/drawing 转换
  Drawing/AnnotationGeometry.swift      # 矩形标准化、箭头尖几何
  Drawing/DrawingInteraction.swift      # 鼠标手势到草稿/提交意图
  Drawing/DrawingCanvasView.swift       # 绘图、预览、单行文字编辑
  Overlay/OverlayWindow.swift           # 透明置顶窗口
  Overlay/OverlayController.swift       # 窗口、状态、画布协调
  Toolbar/ToolbarPanelController.swift  # 顶部固定工具栏
  Resources/Assets.xcassets             # AppIcon 和 AccentColor
  Resources/Info.plist                  # LSUIElement、最低系统等
ScribbyMacTests/
  AnnotationGeometryTests.swift
  AnnotationStoreTests.swift
  OverlayStateMachineTests.swift
  DrawingInteractionTests.swift
  MenuPresentationTests.swift
scripts/
  build-local-app.sh                    # Release 构建并复制到 dist/
docs/manual-test-checklist.md           # 手动 UI 验收记录
README.md                               # 构建、运行、快捷键和限制
```

---

### Task 1: 建立可测试、可运行的菜单栏应用工程

**Files:**
- Create: `ScribbyMac.xcodeproj/project.pbxproj`
- Create: `ScribbyMac.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- Create: `ScribbyMac.xcodeproj/xcshareddata/xcschemes/ScribbyMac.xcscheme`
- Create: `ScribbyMac/App/main.swift`
- Create: `ScribbyMac/App/AppDelegate.swift`
- Create: `ScribbyMac/Resources/Info.plist`
- Create: `ScribbyMac/Resources/Assets.xcassets/Contents.json`
- Create: `ScribbyMac/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `ScribbyMac/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `ScribbyMacTests/AppConfigurationTests.swift`

**Interfaces:**
- Produces: `final class AppDelegate: NSObject, NSApplicationDelegate`
- Produces: bundle identifier `com.local.ScribbyMac`, app target `ScribbyMac`, test target `ScribbyMacTests`, shared scheme `ScribbyMac`
- Produces: `enum AppConfiguration { static let minimumSystemMajor = 13; static let globalHotKeyDisplay = "⌘⇧D" }`

- [ ] **Step 1: 创建 Xcode 工程元数据和一个失败的配置测试**

  手工创建工程文件，设置：`MACOSX_DEPLOYMENT_TARGET = 13.0`、`ARCHS = arm64`、`SWIFT_VERSION = 6.0`、`GENERATE_INFOPLIST_FILE = NO`、`INFOPLIST_FILE = ScribbyMac/Resources/Info.plist`、`CODE_SIGN_STYLE = Automatic`。App target 链接 `AppKit.framework` 和 `Carbon.framework`；Test target 依赖 App target。

  测试先引用尚不存在的 `AppConfiguration`：

  ```swift
  import XCTest
  @testable import ScribbyMac

  final class AppConfigurationTests: XCTestCase {
      func testDefinesTheApprovedMinimumSystemAndHotKeyLabel() {
          XCTAssertEqual(AppConfiguration.minimumSystemMajor, 13)
          XCTAssertEqual(AppConfiguration.globalHotKeyDisplay, "⌘⇧D")
      }
  }
  ```

- [ ] **Step 2: 运行测试并确认因缺少 `AppConfiguration` 而失败**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  ```

  Expected: FAIL，编译器报告 `cannot find 'AppConfiguration' in scope`；工程本身可以被 `xcodebuild` 解析。

- [ ] **Step 3: 添加最小应用入口和配置**

  `AppDelegate.swift`：

  ```swift
  import AppKit

  enum AppConfiguration {
      static let minimumSystemMajor = 13
      static let globalHotKeyDisplay = "⌘⇧D"
  }

  final class AppDelegate: NSObject, NSApplicationDelegate {
      func applicationDidFinishLaunching(_ notification: Notification) {
          NSApp.setActivationPolicy(.accessory)
      }
  }
  ```

  `main.swift`：

  ```swift
  import AppKit

  let application = NSApplication.shared
  let appDelegate = AppDelegate()
  application.delegate = appDelegate
  application.run()
  ```

  `Info.plist` 必须包含 `LSUIElement = true`、`LSMultipleInstancesProhibited = true`、`CFBundleExecutable = $(EXECUTABLE_NAME)`、`CFBundleIdentifier = $(PRODUCT_BUNDLE_IDENTIFIER)`，且不包含任何隐私权限用途描述键。

- [ ] **Step 4: 验证单元测试、Debug 构建和 Info.plist**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  xcodebuild build -project ScribbyMac.xcodeproj -scheme ScribbyMac -configuration Debug -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  plutil -lint ScribbyMac/Resources/Info.plist
  ```

  Expected: 测试 PASS、构建成功、`plutil` 输出 `OK`，且构建日志无 warning。

- [ ] **Step 5: 提交工程骨架**

  ```bash
  git add ScribbyMac.xcodeproj ScribbyMac ScribbyMacTests/AppConfigurationTests.swift
  git commit -m "build: scaffold ScribbyMac application"
  ```

---

### Task 2: 实现不可变标注模型和几何计算

**Files:**
- Create: `ScribbyMac/Model/Annotation.swift`
- Create: `ScribbyMac/Drawing/AnnotationGeometry.swift`
- Create: `ScribbyMacTests/AnnotationGeometryTests.swift`
- Modify: `ScribbyMac.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `enum DrawingTool: CaseIterable { case arrow, rectangle, text }`
- Produces: `enum AnnotationColor: CaseIterable { case red, yellow, green, blue, white, black; var nsColor: NSColor { get } }`
- Produces: `enum StrokeWidth: CGFloat, CaseIterable { case thin = 2, medium = 4, thick = 8 }`
- Produces: `struct DrawingStyle: Equatable { let color: AnnotationColor; let strokeWidth: StrokeWidth }`
- Produces: `enum Annotation: Equatable { case arrow(ArrowAnnotation); case rectangle(RectangleAnnotation); case text(TextAnnotation) }`
- Produces: `AnnotationGeometry.normalizedRectangle(from:to:) -> CGRect?`
- Produces: `AnnotationGeometry.arrowHead(from:to:strokeWidth:) -> (left: CGPoint, right: CGPoint)?`

- [ ] **Step 1: 为矩形、箭头和样式写失败测试**

  覆盖四个行为：反向拖动标准化为同一个 `CGRect`；任一边小于 4 point 的矩形返回 `nil`；箭头长度小于 4 point 返回 `nil`；箭头尖两翼到终点距离相等且随线宽增加。

  ```swift
  func testNormalizesReverseRectangleDrag() {
      XCTAssertEqual(
          AnnotationGeometry.normalizedRectangle(
              from: CGPoint(x: 20, y: 30), to: CGPoint(x: 5, y: 10)
          ),
          CGRect(x: 5, y: 10, width: 15, height: 20)
      )
  }

  func testRejectsTooSmallArrow() {
      XCTAssertNil(AnnotationGeometry.arrowHead(
          from: .zero, to: CGPoint(x: 3, y: 0), strokeWidth: 4
      ))
  }
  ```

- [ ] **Step 2: 运行测试并确认缺失类型导致 RED**

  Run: `xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:ScribbyMacTests/AnnotationGeometryTests`

  Expected: FAIL，报告 `cannot find 'AnnotationGeometry' in scope`。

- [ ] **Step 3: 实现最小模型和纯几何函数**

  `ArrowAnnotation` 保存 `start/end/style`；`RectangleAnnotation` 保存标准化的 `rect/style`；`TextAnnotation` 保存 `origin/text/color/fontSize`，其中 `fontSize` 默认 24。几何常量为 `minimumShapeSize = 4`、箭头夹角 28°、箭头翼长 `max(10, strokeWidth * 4)`，并限制为主线长度的 45%，避免短箭头头部反超。

- [ ] **Step 4: 运行几何测试及全量测试**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:ScribbyMacTests/AnnotationGeometryTests
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  ```

  Expected: 全部 PASS，无 warning。

- [ ] **Step 5: 提交模型与几何计算**

  ```bash
  git add ScribbyMac/Model ScribbyMac/Drawing/AnnotationGeometry.swift ScribbyMacTests/AnnotationGeometryTests.swift ScribbyMac.xcodeproj/project.pbxproj
  git commit -m "feat: add annotation models and geometry"
  ```

---

### Task 3: 实现会话内标注存储和操作历史

**Files:**
- Create: `ScribbyMac/Model/AnnotationStore.swift`
- Create: `ScribbyMacTests/AnnotationStoreTests.swift`
- Modify: `ScribbyMac.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `@MainActor final class AnnotationStore`
- Produces: `private(set) var annotations: [Annotation]`
- Produces: `private(set) var selectedTool: DrawingTool`
- Produces: `private(set) var selectedColor: AnnotationColor`
- Produces: `private(set) var selectedStrokeWidth: StrokeWidth`
- Produces: `var hasAnnotations: Bool { get }`, `var canUndo: Bool { get }`
- Produces: `func add(_ annotation: Annotation)`, `func clear()`, `func undo()`
- Produces: `func select(tool:)`, `func select(color:)`, `func select(strokeWidth:)`
- Produces: `var onChange: (() -> Void)?`

- [ ] **Step 1: 写失败测试覆盖添加、撤销、清空恢复和运行期样式状态**

  ```swift
  @MainActor
  func testUndoAfterClearRestoresTheEntireSnapshot() {
      let store = AnnotationStore()
      let first = Annotation.rectangle(.fixture(rect: CGRect(x: 1, y: 2, width: 8, height: 9)))
      let second = Annotation.text(.fixture(text: "重点"))
      store.add(first)
      store.add(second)

      store.clear()
      XCTAssertTrue(store.annotations.isEmpty)
      store.undo()

      XCTAssertEqual(store.annotations, [first, second])
  }
  ```

  另测：空集合 `clear/undo` 不崩溃；添加三个标注后连续撤销按逆序移除；选择工具、颜色和线宽不进入撤销栈；`onChange` 每次标注数组变化只调用一次。

- [ ] **Step 2: 运行测试并确认因缺少 store 失败**

  Run: `xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:ScribbyMacTests/AnnotationStoreTests`

  Expected: FAIL，报告 `cannot find 'AnnotationStore' in scope`。

- [ ] **Step 3: 用内部命令栈实现最小 store**

  使用内部 `UndoEntry`：`.removeLast` 用于撤销一次添加，`.restore([Annotation])` 用于撤销清空。默认工具 `.arrow`、默认颜色 `.red`、默认线宽 `.medium`。不使用磁盘和 `UserDefaults`。

- [ ] **Step 4: 验证 store 与全量测试**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:ScribbyMacTests/AnnotationStoreTests
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  ```

  Expected: 全部 PASS。

- [ ] **Step 5: 提交标注存储**

  ```bash
  git add ScribbyMac/Model/AnnotationStore.swift ScribbyMacTests/AnnotationStoreTests.swift ScribbyMac.xcodeproj/project.pbxproj
  git commit -m "feat: add in-memory annotation history"
  ```

---

### Task 4: 实现覆盖状态机和绘图手势解释器

**Files:**
- Create: `ScribbyMac/Model/OverlayStateMachine.swift`
- Create: `ScribbyMac/Drawing/DrawingInteraction.swift`
- Create: `ScribbyMacTests/OverlayStateMachineTests.swift`
- Create: `ScribbyMacTests/DrawingInteractionTests.swift`
- Modify: `ScribbyMac.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `enum OverlayState: Equatable { case hidden, passThrough, drawing }`
- Produces: `enum OverlayEvent { case toggleDrawing(hasAnnotations: Bool), hide, show(hasAnnotations: Bool), cleared(hasAnnotations: Bool) }`
- Produces: `struct OverlayStateMachine { private(set) var state: OverlayState; mutating func handle(_ event: OverlayEvent) }`
- Produces: `enum DrawingDraft: Equatable { case arrow(start: CGPoint, current: CGPoint, style: DrawingStyle); case rectangle(start: CGPoint, current: CGPoint, style: DrawingStyle); case text(origin: CGPoint, style: DrawingStyle) }`
- Produces: `struct DrawingInteraction { mutating func begin(at:tool:style:); mutating func update(to:); mutating func finish(at:) -> Annotation?; mutating func commitText(_ text: String) -> Annotation?; mutating func cancel() }`

- [ ] **Step 1: 写失败的状态转换测试**

  覆盖：启动为 `hidden`；无标注退出绘图到 `hidden`；有标注退出到 `passThrough`；从隐藏进入绘图；隐藏/显示行为；非绘图状态清空后为 `hidden`；绘图状态清空后仍为 `drawing`。

- [ ] **Step 2: 写失败的手势测试**

  覆盖箭头和矩形的 begin/update/finish；短图形返回 `nil`；`text` 工具创建等待输入的文字草稿但不响应拖动；`commitText` trim 空白并拒绝空字符串；`cancel()` 同时清空图形和文字草稿；已提交标注使用 begin 时的样式，而不是后续更改的样式。

- [ ] **Step 3: 运行两组测试并确认 RED**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:ScribbyMacTests/OverlayStateMachineTests -only-testing:ScribbyMacTests/DrawingInteractionTests
  ```

  Expected: FAIL，分别报告缺少 `OverlayStateMachine` 和 `DrawingInteraction`。

- [ ] **Step 4: 实现纯 Swift 状态机和手势解释器**

  状态机必须是无 AppKit 窗口副作用的值类型。`DrawingInteraction.finish` 调用 Task 2 的几何函数并总是清空图形草稿；文字点击创建 `.text` 草稿，画布取得输入后调用 `commitText`，取消或退出则调用 `cancel`。

- [ ] **Step 5: 运行目标测试和全量测试**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:ScribbyMacTests/OverlayStateMachineTests -only-testing:ScribbyMacTests/DrawingInteractionTests
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  ```

  Expected: 全部 PASS。

- [ ] **Step 6: 提交状态和手势核心**

  ```bash
  git add ScribbyMac/Model/OverlayStateMachine.swift ScribbyMac/Drawing/DrawingInteraction.swift ScribbyMacTests/OverlayStateMachineTests.swift ScribbyMacTests/DrawingInteractionTests.swift ScribbyMac.xcodeproj/project.pbxproj
  git commit -m "feat: add overlay state and drawing interaction"
  ```

---

### Task 5: 实现画布渲染、预览和单行文字输入

**Files:**
- Create: `ScribbyMac/Drawing/DrawingCanvasView.swift`
- Create: `ScribbyMac/Drawing/AnnotationRenderer.swift`
- Create: `ScribbyMacTests/AnnotationRendererTests.swift`
- Modify: `ScribbyMac.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `AnnotationStore`, `DrawingInteraction`, `AnnotationGeometry`
- Produces: `enum AnnotationRenderer { static func path(for annotation: Annotation) -> CGPath? }`
- Produces: `@MainActor final class DrawingCanvasView: NSView, NSTextFieldDelegate`
- Produces: `func cancelPendingInteraction()`
- Produces: `var borderVisible: Bool`
- Produces: `var onAnnotationsChanged: (() -> Void)?`

- [ ] **Step 1: 写失败的 renderer 测试**

  对矩形断言 path bounding box 等于标注矩形；对箭头断言 path bounding box 同时包含起点、终点和两翼；文字返回 `nil`，因为文字由 attributed string 绘制。

- [ ] **Step 2: 运行测试并确认 RED**

  Run: `xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:ScribbyMacTests/AnnotationRendererTests`

  Expected: FAIL，报告缺少 `AnnotationRenderer`。

- [ ] **Step 3: 实现最小 renderer 和画布**

  `draw(_:)` 按 store 顺序绘制已提交标注，再绘制草稿，最后在 `borderVisible` 时用 3 point 红线绘制视图内边框。矩形无填充；路径设置 round line cap/join；文字使用 `NSFont.systemFont(ofSize: 24)` 和选中颜色。

  鼠标规则：箭头/矩形转发给 `DrawingInteraction`；文字工具单击时创建无边框、透明背景的单行 `NSTextField`。在 `control(_:textView:doCommandBy:)` 中分别处理 `insertNewline:` 和 `cancelOperation:`；提交前 trim whitespace/newline，空文本取消。切换工具、退出绘图和第二次文字点击都调用 `cancelPendingInteraction()`。

- [ ] **Step 4: 验证 renderer 测试、全量测试和 Debug 构建**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  xcodebuild build -project ScribbyMac.xcodeproj -scheme ScribbyMac -configuration Debug -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  ```

  Expected: 全部 PASS，构建无 warning。

- [ ] **Step 5: 提交画布**

  ```bash
  git add ScribbyMac/Drawing ScribbyMacTests/AnnotationRendererTests.swift ScribbyMac.xcodeproj/project.pbxproj
  git commit -m "feat: render and edit screen annotations"
  ```

---

### Task 6: 实现透明覆盖窗口、工具栏及菜单展示状态

**Files:**
- Create: `ScribbyMac/Overlay/OverlayWindow.swift`
- Create: `ScribbyMac/Overlay/OverlayController.swift`
- Create: `ScribbyMac/Toolbar/ToolbarPanelController.swift`
- Create: `ScribbyMac/Menu/MenuPresentation.swift`
- Create: `ScribbyMac/Menu/StatusMenuController.swift`
- Create: `ScribbyMacTests/MenuPresentationTests.swift`
- Modify: `ScribbyMac.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `OverlayStateMachine`, `AnnotationStore`, `DrawingCanvasView`
- Produces: `struct MenuPresentation: Equatable { let drawingTitle: String; let visibilityTitle: String; let canToggleVisibility: Bool; let canClear: Bool }`
- Produces: `MenuPresentation.make(state:hasAnnotations:)`
- Produces: `@MainActor final class OverlayController`
- Produces: `func toggleDrawing()`, `func hideAnnotations()`, `func showAnnotations()`, `func clearAnnotations()`, `func undo()`
- Produces: `@MainActor final class ToolbarPanelController`, `@MainActor final class StatusMenuController`

- [ ] **Step 1: 写失败的菜单展示测试**

  覆盖：`drawing` 显示“结束绘图”；其他状态显示“开始绘图”；`passThrough` 显示“隐藏标注”；`hidden` 且有标注显示“显示标注”；无标注时可见性和清空均禁用。

- [ ] **Step 2: 运行测试并确认 RED**

  Run: `xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:ScribbyMacTests/MenuPresentationTests`

  Expected: FAIL，报告缺少 `MenuPresentation`。

- [ ] **Step 3: 实现菜单展示值和覆盖窗口**

  `OverlayWindow` 使用 `.borderless`，设置 `isOpaque = false`、`backgroundColor = .clear`、`hasShadow = false`、`level = .floating`、`collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`。每次进入绘图前读取 `NSScreen.main?.frame`；无主显示器时写入 OSLog 并保持 `hidden`。

- [ ] **Step 4: 实现顶部固定工具栏和菜单栏**

  工具栏用非激活式 `NSPanel`，顶部居中并留 12 point 间距，使用 SF Symbols 表示箭头、矩形、文字、撤销、清空和完成。颜色显示六个圆形 swatch，线宽显示 2/4/8；当前选项具备明确选中态。菜单栏使用 `NSStatusItem.variableLength` 和模板图标，不加载网络资源。

- [ ] **Step 5: 实现状态副作用映射**

  - `drawing`：window order front、`ignoresMouseEvents = false`、canvas border visible、toolbar shown。
  - `passThrough`：window order front、`ignoresMouseEvents = true`、canvas border hidden、toolbar hidden。
  - `hidden`：toolbar hidden、overlay order out。

  `toggleDrawing` 退出前调用 `canvas.cancelPendingInteraction()`；清空后驱动 `.cleared(hasAnnotations: false)`；store `onChange` 同步重绘和菜单可用状态。

- [ ] **Step 6: 运行测试和构建**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  xcodebuild build -project ScribbyMac.xcodeproj -scheme ScribbyMac -configuration Debug -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  ```

  Expected: 全部 PASS，构建无 warning。

- [ ] **Step 7: 提交窗口和控制界面**

  ```bash
  git add ScribbyMac/Overlay ScribbyMac/Toolbar ScribbyMac/Menu ScribbyMacTests/MenuPresentationTests.swift ScribbyMac.xcodeproj/project.pbxproj
  git commit -m "feat: add overlay toolbar and status menu"
  ```

---

### Task 7: 接入全局热键、应用组装和焦点恢复

**Files:**
- Create: `ScribbyMac/HotKey/GlobalHotKeyController.swift`
- Modify: `ScribbyMac/App/AppDelegate.swift`
- Modify: `ScribbyMac.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `enum GlobalHotKeyError: LocalizedError { case registrationFailed(OSStatus) }`
- Produces: `final class GlobalHotKeyController { init(handler: @escaping () -> Void); func register() throws; func unregister() }`
- Consumes: `OverlayController`, `StatusMenuController`

- [ ] **Step 1: 写一个仅验证纯配置映射的失败测试**

  在 `AppConfigurationTests` 添加：

  ```swift
  func testHotKeyUsesCommandShiftD() {
      XCTAssertEqual(AppConfiguration.hotKeyKeyCode, UInt32(kVK_ANSI_D))
      XCTAssertEqual(AppConfiguration.hotKeyModifiers, UInt32(cmdKey | shiftKey))
  }
  ```

- [ ] **Step 2: 运行测试并确认缺少热键配置导致 RED**

  Run: `xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO -only-testing:ScribbyMacTests/AppConfigurationTests`

  Expected: FAIL，报告 `AppConfiguration` 没有 `hotKeyKeyCode` 或 `hotKeyModifiers`。

- [ ] **Step 3: 实现 Carbon 热键注册**

  使用固定 four-character signature 和 id，通过 `InstallEventHandler` 接收 `kEventHotKeyPressed`，通过 `RegisterEventHotKey` 注册 `kVK_ANSI_D` + `cmdKey | shiftKey`。`deinit` 或应用终止时调用 `UnregisterEventHotKey` 和 `RemoveEventHandler`。任何非 `noErr` 结果转成 `GlobalHotKeyError.registrationFailed(status)`。

- [ ] **Step 4: 在 `AppDelegate` 组装完整应用**

  创建唯一的 store、overlay、toolbar、status menu 和 hotkey controller。进入绘图前保存 `NSWorkspace.shared.frontmostApplication`；退出绘图后用 `activate(options: [])` 恢复。热键注册失败时使用 `NSAlert` 显示错误与“仍可从菜单栏开始绘图”的说明，应用继续运行。

- [ ] **Step 5: 验证测试、Debug 构建和静态权限检查**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  xcodebuild build -project ScribbyMac.xcodeproj -scheme ScribbyMac -configuration Debug -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  rg 'NSScreenCaptureUsageDescription|NSAccessibility|AXIsProcessTrusted|URLSession|SMAppService' ScribbyMac ScribbyMac.xcodeproj
  ```

  Expected: 测试 PASS、构建无 warning；`rg` 没有匹配结果。

- [ ] **Step 6: 提交热键与组装**

  ```bash
  git add ScribbyMac/HotKey ScribbyMac/App/AppDelegate.swift ScribbyMacTests/AppConfigurationTests.swift ScribbyMac.xcodeproj/project.pbxproj
  git commit -m "feat: wire global hotkey and application lifecycle"
  ```

---

### Task 8: Release 产物、文档和完整验收

**Files:**
- Create: `scripts/build-local-app.sh`
- Create: `docs/manual-test-checklist.md`
- Create: `README.md`
- Modify: `.gitignore`

**Interfaces:**
- Produces: `scripts/build-local-app.sh`，无参数执行后创建 `dist/ScribbyMac.app`
- Produces: 手动验收记录模板，逐项记录 macOS 版本、设备、结果和备注

- [ ] **Step 1: 先运行尚不存在的产物脚本并确认失败**

  Run: `bash scripts/build-local-app.sh`

  Expected: FAIL，shell 报告文件不存在。

- [ ] **Step 2: 实现确定性的本地 Release 构建脚本**

  脚本使用 `set -euo pipefail`，执行：

  ```bash
  xcodebuild \
    -project ScribbyMac.xcodeproj \
    -scheme ScribbyMac \
    -configuration Release \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath "$PROJECT_ROOT/build/DerivedData" \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    build
  ditto "$PROJECT_ROOT/build/DerivedData/Build/Products/Release/ScribbyMac.app" \
        "$PROJECT_ROOT/dist/ScribbyMac.app"
  codesign --force --deep --sign - "$PROJECT_ROOT/dist/ScribbyMac.app"
  ```

  `PROJECT_ROOT` 必须由脚本自身路径解析，不依赖调用者当前目录。`.gitignore` 加入 `/build/` 和 `/dist/`，但交付时仍在工作区保留 `dist/ScribbyMac.app` 供用户双击。

- [ ] **Step 3: 编写 README 与手动验收清单**

  README 明确：系统要求、Xcode 构建命令、快捷键、三种工具、六色三线宽、菜单命令、数据不保存、只支持主显示器、全屏游戏不保证，以及首次打开本地 ad-hoc 应用时可能出现的 Gatekeeper 操作说明。

  `docs/manual-test-checklist.md` 按规格第 11.2 节列出 14 项，每项具有 `PASS/FAIL/BLOCKED`、证据和备注栏，不预先标记成功。

- [ ] **Step 4: 执行完整自动化与 Release 验证**

  Run:

  ```bash
  xcodebuild test -project ScribbyMac.xcodeproj -scheme ScribbyMac -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
  bash scripts/build-local-app.sh
  file dist/ScribbyMac.app/Contents/MacOS/ScribbyMac
  plutil -p dist/ScribbyMac.app/Contents/Info.plist
  codesign --verify --deep --strict --verbose=2 dist/ScribbyMac.app
  rg 'NSScreenCaptureUsageDescription|NSMicrophoneUsageDescription|NSCameraUsageDescription|NSLocation|NSContactsUsageDescription' dist/ScribbyMac.app/Contents/Info.plist
  ```

  Expected: 测试 PASS；Release 构建无 warning；`file` 包含 `Mach-O 64-bit executable arm64`；`Info.plist` 包含 `LSUIElement = 1` 和 minimum system 13.0；签名验证成功；隐私用途键搜索无结果。

- [ ] **Step 5: 启动应用并执行手动 UI 验收**

  Run: `open dist/ScribbyMac.app`

  按 `docs/manual-test-checklist.md` 逐项验证菜单栏、无 Dock 图标、热键、箭头、反向矩形、单行文字、颜色、线宽、撤销清空、穿透、隐藏恢复、普通应用和至少一个标准全屏应用。把实际结果写入清单；任何失败先按 `superpowers:systematic-debugging` 定位并修复，再重新执行受影响项。

- [ ] **Step 6: 请求代码审查并修复高优先级问题**

  使用 `superpowers:requesting-code-review` 对照规格、计划、测试和手动验收记录检查。修复所有 P0/P1/P2 问题，并重新运行受影响测试与完整 Release 构建。

- [ ] **Step 7: 提交交付脚本与文档**

  ```bash
  git add .gitignore scripts/build-local-app.sh docs/manual-test-checklist.md README.md
  git commit -m "docs: add build and acceptance workflow"
  ```

- [ ] **Step 8: 最终验证工作区和提交历史**

  Run:

  ```bash
  git status --short
  git log --oneline --decorate -10
  ```

  Expected: 仅原始 `iScribby-Setup-v0.0.11.exe` 保持未跟踪；没有遗漏的源码或文档改动。交付链接指向 `dist/ScribbyMac.app`、`ScribbyMac.xcodeproj`、`README.md` 和手动验收记录。

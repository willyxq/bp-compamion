# 轻松血压 (Easy BP)

一款帮助高血压病人**记录血压、统计分析、规划日常生活并提醒**的 Flutter 手机 App。
数据全部保存在本地（隐私优先），无需联网与账号。

## 功能

### 🏠 首页 Dashboard
- 最新血压大卡片，依据《中国高血压防治指南》自动分级，颜色随风险变化并给出温和建议。
- 今日计划进度条与待办清单，可一键勾选完成。
- 近 7 天血压趋势缩略折线图。

### 📝 记录
- 录入收缩压 / 舒张压 / 心率 / 时间 / 测量场景（晨起·睡前·服药前后）/ 备注。
- 录入时实时预览血压分级。
- 历史记录按「今天 / 昨天 / 日期」分组，左滑删除。

### 📊 统计
- 时间范围切换：7 / 30 / 90 天。
- 平均血压、达标率。
- 收缩压 / 舒张压双线趋势图（带日期轴）。
- 按分级（正常 / 正常高值 / 1~3 级 / 偏低）统计分布占比。
- **导出健康报告 PDF**：一键生成多页 A4 报告（概览 + 分级分布 + 测量明细表），
  通过系统分享面板可**保存到文件、转发（信息/微信/AirDrop）、打印**。
  中文使用 Noto Sans SC 字体（首次生成需联网下载并本地缓存）。

### 🗓 规划与提醒
- 服药、测量、饮食、运动、作息等计划/提醒，可设定时间、开关、左滑删除。
- 每日完成情况追踪。
- 健康小贴士。

## 技术栈

| 用途 | 选型 |
|---|---|
| UI 框架 | Flutter (Material 3) |
| 状态管理 | provider (`ChangeNotifier`) |
| 本地存储 | shared_preferences（JSON 序列化） |
| 图表 | fl_chart |
| 日期 | intl |

## 目录结构

```
lib/
├── main.dart                     # 入口，注入 AppState
├── theme.dart                    # Material 3 主题
├── models/
│   ├── bp_record.dart            # 血压记录模型 + 测量场景
│   ├── bp_classification.dart    # 血压分级算法与颜色/建议
│   └── plan_task.dart            # 计划/提醒模型
├── services/
│   └── storage.dart              # shared_preferences 持久化
├── state/
│   └── app_state.dart            # 全局状态 + 统计逻辑 + 演示数据
└── screens/
    ├── root_scaffold.dart        # 底部导航
    ├── home_screen.dart          # 首页
    ├── records_screen.dart       # 记录列表
    ├── stats_screen.dart         # 统计
    ├── plan_screen.dart          # 规划
    └── add_record_sheet.dart     # 新增血压底部弹窗
```

## 运行

```bash
flutter pub get

# iOS 模拟器
flutter run -d <ios-simulator-id>

# Android
flutter run -d <android-device>

# Web（注意：Web CanvasKit 渲染器在离线环境可能缺少中文字体回退，真机/模拟器正常）
flutter run -d chrome
```

> 小技巧：`--dart-define=INITIAL_TAB=2` 可直接进入指定 Tab（0 首页 / 1 记录 / 2 统计 / 3 规划），用于深链或演示。

## 桌面小组件（iOS / Android）

在**不打开 App** 的情况下快速记录血压：

| 平台 | 交互方式 | 最低系统 |
|---|---|---|
| **iOS** | 添加「轻松血压」小组件 → 点「记录血压」→ 系统弹出收缩压/舒张压/心率输入框（App Intent） | iOS 17+ |
| **Android** | 添加桌面小组件 → 用 +/- 调整数值 → 点「保存」 | Android 5+ |

小组件与 App 通过 **App Group / 共享存储** 同步记录；回到 App 或从后台恢复时会自动合并数据。

### 添加小组件

- **iPhone**：长按主屏幕 → 「+」→ 搜索「轻松血压」→ 添加小组件
- **Android**：长按主屏幕 → 「小组件」→ 选择「轻松血压」

### 云端 / Linux 验证小组件 UI

无法在 Linux 上运行 iOS 模拟器或真机 WidgetKit，可用 Flutter 预览页对照设计：

```bash
flutter run -d chrome --dart-define=SHOW_WIDGET_PREVIEW=true
flutter test test/bp_widget_preview_test.dart
```

## 测试

```bash
flutter test       # 含血压分级逻辑单元测试
flutter analyze
```

## 发布到 App Store

详见 [PUBLISHING.md](PUBLISHING.md)：从 Apple 开发者账号、签名、归档上传，到
TestFlight 邀请朋友试用，再到提交审核正式发布的完整步骤。

## 路线图（后续可扩展）

- 接入 `flutter_local_notifications` 实现系统级定时提醒（当前为应用内计划/勾选）。
- ~~数据导出 PDF~~ ✅ 已支持（健康报告 PDF）；可进一步增加 CSV 导出。
- 多用户/家庭成员档案。
- 与蓝牙血压计、健康平台（HealthKit / Google Fit）对接。

## 免责声明

本应用提供的分级与建议仅供健康管理参考，**不能替代专业医疗诊断与治疗**。如有不适请及时就医。

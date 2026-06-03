# 「轻松血压」发布到 App Store 指南

从 0 到上架，分三个阶段：**准备账号与工程 → TestFlight 邀请朋友试用 → 提交审核正式发布**。

---

## 阶段 0：前置条件

| 项目 | 说明 |
|---|---|
| Mac + Xcode | 必须用 macOS，安装最新 Xcode（已具备）。 |
| Apple 开发者账号 | 注册 [Apple Developer Program](https://developer.apple.com/programs/)，**个人/公司 99 美元/年**。审核 1~2 天。 |
| Apple ID | 用于登录 App Store Connect。 |
| 隐私政策网页 | App Store 要求提供一个可公开访问的隐私政策 URL（医疗/健康类必需）。可用 GitHub Pages、Notion 公开页等免费托管。 |

> 本 App 数据全部存在本地、不上传服务器，隐私政策可写明「数据仅保存在本机，不收集、不上传」。

---

## 阶段 1：配置 Xcode 工程

### 1.1 Bundle Identifier（已设为 `com.bpcompanion.bpCompanion`）
建议改成你自己的反向域名（全局唯一），例如 `com.yourname.easybp`：

```bash
# 用 Xcode 打开
open ios/Runner.xcworkspace
```
在 Xcode → `Runner` target → **Signing & Capabilities**：
- **Team**：选择你的开发者账号团队。
- **Bundle Identifier**：填唯一 ID（与 App Store Connect 一致）。
- 勾选 **Automatically manage signing**（最省心，Xcode 自动生成证书与描述文件）。

### 1.2 版本号
`pubspec.yaml` 里 `version: 1.0.0+1`：
- `1.0.0` = 展示版本（CFBundleShortVersionString）
- `+1` = 构建号（CFBundleVersion）；**每次上传必须递增**构建号。

### 1.3 显示名称与图标
- 名称「轻松血压」已配置（`ios/Runner/Info.plist` 的 `CFBundleDisplayName`）。
- 图标已通过 `flutter_launcher_icons` 生成。如需更换：替换 `assets/icon/app_icon.png` 后执行
  `dart run flutter_launcher_icons`。

### 1.4 隐私用途声明（重要）
本 App 当前未用相机/定位/通知；若后续加入「系统提醒（本地通知）」，需在 `Info.plist` 增加
相应权限说明，并在代码请求通知授权。健康类 App 若接入 HealthKit 还需额外声明
`NSHealthShareUsageDescription` 等。

---

## 阶段 2：构建并上传

### 2.1 命令行归档（推荐）

```bash
flutter clean
flutter pub get
flutter build ipa --release
```
产物在 `build/ios/ipa/*.ipa`。

### 2.2 上传到 App Store Connect

任选其一：

**方式 A — Transporter（最简单）**
1. Mac App Store 安装 **Transporter** App。
2. 用 Apple ID 登录，拖入 `build/ios/ipa/轻松血压.ipa`，点 **Deliver**。

**方式 B — 命令行**
```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
# 或用 App 专用密码：--username <你的AppleID> --password <app-specific-password>
```

**方式 C — Xcode**
Xcode → `Product` → `Archive` → `Distribute App` → `App Store Connect` → `Upload`。

> 首次上传后，构建包需在 App Store Connect「处理」几分钟到半小时。

---

## 阶段 3：在 App Store Connect 建立 App 记录

登录 [App Store Connect](https://appstoreconnect.apple.com) → **我的 App** → **+** 新建：
- 平台 iOS；名称「轻松血压」（名称全局唯一，被占用则换名）；主要语言 简体中文；
- Bundle ID 选 2.1 中的 ID；SKU 任意唯一字符串。

需要填写的元数据：
- **App 截图**：至少提供 6.7"（iPhone 15/16/17 Pro Max）一组截图。可直接用模拟器
  对四个页面截图（首页/记录/统计/规划）。
- **App 描述、关键词、宣传文本**。
- **隐私政策 URL**（必填）。
- **App 隐私（App Privacy）**：如实勾选「不收集数据」。
- **年龄分级**：医疗/健康信息相关，按问卷如实填写。
- **类别**：建议「医疗」或「健康健美」。

---

## 阶段 4：TestFlight —— 邀请你和朋友试用

构建包处理完成后，进入 App 的 **TestFlight** 标签：

### 4.1 内部测试（最快，无需审核）
- 适合你自己和团队成员（需是 App Store Connect 同账号下的「用户」，最多 100 人）。
- 在「内部测试」新建测试组 → 选择构建版本 → 添加测试员（他们的 Apple ID 邮箱）。
- 测试员收到邮件 → 安装 **TestFlight** App → 接受邀请即可安装试用。**几乎即时生效**。

### 4.2 外部测试（朋友试用，最多 10000 人）
- 适合普通朋友（任意 Apple ID）。
- 新建「外部测试组」→ 添加构建 → **首次需通过 Apple 的 Beta 审核**（通常几小时到 1 天）。
- 可生成**公开链接（Public Link）**，把链接发给朋友，他们点开即可加入试用。
- 每个构建的测试有效期 90 天。

> 建议路径：先用「内部测试」自己验证，再开「外部测试公开链接」发给朋友。

---

## 阶段 5：提交审核 → 正式发布给所有人

1. 在 App 的 **「App Store」标签**（不是 TestFlight）选择要发布的构建版本。
2. 确认所有元数据、截图、隐私政策齐全。
3. 点 **「提交以供审核」**。
4. Apple 审核通常 **24~48 小时**。通过后可选择：
   - **自动发布**：审核通过即上架；
   - **手动发布**：你点击后才上架；
   - **分阶段发布**：按比例逐步放量。

---

## 医疗/健康类 App 审核注意事项（重点）

Apple 对健康类 App 审核较严格，提前规避被拒：

1. **明确免责声明**：App 内与商店描述都需说明「仅供健康管理参考，不能替代专业医疗诊断/治疗」。本 App 各处已包含此声明。
2. **不得宣称诊断/治疗疾病**：描述用「记录、统计、提醒、管理」等词，避免「诊断高血压」「治疗」等。
3. **数据准确性与来源**：血压分级标准注明依据《中国高血压防治指南》。
4. **隐私**：如实声明数据仅存本地、不上传。若将来上云需提供数据安全说明。
5. 若加入「用药提醒」，避免推荐具体药物剂量；提醒内容由用户自行填写。

---

## 常见命令速查

```bash
# 升级构建号后重新打包上传
# 1) 改 pubspec.yaml: version: 1.0.0+2
flutter build ipa --release
# 2) Transporter 上传新包，或：
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios --apiKey ... --apiIssuer ...

# 生成各平台图标
dart run flutter_launcher_icons

# 真机调试（连接 iPhone 并信任）
flutter devices
flutter run -d <iPhone设备ID> --release
```

---

## Android（可选，发布到 Google Play）
本工程已配置 Android。若要上 Google Play：注册 Google Play 开发者账号（一次性 25 美元）→
`flutter build appbundle --release`（需配置签名 keystore）→ 上传 `.aab` 到 Play Console →
内部测试/封闭测试邀请朋友 → 提交审核发布。

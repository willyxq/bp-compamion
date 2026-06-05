# App Store Connect 上架文案（轻松血压）

> 直接复制到 App Store Connect 对应字段。URL 基于 GitHub Pages 仓库
> `willyxq/bp-compamion`，请先按本文件末尾「GitHub Pages 部署」启用 Pages。

---

## Promotional Text（促销文本，≤170 字）

```
全新「轻松血压」上线！随手记录血压、自动判定分级、查看趋势统计，还能一键导出 PDF 健康报告，保存、转发、打印给医生更方便。数据全程仅存本机，隐私无忧。
```

## Description（描述）

```
「轻松血压」是一款为高血压人群打造的血压管理工具，专注「记得住、看得懂、坚持得了」，帮你把日常血压管理变简单。

【快速记录】
几秒钟记录一次血压：收缩压、舒张压、心率，可标注晨起 / 睡前 / 服药前后等测量场景，并添加备注。录入即时显示血压分级。

【统计分析】
· 7 / 30 / 90 天可切换的收缩压、舒张压双线趋势图
· 平均血压、达标率、心率等关键指标一目了然
· 依据《中国高血压防治指南》自动分级（正常 / 正常高值 / 1~3 级 / 偏低），用颜色直观区分

【日常规划与提醒】
为服药、测量、低盐饮食、运动、规律作息等设置每日计划，逐项勾选打卡，养成健康习惯。

【一键健康报告】
导出多页 PDF 健康报告，包含数据概览、分级分布与测量明细，可保存到文件、转发或打印，就诊时给医生看更清晰。

【隐私优先】
所有数据仅保存在你的设备本地，不上传、不收集、无广告、无追踪，安心使用。

【清爽易用】
大字号、色彩分级的简洁界面，长辈也能轻松上手。

———
健康提示：本应用提供的记录、统计与分级仅供健康管理参考，不能替代专业医疗诊断与治疗。如有不适，请及时就医。
```

## Keywords（关键词，≤100 字符，英文逗号分隔）

```
血压,高血压,血压记录,血压管理,血压监测,血压计,心率,降压,用药提醒,健康管理,慢病,测血压,血压趋势,健康报告
```

## Support URL（支持网址）

```
https://willyxq.github.io/bp-compamion/support.html
```

## Marketing URL（营销网址）

```
https://willyxq.github.io/bp-compamion/
```

## Copyright（版权）

```
2026 Bangguo Xiong
```

## Privacy Policy URL（隐私政策网址）

```
https://willyxq.github.io/bp-compamion/privacy.html
```

---

## GitHub Pages 部署步骤

网站源文件已放在本仓库 `docs/` 目录（`index.html` / `privacy.html` / `support.html`）。

1. 推送代码到远程仓库：
   ```bash
   git remote add origin https://github.com/willyxq/bp-compamion.git
   git push -u origin main
   ```
2. 打开仓库 **Settings → Pages**：
   - **Source** 选择 `Deploy from a branch`
   - **Branch** 选择 `main`，目录选择 `/docs`，点击 **Save**
3. 等待 1~2 分钟，Pages 会发布到：
   - 营销主页：`https://willyxq.github.io/bp-compamion/`
   - 隐私政策：`https://willyxq.github.io/bp-compamion/privacy.html`
   - 支持页面：`https://willyxq.github.io/bp-compamion/support.html`

> 注意：以上 URL 中的仓库名为 `bp-compamion`（与你提供的远程地址一致）。
> 若今后把仓库改名为 `bp-companion`，记得同步更新这些链接。

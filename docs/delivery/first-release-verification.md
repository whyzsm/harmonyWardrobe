# 衣不缺首版交付验证

## 范围

本记录覆盖 `衣不缺` 个人衣橱改版：主导航、衣橱二级 tab、逛店记录、我的个人信息、视觉 token 和旧主入口清理。

本轮重设计采用多 agent 审计：设计审计确认信息架构保留 `衣橱 / + / 逛店`，代码审查确认未提交的 demo 增强页不接真实 runtime，因此不纳入交付；最终只整合真实业务壳层上的导航选中指示、快捷面板大行入口、轻量按压反馈、衣物卡片可识别信息和中文化状态文案。

本轮 UX Researcher 细化基于合成研究，不等同真实访谈；结论是优先提升“我有什么、下一步做什么、保存是否成功”的可见性，因此补充了衣橱/逛店数量摘要、个人信息行内校验、保存成功反馈和更具体的空态说明。

## 本地验证

已执行以下命令作为交付门禁：

```bash
for script in scripts/validate-*.mjs; do node "$script" || exit 1; done
git diff --check
```

期望结果：

- 所有验证脚本通过。
- 没有尾随空白或 patch 格式问题。

实际结果：

- 2026-07-04 已通过全部 `scripts/validate-*.mjs`。
- 2026-07-04 已通过 `git diff --check`。

## 构建验证

已执行 entry HAP 构建：

```bash
/Users/seminzhu/Downloads/command-line-tools/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
```

实际结果：`BUILD SUCCESSFUL`。构建过程提示 `No signingConfig found for product default`，这是当前本地调试构建的预期状态；真实设备安装与签名发布验证需要在配置签名材料后补跑。

## 手工 QA

手工 QA 脚本位于 `docs/qa/manual-test-script.md`，覆盖：

- 顶部 `logo + 衣不缺` 和 `我的` 入口。
- 底部 `衣橱 / + / 逛店` 主导航。
- `拍衣服`、`拍搭配`、`拍店铺` 大行入口。
- `衣裤 / 美搭` tab 切换。
- 衣物、美搭、逛店记录新增和回显。
- 身高、体重、腰围保存和回显。
- 个人信息非法输入提示和保存成功反馈。
- 衣橱/逛店数量摘要与搜索结果数量反馈。
- 黑色胶囊主按钮、圆角图片和大圆角卡片。
- 衣物卡片显示名称和分类，加载/错误/搜索等文案中文化。

## 已知限制

- 旧 wishlist 表和兼容代码保留，但不作为主入口暴露。
- 第一版 `拍衣服 / 拍搭配 / 拍店铺` 可复用系统图片选择器，不强制接入真机相机权限。
- 未新增网络权限或远端同步能力。

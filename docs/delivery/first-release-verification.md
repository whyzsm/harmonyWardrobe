# 衣不缺首版交付验证

## 范围

本记录覆盖 `衣不缺` 个人衣橱改版：主导航、衣橱二级 tab、逛店记录、我的个人信息、视觉 token 和旧主入口清理。

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
- `拍衣服`、`拍搭配`、`拍店铺`。
- `衣裤 / 美搭` tab 切换。
- 衣物、美搭、逛店记录新增和回显。
- 身高、体重、腰围保存和回显。
- 黑色胶囊主按钮、圆角图片和大圆角卡片。

## 已知限制

- 旧 wishlist 表和兼容代码保留，但不作为主入口暴露。
- 第一版 `拍衣服 / 拍搭配 / 拍店铺` 可复用系统图片选择器，不强制接入真机相机权限。
- 未新增网络权限或远端同步能力。

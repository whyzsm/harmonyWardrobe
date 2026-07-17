# 2026-07-17 未改项与提交说明

## 本轮已完成

- 顶层 route/page 分支已统一增加轻量 `TransitionEffect.OPACITY` 页面转场。
- 本地未跟踪的旧 UI 死代码文件已移除：`ClothingCard.ets`、`OutfitCard.ets`、`StoreVisitCard.ets`。
- 相关验证脚本已从“维护旧组件内容”调整为“禁止旧组件/孤儿页回归”。
- 日期选择器策略已明确：购买日期、逛店日期、穿着日期均不允许选择未来日期。
- 交互验证脚本已覆盖页面转场、日期策略和卡片 pressed feedback，并反向禁止已移除的旧导航概念回流。

## 没有改的地方

| 项目 | 没有改的内容 | 原因 / 处理方式 |
| --- | --- | --- |
| 本机签名 | 没有修改、没有提交 `build-profile.json5` | 该文件包含本机 `signingConfigs`，按要求保留在本机工作区，不纳入代码提交 |
| DevEco SDK 环境 | 没有修改本机 SDK 安装和 `DEVECO_SDK_HOME` | 当前 HAP 构建失败点是 `SDK component missing`，属于本机环境问题，不属于仓库代码改动 |
| 历史计划文档 | 没有批量改写历史实施方案 | `docs/plans` 中的旧方案保留历史上下文；当前产品口径以 README、architecture、design 和验证脚本为准 |
| 业务模型 / 数据库 | 没有新增网络同步、后端依赖、权限、数据库表或远程能力 | 当前范围只处理 UI 交互、死代码清理和验证脚本，不扩大产品边界 |
| 日期手输能力 | 没有恢复日期字段的手动输入 | 当前统一为系统日期选择器，并通过 `end: new Date()` 固化“不允许未来日期”策略 |
| 真机截图验收 | 没有补设备截图 | 当前本机 SDK 组件缺失，无法完成构建和设备安装截图；待 SDK 环境修复后执行 |

## 验证结果

已通过：

```bash
git diff --check
```

已通过，跳过本机签名检查：

```bash
fail=0
for script in scripts/*.mjs; do
  if [ "$(basename "$script")" = "validate-project-structure.mjs" ]; then
    echo "SKIP local signing check: $script"
    continue
  fi
  node "$script" || fail=$((fail + 1))
done
exit "$fail"
```

单独运行 `scripts/validate-project-structure.mjs` 仍会失败，原因是本机 `build-profile.json5` 中存在 `signingConfigs`。该项是本机签名配置，不应随本轮代码提交。

HAP 构建未通过，失败原因是本机 DevEco SDK 组件缺失：

```text
00303168 Configuration Error
Error Message: SDK component missing.
```

## 提交注意

- 提交时应排除 `build-profile.json5`。
- 推送目标为两个真实远端：`origin` 和 `github`。
- `both` 是本仓库内的本地聚合 remote，不作为本次“两端远端仓库”目标。

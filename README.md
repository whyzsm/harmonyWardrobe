# 衣不缺（Harmony Wardrobe）

`衣不缺` 是一个本地优先、图片优先的 HarmonyOS Stage 衣柜应用。它用于管理衣物、穿搭/美搭、穿着记录、逛店记录、心愿清单和统一搜索。

项目工程名保留为 `harmony-wardrobe`，应用包名为 `io.wardrobe.tiny`。产品体验方向以 `衣不缺` 为准：白底、浅灰表面、黑色交互、真实照片优先，不做社交推荐流，不展示不存在的远程同步能力。

## 技术栈

- 代码语言：HarmonyOS 原生（ArkTS + ArkUI）。
- 应用模型：HarmonyOS Stage 模型，入口模块为 `entry`。
- 本地存储：SQLite 业务表 + 应用本地媒体文件。
- 构建工具：Hvigor 与 DevEco Studio command-line-tools。
- 网络依赖：无后端服务，无远程同步依赖。

## 产品边界

- 本地优先：业务数据存入本机 SQLite。
- 图片优先：照片由媒体层复制到应用本地存储，SQLite 只保存本地 URI/path。
- 离线可用：当前应用不依赖网络服务，不应新增网络权限。
- 数据真实：页面只能展示用户本地记录，不虚构作者、点赞、评论、同步状态或远端数据。
- 安静工具感：主流程服务于“记录、整理、查找、回看”，避免社交化和运营化表达。

## 核心功能

- 衣柜：记录衣物照片、名称、分类、备注、购买信息，支持列表、搜索、详情、编辑和删除。
- 穿搭/美搭：记录穿搭照片和关联衣物，支持本地自定义分类筛选、创建、编辑和删除；未分类穿搭保留在“全部”中。
- 逛店：记录店铺、商圈/地址、试穿备注、状态和图片，支持搜索、筛选、编辑和删除。
- 穿着记录：在穿搭页记录或编辑一次穿着，可关联穿搭并保留本地照片与备注。
- 我的：维护本地身形信息、偏好、隐私设置，并进入心愿清单。
- 心愿清单：记录想买的单品、门店、价格、备注和照片。
- 统一搜索：衣物、穿搭、逛店、店铺、心愿等内容进入可重建的搜索索引。

## 目录结构

```text
.
├── AppScope/                         # 应用级配置
├── entry/                            # HarmonyOS entry 模块
│   └── src/main/
│       ├── ets/
│       │   ├── app/                  # 应用 runtime 组装
│       │   ├── components/           # 可复用 ArkUI 组件
│       │   ├── data/                 # SQLite、迁移、仓储、搜索索引
│       │   ├── domain/               # 领域模型与业务规则
│       │   ├── entryability/         # EntryAbility
│       │   ├── media/                # 选图、拍照、本地媒体复制与清理
│       │   ├── pages/                # 页面组合、导航、用户输入与状态展示
│       │   ├── theme/                # 衣不缺视觉 token
│       │   └── utils/                # 轻量共享工具
│       ├── module.json5              # entry 模块元数据
│       └── resources/                # 资源文件
├── docs/
│   ├── architecture.md               # 架构说明
│   ├── background/yibuque-design.md  # 衣不缺设计规范
│   ├── delivery/                     # 交付验证记录
│   ├── plans/                        # 设计、实现和优化计划
│   ├── qa/                           # 手工 QA 脚本与走查报告
│   └── review/                       # 评审报告
├── scripts/                          # 本地验证、调试和约束检查脚本
├── build-profile.json5               # Hvigor 工程配置
├── hvigorfile.ts                     # 根 Hvigor 任务入口
└── oh-package.json5                  # 根包配置
```

## 架构约定

- 页面层只负责界面组合、导航状态、加载态、空态、错误态和用户输入。
- 页面不要直接写 SQL，应通过 repository 或 domain-facing service 访问数据。
- `domain/` 不依赖 ArkUI、SQLite 或本地文件 API。
- SQLite 业务表是事实来源，搜索索引是派生数据，必须可重建。
- repository 负责让业务数据、搜索索引和媒体清理保持一致。
- 照片二进制只放在应用本地文件中，不写入 SQLite。
- 小工具放在 `utils/`，避免反向依赖页面、组件、仓储或平台适配器。

## 设计资料

改页面布局、视觉 token、导航、用户可见文案或交互前，先阅读：

- `docs/background/yibuque-design.md`
- `docs/architecture.md`
- `docs/qa/manual-test-script.md`
- 相关 `docs/plans/*.md`

当前设计基线：

- 页面以真实照片和本地记录为主。
- 主操作、选中态和保存按钮使用黑色。
- 禁止旧 Rose VI 的粉色背景、粉色主按钮、粉色阴影和粉色边框。
- 底部导航为 `衣柜 / 逛店 / 相机 / 穿搭 / 我的`。
- 底部相机入口打开快捷录入，不作为社交发布入口。

## 本地开发

前置环境：

- DevEco Studio 或可用的 HarmonyOS command-line-tools。
- Node.js，用于运行 `scripts/*.mjs` 验证脚本。
- HarmonyOS 模拟器或可调试设备。

常用验证：

```bash
for script in scripts/*.mjs; do node "$script"; done
git diff --check
```

完整 App 构建：

```bash
<command-line-tools>/bin/hvigorw assembleApp --no-daemon --no-incremental --no-parallel --stacktrace
```

只构建 entry HAP：

```bash
<command-line-tools>/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
```

模拟机调试环境：

```bash
scripts/emulator-debug.sh
```

`scripts/emulator-debug.sh` 会构建 default debug HAP、安装到当前 HDC 目标、启动 `EntryAbility`，并默认保存一张模拟器截图。工具路径可通过 `DEVECO_COMMAND_LINE_TOOLS`、`DEVECO_SDK_HOME`、`HVIGORW` 或 `HDC` 覆盖。多设备时可指定：

```bash
HDC_TARGET=<target> scripts/emulator-debug.sh
```

已有可用 HAP、只想安装启动时：

```bash
SKIP_BUILD=1 scripts/emulator-debug.sh
```

如果模拟器中已有同包名但签名不同的应用，脚本会停止。确认可以卸载旧包并保留数据后再运行：

```bash
RESET_APP_ON_SIGN_MISMATCH=1 scripts/emulator-debug.sh
```

## 签名与本机配置

不要提交签名材料或本机签名配置。

`.gitignore` 已忽略：

- `.hvigor/`
- `build/`
- `entry/build/`
- `.idea/`
- `.workbuddy/`
- `signature/`
- `*.backup`

特别注意：DevEco Studio 可能会把当前华为账号生成的调试签名写入 `build-profile.json5`，包括 `signingConfig`、`signingConfigs`、证书路径、profile 路径、`.p12` 路径和密码字段。这些内容属于本机私有配置，尤其是多台电脑登录同一个华为账号时，不要提交到仓库。

提交前检查：

```bash
git status --short --branch -uall
git diff -- build-profile.json5
git diff --cached --name-only
```

如果 `build-profile.json5` 里只有签名相关差异，保持它未暂存即可。需要提交其它文件时，显式按文件暂存，不要使用会把签名一起带上的批量暂存方式。

## QA 与交付记录

- 手工 QA 脚本：`docs/qa/manual-test-script.md`
- 静态走查报告：`docs/qa/walkthrough-report-2026-07-14.md`
- 首版交付记录：`docs/delivery/first-release-verification.md`
- 最新优化计划：`docs/plans/optimization-plan-2026-07-14.md`

手工 QA 应至少覆盖：

- 离线启动、保存和重启回显。
- 衣柜、穿搭、逛店、我的、心愿和搜索主流程。
- 拍照/相册选择后的本地媒体复制。
- 删除记录后的搜索索引和媒体清理。
- 视觉基线：黑色主操作、浅灰表面、真实图片、中文状态文案。

## 提交前清单

- 没有提交 `.hvigor/`、`build/`、`entry/build/` 等生成物。
- 没有提交 `signature/`、证书、profile、`.p12`、签名密码或本机绝对路径。
- 没有新增网络权限或远程同步依赖。
- 页面没有直接写 SQL。
- 新增或删除业务数据时同步维护搜索索引。
- 涉及照片的新增、修改和删除都走媒体层。
- 用户可见文案为中文，不出现 `loading / error / retry / search` 这类调试式前缀。
- UI 改动已对齐 `docs/background/yibuque-design.md`。
- 已运行本地验证脚本和 `git diff --check`。

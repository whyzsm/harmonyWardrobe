# Harmony Wardrobe 架构 / Harmony Wardrobe Architecture

## 总览 / Overview

Harmony Wardrobe 是一个本地优先的 HarmonyOS Stage 应用，用于管理衣橱记录、穿搭模板、穿着日志、日历回顾和购物心愿记录。应用把业务数据保存在本地 SQLite 表中，把复制后的照片保存在应用本地存储中，SQLite 只保存本地 URI 或路径引用。

Harmony Wardrobe is a local-first HarmonyOS Stage app for wardrobe records, outfit templates, wear logs, calendar recall, and wishlist notes. The app keeps business data in local SQLite tables and stores copied photos in app-local storage, with SQLite storing only local URI or path references.

## UI 层 / UI Layer

UI 层位于 `entry/src/main/ets/pages`。它负责页面组合、导航状态、用户输入、加载态、空态和错误展示。页面应通过清晰接口调用面向领域的服务或仓储，不应直接写 SQL。

The UI layer lives under `entry/src/main/ets/pages`. It owns screen composition, navigation state, user input, loading states, empty states, and error presentation. Pages should call domain-facing services or repositories through clear interfaces and must not write SQL directly.

## 组件层 / Component Layer

组件层位于 `entry/src/main/ets/components`。它包含跨页面复用的 ArkUI 构建块，例如照片网格、条目卡片、表单控件、筛选控件和空态视图。组件应聚焦展示，通过类型化输入接收数据。

The component layer lives under `entry/src/main/ets/components`. It contains reusable ArkUI building blocks shared across screens, such as photo grids, item cards, form controls, filter controls, and empty-state views. Components should stay presentation-focused and receive data through typed inputs.

## 领域层 / Domain Layer

领域层位于 `entry/src/main/ets/domain`。它定义衣物、穿搭模板、穿着日志、购物心愿和搜索结果等衣橱业务概念与规则。领域对象不应依赖 ArkUI 组件、SQLite API 或本地文件 API。

The domain layer lives under `entry/src/main/ets/domain`. It defines wardrobe business concepts and rules for clothing items, outfit templates, wear logs, wishlist items, and search results. Domain objects should not depend on ArkUI widgets, SQLite APIs, or local file APIs.

## 数据层 / Data Layer

数据层位于 `entry/src/main/ets/data`。它负责数据库访问、迁移、仓储和派生搜索索引。SQLite 业务表是事实来源；搜索索引数据可以重建，并应通过仓储操作保持一致。

The data layer lives under `entry/src/main/ets/data`. It owns database access, migrations, repositories, and the derived search index. SQLite business tables are the source of truth; search index data is rebuildable and should be kept consistent through repository operations.

## 媒体层 / Media Layer

媒体层位于 `entry/src/main/ets/media`。它负责照片选择、相机集成、本地文件复制和应用本地孤立媒体清理。数据库只应保存本地媒体引用，不应保存图片二进制内容。

The media layer lives under `entry/src/main/ets/media`. It owns photo picking, camera integration, local file copying, and cleanup of orphaned app-local media. The database should store only local media references, not image blobs.

## 工具层 / Utility Layer

工具层位于 `entry/src/main/ets/utils`。它包含 ID、日期、结果处理和文本处理等小型共享工具。工具应保持轻量，避免依赖应用页面、组件或仓储。

The utility layer lives under `entry/src/main/ets/utils`. It contains small shared helpers for IDs, dates, result handling, and text processing. Utilities should remain framework-light and avoid depending on app screens or repositories.

## 依赖方向 / Dependency Direction

依赖应从 UI 和组件流向领域契约，再通过数据和媒体适配器连接到平台能力。共享工具可被任意层使用，但除非明确隔离，否则工具不应导入应用页面、组件、仓储或平台特定适配器。

Dependencies should flow from UI and components toward domain contracts, then through data and media adapters to platform capabilities. Shared utilities may be used by any layer, but utilities must not import application pages, components, repositories, or platform-specific adapters unless explicitly isolated.

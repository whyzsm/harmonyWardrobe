# Harmony Wardrobe 手工 QA 脚本 / Harmony Wardrobe Manual QA Script

## 目标 / Goal

中文：验证首版核心流程可以在 offline 条件下完成，包括 Today、Wardrobe、Outfits、Calendar、Shopping、photo、search 和本地持久化。

English: Verify that the first release core flows work in offline mode, including Today, Wardrobe, Outfits, Calendar, Shopping, photo, search, and local persistence.

## 前置条件 / Preconditions

中文：安装调试包后，关闭网络或进入飞行模式；如需要稳定数据，可先通过 debug fixture 注入 `seedWardrobeDebugData` 数据。

English: After installing the debug build, disable network access or turn on airplane mode; when stable data is needed, inject `seedWardrobeDebugData` through the debug fixture first.

中文：确认应用没有请求网络权限，所有照片使用本地相册、相机或 `debug://photos/...` 种子 URI。

English: Confirm the app does not request network permission, and all photos come from local gallery, camera, or `debug://photos/...` seed URIs.

## Today / Today

中文：打开 Today 页，确认当天穿着记录可见；新增一条今日记录，填写地点和备注，保存后返回 Today 页确认记录仍显示。

English: Open the Today tab and confirm today's wear log is visible; add a new wear log for today, enter place and note, save it, then return to Today and confirm the record remains visible.

## Wardrobe / Wardrobe

中文：打开 Wardrobe 页，确认种子衣物可见；新增衣物，选择分类、填写名称、备注和购买信息，并附加一张 photo。

English: Open the Wardrobe tab and confirm seed clothing items are visible; add a clothing item, select category, enter name, note, and purchase details, and attach one photo.

中文：编辑刚新增的衣物，修改名称或备注后保存；删除一件非关键测试衣物，确认列表刷新且不会影响其他数据。

English: Edit the newly added item, change its name or note, and save it; delete a non-critical test item and confirm the list refreshes without affecting other data.

## Outfits / Outfits

中文：打开 Outfits 页，确认种子穿搭可见；创建一个穿搭，选择至少两件 Wardrobe 衣物，附加 photo，并保存。

English: Open the Outfits tab and confirm the seed outfit is visible; create an outfit, select at least two Wardrobe items, attach a photo, and save it.

中文：从穿搭详情进入穿着记录流程，选择日期并保存，确认该穿搭的最近穿着记录更新。

English: From outfit details, start the wear-log flow, choose a date, save it, and confirm the outfit recent wear history updates.

## Calendar / Calendar

中文：打开 Calendar 页，切换到包含测试日期的月份，确认有穿着记录的日期有可识别状态。

English: Open the Calendar tab, switch to the month that contains the test date, and confirm dates with wear logs have a recognizable state.

中文：点选有记录的日期，确认当天穿搭、地点和备注可以查看；点选无记录日期，确认空态合理。

English: Select a date with records and confirm outfit, place, and note are viewable; select a date without records and confirm the empty state is reasonable.

## Shopping / Shopping

中文：打开 Shopping 页，确认种子心愿单可见；新增心愿单条目，填写标题、店铺、价格、备注和 photo。

English: Open the Shopping tab and confirm the seed wishlist item is visible; add a wishlist item with title, store, price, note, and photo.

中文：编辑并删除一个测试心愿单条目，确认 Shopping 列表和搜索结果同步更新。

English: Edit and delete one test wishlist item, then confirm the Shopping list and search results update consistently.

## Photo / Photo

中文：在 Wardrobe、Outfits、Today 和 Shopping 各执行一次 photo 选择或相机拍照；保存后确认缩略图仍能显示。

English: Pick or capture a photo once from Wardrobe, Outfits, Today, and Shopping; after saving, confirm thumbnails remain visible.

中文：重启应用后再次打开这些记录，确认 photo URI 没有丢失，且没有出现网络依赖。

English: Restart the app and reopen those records, confirming photo URIs are not lost and no network dependency appears.

## Search / Search

中文：搜索种子数据关键词，例如 `White`、`Office`、`Teal`；确认结果覆盖 Wardrobe、Outfits、Calendar 关联的穿着记录和 Shopping。

English: Search seed keywords such as `White`, `Office`, and `Teal`; confirm results cover Wardrobe, Outfits, Calendar-related wear logs, and Shopping.

中文：修改一条记录后再次搜索，确认搜索索引更新；删除记录后确认搜索结果不再出现该记录。

English: Modify one record and search again to confirm the search index updates; delete the record and confirm it no longer appears in results.

## Offline Persistence / Offline Persistence

中文：保持 offline 状态，新增、编辑、删除各类记录后完全退出应用并重新打开，确认本地 SQLite 数据仍存在。

English: While remaining offline, add, edit, and delete each type of record, then fully close and reopen the app to confirm local SQLite data persists.

中文：重启设备或模拟器后再次打开应用，确认 Today、Wardrobe、Outfits、Calendar、Shopping 和 search 的状态与重启前一致。

English: Restart the device or emulator, reopen the app, and confirm Today, Wardrobe, Outfits, Calendar, Shopping, and search state match the state before restart.

## 记录 / Notes

中文：记录设备型号、系统版本、应用 commit、是否使用 seed fixture、未覆盖项和失败截图路径。

English: Record device model, system version, app commit, whether the seed fixture was used, uncovered items, and failure screenshot paths.

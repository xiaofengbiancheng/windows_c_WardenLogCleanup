# Warden 日志清理开发任务清单

## 阶段与状态
核心清理、定时任务注册、参数路由和卸载逻辑已实现，并完成本机手工验证。脚本文件为仓库根目录的 `WardenLogCleanup.bat`。

| 编号 | 任务 | 阶段 | 优先级 | 当前状态 | 验收摘要 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| T01* | 脚本骨架与参数识别 | 阶段1 | P0 | 已完成 | 无参数进入清理；卸载参数进入卸载流程。 |
| T02 | 管理员权限校验 | 阶段1 | P0 | 已完成 | 非管理员提示错误并退出。 |
| T03 | 目标目录校验 | 阶段1 | P0 | 已完成 | 目录不存在时提示并退出。 |
| T04 | 当前日期获取 | 阶段2 | P0 | 已完成 | 当前日期转换为 `YYYYMMDD`，兼容 `Tue MM/DD/YYYY` 等带星期前缀格式。 |
| T05 | 文件遍历与分类 | 阶段2 | P0 | 已完成 | 白名单和当天文件保留，历史文件进入处理。 |
| T06 | 历史文件占用判断 | 阶段2 | P0 | 已完成 | 使用重命名探测判断占用状态。 |
| T07 | 差异化清理 | 阶段3 | P0 | 已完成 | 未占用删除，占用文件尝试清空。 |
| T08 | 汇总日志写入 | 阶段3 | P0 | 已完成 | 追加 `Delete/Clear/Fail` 统计。 |
| T09 | 定时任务注册 | 阶段4 | P1 | 已完成 | 创建 `\WardenLogCleanupTask`，每日 09:00 以 `SYSTEM` 执行；验收时确认任务引用已部署的修复版脚本。 |
| T10 | 控制台输出 | 阶段4 | P1 | 已完成 | 手动运行显示文件结果并暂停；计划任务静默运行。 |
| T11 | 定时任务卸载 | 阶段4 | P1 | 已完成 | `-uninstall` 等参数只删除任务；不存在时友好提示。 |

脚本支持测试环境变量 `WARDEN_SKIP_TASK_INSTALL=1`，用于临时执行清理而不改变任务计划配置。

## 验证命令
```bat
cmd /c "D:\codex_code\codex_code1\WardenLogCleanup.bat"
cmd /c "set WARDEN_SKIP_TASK_INSTALL=1&& call D:\codex_code\codex_code1\WardenLogCleanup.bat"
schtasks /Query /TN "\WardenLogCleanupTask" /V /FO LIST
cmd /c "D:\codex_code\codex_code1\WardenLogCleanup.bat" -uninstall
```

## 注意事项
所有破坏性测试应使用临时目录。应验证 `Tue 08/11/2026` 可转换为 `20260811`，并确认 `health-check-win.log` 不会被清理。部署后应执行 `schtasks /Query /TN "\WardenLogCleanupTask" /V /FO LIST`，确认“要运行的任务”指向已覆盖的脚本路径。修改默认路径、白名单或任务时间后，应同步更新 `PRD.md` 和 `产品使用说明.md`。

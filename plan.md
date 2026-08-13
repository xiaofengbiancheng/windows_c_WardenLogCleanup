# Warden 日志清理开发任务清单

## 阶段与状态
核心清理、定时任务注册、参数路由和卸载逻辑已实现，并完成本机手工验证。脚本文件为仓库根目录的 `WardenLogCleanup.bat`。

| 编号 | 任务 | 阶段 | 优先级 | 当前状态 | 验收摘要 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| T01* | 脚本骨架与参数识别 | 阶段1 | P0 | 已完成 | 无参数进入清理；卸载参数进入卸载流程。 |
| T02 | 管理员权限校验 | 阶段1 | P0 | 已完成 | 非管理员提示错误并退出。 |
| T03 | 目标目录校验 | 阶段1 | P0 | 已完成 | 目录不存在时提示并退出。 |
| T04 | 当前日期获取 | 阶段2 | P0 | 已完成 | 当前日期转换为 `YYYYMMDD`，兼容 `Tue MM/DD/YYYY` 等带星期前缀格式。 |
| T05 | 文件遍历与分类 | 阶段2 | P0 | 已完成 | 白名单保留；`health-check-win.log` 始终直接尝试清空且不删除，不受当天日期规则影响；正在使用但允许写入时应清空，独占锁定时无法绕过且计入 `Fail`；当天其他文件保留，历史文件进入处理。 |
| T06 | 历史文件占用判断 | 阶段2 | P0 | 已完成 | 使用重命名探测判断占用状态。 |
| T07 | 差异化清理 | 阶段3 | P0 | 已完成 | 未占用删除，占用文件尝试清空。 |
| T08 | 汇总日志写入 | 阶段3 | P0 | 已完成 | 追加 `Delete/Clear/Fail` 统计。 |
| T09 | 定时任务注册 | 阶段4 | P1 | 已完成 | 创建 `\WardenLogCleanupTask`，每日 09:00 以 `SYSTEM` 执行；任务通过 `cmd.exe /d /c <脚本短路径> /scheduled` 调用已部署脚本，验收时确认任务引用更新后的部署文件。 |
| T10 | 控制台输出 | 阶段4 | P1 | 已完成 | 手动运行显示文件结果并暂停；计划任务静默运行。 |
| T11 | 定时任务卸载 | 阶段4 | P1 | 已完成 | `-uninstall` 等参数只删除任务；不存在时友好提示。 |

脚本支持 `WARDEN_TARGET_DIR`、`WARDEN_LOG_FILE`、`WARDEN_WHITELIST`、`WARDEN_TASK_NAME`、`WARDEN_TASK_TIME` 和 `WARDEN_SKIP_TASK_INSTALL=1` 等测试环境变量。`CLEAR_ONLY_FILE` 仅能修改脚本顶部配置。

## 验证命令
```bat
call "D:\codex_code\codex_code1\WardenLogCleanup.bat"
cmd /c "set WARDEN_SKIP_TASK_INSTALL=1&& call D:\codex_code\codex_code1\WardenLogCleanup.bat"
schtasks /Query /TN "\WardenLogCleanupTask" /V /FO LIST
call "D:\codex_code\codex_code1\WardenLogCleanup.bat" -uninstall
```

## 注意事项
所有破坏性测试应使用临时目录。应验证 `Tue 08/11/2026` 可转换为 `20260811`，确认 `cleanup_action.log` 不会被清理，并确认当天的 `health-check-win.log` 会被清空但仍存在；该 `.log` 文件正在使用但允许写入时，也应清空且不删除；独占锁定而无法写入时，应显示 `[FAIL] ... [clear-only]` 并增加 `Fail`，且不应声称能够绕过锁定。部署后应执行 `schtasks /Query /TN "\WardenLogCleanupTask" /V /FO LIST`，确认“要运行的任务”通过 `cmd.exe /d /c` 和 `/scheduled` 调用已覆盖的部署脚本。修改默认路径、白名单、仅清空文件或任务时间后，应同步更新 `PRD.md` 和 `产品使用说明.md`。

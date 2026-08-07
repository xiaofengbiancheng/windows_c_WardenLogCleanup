# Warden 日志自动清理工具 PRD

## 1. 产品概述
`WardenLogCleanup.bat` 用于清理 `C:\warden\wisps\health-check\log` 下的历史日志，释放磁盘空间，同时保护当天仍可能被业务写入的日志。脚本仅依赖 Windows 原生 CMD 命令。

## 2. 运行模式
- **无参数**：要求管理员权限，注册或覆盖 `\WardenLogCleanupTask`，计划每天 09:00 以 `SYSTEM` 运行，并立即执行一次清理。
- **`-uninstall`、`--uninstall` 或 `/uninstall`**：仅删除指定定时任务，不扫描、不删除、不清空任何日志。
- **`/scheduled` 或 `--scheduled`**：供任务计划程序调用，跳过重复注册并静默清理。
- **临时测试**：设置 `WARDEN_SKIP_TASK_INSTALL=1` 后运行无参数脚本时，仅执行清理，不注册或修改定时任务。

## 3. 清理规则
1. `health-check-win` 和 `cleanup_action.log` 为精确文件名白名单，始终保留。
2. 最后修改日期为当天的文件保留。
3. 其他未占用历史文件强制删除。
4. 其他被占用历史文件尝试清空内容，保留文件本身；失败计入 `Fail`。

## 4. 输出与配置
控制台显示手动执行的文件级结果和汇总；定时执行不显示交互输出。汇总追加写入：
`C:\warden\wisps\health-check\log\cleanup_action.log`

格式为：`[YYYY/MM/DD HH:MM:SS] Delete: X, Clear: Y, Fail: Z`。

脚本顶部可配置 `TARGET_DIR`、`LOG_FILE`、`WHITELIST`、`TASK_NAME` 和 `TASK_TIME`；也支持同名 `WARDEN_` 环境变量覆盖。

## 5. 边界
不提供远程部署、归档压缩、强制终止占用进程或 GUI。目标目录不存在时提示错误并退出。

# Warden 日志自动清理工具 PRD

## 1. 产品概述
`WardenLogCleanup.bat` 用于清理 `C:\warden\wisps\health-check\log` 下的历史日志，释放磁盘空间，同时保护当天仍可能被业务写入的日志。脚本仅依赖 Windows 原生 CMD 命令。

## 2. 运行模式
- **无参数**：要求管理员权限，注册或覆盖 `\WardenLogCleanupTask`，计划每天 09:00 以 `SYSTEM` 运行，并立即执行一次清理。
- **`-uninstall`、`--uninstall` 或 `/uninstall`**：仅删除指定定时任务，不扫描、不删除、不清空任何日志。
- **`/scheduled` 或 `--scheduled`**：供任务计划程序调用，跳过重复注册并静默清理。
- **临时测试**：设置 `WARDEN_SKIP_TASK_INSTALL=1` 后运行无参数脚本时，仅执行清理，不注册或修改定时任务。

在 CMD 中执行带参数的脚本时，应使用 `call "完整脚本路径" <参数>`；例如 `call "C:\warden\wisps\health-check\WardenLogCleanup.bat" --uninstall`。不要使用 `cmd /c "完整脚本路径" --uninstall`，因为参数位于引号外会导致路径语法错误。

部署到服务器时，应将经验证的 `WardenLogCleanup.bat` 覆盖实际运行位置的同名文件。计划任务执行注册时所传入的脚本路径，因此开发工作区中的副本不会自动更新服务器已部署的副本。

## 3. 清理规则
1. `cleanup_action.log` 为精确文件名白名单，始终保留。
2. `health-check-win.txt` 为仅清空文件：每次运行均直接尝试清空内容，绝不删除；即使文件正在被使用，只要仍允许写入也会清空。无法清空时计入 `Fail`。
3. 最后修改日期为当天的其他文件保留；文件名不参与日期判断。
4. 其他未占用历史文件强制删除。
5. 其他被占用历史文件尝试清空内容，保留文件本身；失败计入 `Fail`。

## 4. 输出与配置
控制台显示手动执行的文件级结果和汇总；定时执行不显示交互输出。仅清空文件清空成功显示 `[CLEAR] health-check-win.txt [clear-only]`，失败显示 `[FAIL] health-check-win.txt [clear-only]`。汇总追加写入：
`C:\warden\wisps\health-check\log\cleanup_action.log`

格式为：`[YYYY/MM/DD HH:MM:SS] Delete: X, Clear: Y, Fail: Z`。

脚本顶部集中配置 `TARGET_DIR`、`LOG_FILE`、`WHITELIST`、`CLEAR_ONLY_FILE`、`TASK_NAME` 和 `TASK_TIME`。其中 `TARGET_DIR`、`LOG_FILE`、`WHITELIST`、`TASK_NAME` 和 `TASK_TIME` 支持对应的 `WARDEN_` 环境变量覆盖；`CLEAR_ONLY_FILE` 修改脚本顶部配置后生效。

当天日期兼容 Windows 本地日期格式，包括 `YYYY/MM/DD`、`MM/DD/YYYY` 和带星期前缀的 `Tue MM/DD/YYYY`；脚本内部统一转换为 `YYYYMMDD` 后比较。

## 5. 边界
不提供远程部署、归档压缩、强制终止占用进程或 GUI。目标目录不存在或当天日期无法识别时，脚本会提示错误并退出。定时任务注册失败或注册后无法验证时，脚本会输出警告，但仍继续执行本次清理。

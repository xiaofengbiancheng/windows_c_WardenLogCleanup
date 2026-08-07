# Warden 日志清理脚本使用说明

## 1. 前提
请使用“以管理员身份运行”的 CMD。脚本默认清理：

```text
C:\warden\wisps\health-check\log
```

## 2. 日常运行
```bat
cmd /c "D:\codex_code\codex_code1\WardenLogCleanup.bat"
```

无参数运行会注册或覆盖根目录任务 `\WardenLogCleanupTask`，计划每天 09:00 以 `SYSTEM` 执行，并立即清理一次。手动执行结束后会暂停窗口，便于查看结果。

### 临时执行一次且不注册任务
```bat
cmd /c "set WARDEN_SKIP_TASK_INSTALL=1&& call D:\codex_code\codex_code1\WardenLogCleanup.bat"
```

这是一条独立命令，仅对当前 CMD 子进程生效，不会创建、覆盖或删除定时任务；但会按正常规则实际清理默认日志目录。

## 3. 卸载任务
```bat
cmd /c "D:\codex_code\codex_code1\WardenLogCleanup.bat" -uninstall
```

`--uninstall` 和 `/uninstall` 也有效。卸载模式只删除定时任务，不执行任何清理；任务不存在时会提示任务不存在且不报错。

## 4. 验证任务
```bat
schtasks /Query /TN "\WardenLogCleanupTask" /V /FO LIST
```

重点确认“计划任务状态”为“已启用”、“下次运行时间”为每天 09:00、“作为用户运行”为 `SYSTEM`，以及“要运行的任务”包含 `/scheduled`。

## 5. 结果与故障处理
`[KEEP]` 表示保留，`[DELETE]` 表示删除，`[CLEAR]` 表示清空占用文件，`[FAIL]` 表示处理失败。汇总会追加到 `cleanup_action.log`。

遇到权限错误时，请重新打开管理员 CMD；遇到目录错误时，先确认目标目录存在。不要直接对生产目录做测试。

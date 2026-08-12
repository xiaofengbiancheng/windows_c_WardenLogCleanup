# Warden 日志清理脚本使用说明

## 1. 前提
请使用“以管理员身份运行”的 CMD。脚本默认清理：

```text
C:\warden\wisps\health-check\log
```

## 2. 日常运行

### 部署到服务器
将已验证的项目脚本部署为：

```text
C:\warden\wisps\health-check\WardenLogCleanup.bat
```

开发工作区中的 `D:\codex_code\codex_code1\WardenLogCleanup.bat` 与服务器部署文件是两份独立文件。修改开发工作区后，必须重新覆盖服务器部署文件；计划任务只会执行“要运行的任务”字段中指定的路径。

```bat
call "C:\warden\wisps\health-check\WardenLogCleanup.bat"
```

无参数运行会注册或覆盖根目录任务 `\WardenLogCleanupTask`，计划每天 09:00 以 `SYSTEM` 执行，并立即清理一次。任务实际使用 `cmd.exe /d /c <脚本短路径> /scheduled` 调用部署脚本。手动执行结束后会暂停窗口，便于查看结果；若任务注册或验证失败，脚本会显示警告但仍继续本次清理。

### 临时执行一次且不注册任务
```bat
cmd /c "set WARDEN_SKIP_TASK_INSTALL=1&& call C:\warden\wisps\health-check\WardenLogCleanup.bat"
```
这是一条独立命令，仅对当前 CMD 子进程生效，不会创建、覆盖或删除定时任务；但会按正常规则实际清理默认日志目录。

## 3. 卸载任务
```bat
call "C:\warden\wisps\health-check\WardenLogCleanup.bat" -uninstall
```

`--uninstall` 和 `/uninstall` 也有效。请使用 `call "完整脚本路径" <卸载参数>`；不要使用 `cmd /c "完整脚本路径" --uninstall`，该写法会使参数落在命令引号外并触发路径语法错误。卸载模式只删除定时任务，不执行任何清理；任务不存在时会提示任务不存在且不报错。

## 4. 验证任务
```bat
schtasks /Query /TN "\WardenLogCleanupTask" /V /FO LIST
```

重点确认“计划任务状态”为“已启用”、“下次运行时间”为每天 09:00、“作为用户运行”为 `SYSTEM`，以及“要运行的任务”包含 `cmd.exe /d /c`、已部署脚本的路径和 `/scheduled`。

## 5. 结果与故障处理
`cleanup_action.log` 始终保留。`health-check-win.txt` 每次运行都会直接尝试清空内容，绝不会删除，即使它是当天文件或正在被其他进程使用。只要系统允许写入，文件会被清空并显示 `[CLEAR] health-check-win.txt [clear-only]`；真正无法写入时才保留原内容，显示 `[FAIL] health-check-win.txt [clear-only]` 并在汇总中增加 `Fail`。其他当天文件保留；历史文件未占用时删除、占用时尝试清空。`[KEEP]` 表示保留，`[DELETE]` 表示删除，`[CLEAR]` 表示清空（包括仅清空文件和占用的历史文件），`[FAIL]` 表示处理失败。汇总会追加到 `cleanup_action.log`。

## 6. 本地测试配置
可在同一条 CMD 命令中临时设置 `WARDEN_TARGET_DIR`、`WARDEN_LOG_FILE`、`WARDEN_WHITELIST`、`WARDEN_TASK_NAME`、`WARDEN_TASK_TIME` 或 `WARDEN_SKIP_TASK_INSTALL`，以便在临时目录验证。`health-check-win.txt` 的名称由脚本顶部 `CLEAR_ONLY_FILE` 配置控制，不能通过环境变量覆盖。

遇到权限错误时，请重新打开管理员 CMD；遇到目录错误时，先确认目标目录存在。不要直接对生产目录做测试。

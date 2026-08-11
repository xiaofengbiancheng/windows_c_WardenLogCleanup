# Repository Guidelines

## Project Structure
这是一个 Windows 批处理脚本项目，核心文件位于仓库根目录：

- `WardenLogCleanup.bat`：日志清理、定时任务注册和卸载逻辑。
- `PRD.md`：产品需求和运行规则。
- `开发任务清单.md`：开发任务、状态和验收记录。
- `产品使用说明.md`：运维人员使用手册。

## Build, Test, and Development
项目无编译步骤、第三方依赖或自动化测试框架。使用管理员 CMD 执行：

```bat
cmd /c "D:\codex_code\codex_code1\WardenLogCleanup.bat"
cmd /c "set WARDEN_SKIP_TASK_INSTALL=1&& call D:\codex_code\codex_code1\WardenLogCleanup.bat"
schtasks /Query /TN "\WardenLogCleanupTask" /V /FO LIST
cmd /c "D:\codex_code\codex_code1\WardenLogCleanup.bat" -uninstall
```

第一条命令会注册或覆盖每日 09:00 任务，并立即执行一次清理；第二条命令临时清理但不修改任务；第三条命令验证任务；第四条命令只卸载任务。

仓库中的 `D:\codex_code\codex_code1\WardenLogCleanup.bat` 与服务器部署的 `C:\warden\wisps\health-check\WardenLogCleanup.bat` 是独立文件。修改仓库脚本后，必须显式覆盖服务器部署文件，并通过 `schtasks /Query` 确认任务“要运行的任务”引用了更新后的脚本。

## Coding Style
仅使用 Windows CMD 批处理语法。配置项集中在脚本顶部，变量使用大写下划线命名，例如 `TARGET_DIR`、`TASK_NAME`。子程序标签使用清晰的 PascalCase 或 snake_case 名称。保持 Windows `CRLF` 换行，避免 PowerShell、第三方 EXE 和外部网络依赖。

## Testing Guidelines
必须在临时日志目录验证：管理员权限、目录不存在、白名单文件、当天文件、历史文件删除、历史占用文件清空、汇总日志以及三种卸载参数。日期测试应覆盖 `Tue 08/11/2026` 并确认其转换为 `20260811`。不要直接对生产日志做破坏性测试。

## Pull Requests
当前目录没有 Git 历史，无法约定既有提交格式。提交时使用简短命令式标题，例如 `修复定时任务注册参数`。PR 应说明变更范围、手工测试命令和输出，并附带定时任务行为变化。

## Security and Configuration
脚本默认处理 `C:\warden\wisps\health-check\log`，需要管理员权限并以 `SYSTEM` 注册任务。可通过 `WARDEN_TARGET_DIR`、`WARDEN_LOG_FILE`、`WARDEN_WHITELIST`、`WARDEN_TASK_NAME` 和 `WARDEN_TASK_TIME` 做本地测试覆盖。

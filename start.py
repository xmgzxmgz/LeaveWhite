#!/usr/bin/env python3
import subprocess
import sys
import os

# ANSI 颜色代码
GREEN = '\033[0;32m'
RED = '\033[0;31m'
NC = '\033[0m'  # No Color

def log(message, color=NC):
    """打印带颜色的日志"""
    print(f"{color}{message}{NC}")

def run_command(command, check=True):
    """运行 shell 命令并实时输出"""
    try:
        # 使用 subprocess.run 直接连接标准输出和错误输出，保持实时性
        result = subprocess.run(
            command,
            shell=True,
            check=check,
            text=True
        )
        return result.returncode
    except subprocess.CalledProcessError as e:
        return e.returncode

def main():
    log("🚀 正在启动 LeaveWhite...", GREEN)

    # 1. 编译项目
    # 使用 --disable-sandbox 绕过权限限制，避免 keychain 和文件访问报错
    log("🔨 正在编译...", GREEN)
    build_cmd = "swift build --disable-sandbox -c debug"
    if run_command(build_cmd) != 0:
        log("❌ 编译失败，请检查错误信息。", RED)
        sys.exit(1)

    # 2. 运行项目
    log("▶️  正在运行...", GREEN)
    run_cmd = "swift run --disable-sandbox LeaveWhite"
    # 这里不需要 check=True，因为运行时的错误不需要脚本层面的异常处理，直接透传即可
    run_command(run_cmd, check=False)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("\n🛑 已停止", RED)
        sys.exit(0)

# 🛡️ LeaveWhite

[![CI](https://github.com/xmgzxmgz/LeaveWhite/actions/workflows/ci.yml/badge.svg)](https://github.com/xmgzxmgz/LeaveWhite/actions/workflows/ci.yml)

> 一款注重隐私的安全日记与紧急响应应用，基于 AES-256-GCM 加密和生物认证保护您的数据。

## ✨ 功能特性

- 📝 **安全日记** — 端到端加密存储，AES-256-GCM + Keychain 密钥管理
- 🔐 **生物认证** — Face ID / Touch ID 解锁
- ⏰ **Dead Man Switch** — 紧急响应机制，未按时签到自动触发
- 📡 **Echo Chronos** — 加密消息延迟分发系统
- 🌐 **中英双语** — 完整的国际化支持
- 🎨 **毛玻璃 UI** — 自定义 GlassCard 组件、GuardianRing 动画
- 🛡️ **安全错误处理** — 统一的 os_log 日志系统，用户友好的错误提示

## 🛠️ 技术栈

| 技术 | 用途 |
|------|------|
| Swift 5.10+ | 核心语言 |
| SwiftUI | 用户界面 |
| SwiftData | 数据持久化 |
| CryptoKit | AES-256-GCM 加密 |
| LocalAuthentication | 生物认证 |
| Keychain Services | 密钥安全存储 |
| os (Unified Logging) | 结构化日志 |
| Swift Testing | 单元测试框架 |

## 📋 系统要求

- macOS 14+ / iOS 17+
- Xcode 15+
- Swift 5.10+

## 🚀 构建运行

```bash
# 使用 Xcode 打开（推荐，完整构建）
open Package.swift

# 命令行构建库目标（SwiftData 宏需要 Xcode 构建系统）
swift build --target LeaveWhiteCore
```

## 🧪 运行测试

```bash
# 需要 Xcode 构建系统（SwiftData 宏依赖）
swift test
```

测试覆盖：
- **DeadManSwitchEngine** — safe/warning/triggered 状态判定、边界条件
- **HeuristicClassifier** — 密码、助记词、账号、长文本等分类
- **CryptoBox** — AES-256-GCM 加解密往返、错误密钥、篡改检测、AAD 验证

## 📁 项目结构

```
LeaveWhite/
├── Sources/
│   ├── LeaveWhiteCore/       # 核心库 (加密、安全、数据模型)
│   │   ├── Security/
│   │   │   ├── CryptoBox       # AES-256-GCM 加解密
│   │   │   ├── VaultKeyManager # Keychain 密钥管理 (actor)
│   │   │   ├── SecurityManager # 生物认证 + 安全策略
│   │   │   └── KeychainClient  # Keychain 底层操作
│   │   ├── AI/
│   │   │   └── HeuristicClassifier # 内容自动分类
│   │   ├── Engine/
│   │   │   └── DeadManSwitchEngine # 死人开关引擎
│   │   ├── Models/              # SwiftData 数据模型
│   │   └── Utils/
│   │       └── LWLog            # 统一日志系统 (os_log)
│   └── LeaveWhite/              # SwiftUI 应用层
│       ├── Dashboard            # 主面板
│       ├── Vault                # 加密保险库
│       ├── EchoChronos          # 延迟消息系统
│       ├── Utils/
│       │   ├── LanguageManager  # 多语言管理 (@MainActor)
│       │   ├── ErrorLocalization # 错误信息本地化
│       │   └── PlatformViewModifiers # 跨平台 UI 适配
│       ├── Components/          # 复用 UI 组件
│       ├── Design/              # 主题配色
│       └── Resources/           # 国际化资源 (中/英)
└── Tests/
    └── LeaveWhiteCoreTests/     # 单元测试 (Swift Testing)
```

## 🔒 安全架构

- **加密**: AES-256-GCM（硬件加速）
- **密钥管理**: Apple Keychain Services + actor 隔离
- **认证**: LocalAuthentication (Face ID / Touch ID)
- **并发安全**: Swift actor 模型 + Sendable 标注
- **错误处理**: 统一 os_log 日志，用户友好的本地化错误提示
- **隐私保护**: 日志中使用 privacy 标记防止敏感信息泄露

## 📄 License

MIT

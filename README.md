# 🛡️ LeaveWhite

> 一款注重隐私的安全日记与紧急响应应用，基于 AES-256-GCM 加密和生物认证保护您的数据。

## ✨ 功能特性

- 📝 **安全日记** — 端到端加密存储，AES-256-GCM + Keychain 密钥管理
- 🔐 **生物认证** — Face ID / Touch ID 解锁
- ⏰ **Dead Man Switch** — 紧急响应机制，未按时签到自动触发
- 📡 **Echo Chronos** — 加密消息延迟分发系统
- 🌐 **中英双语** — 完整的国际化支持
- 🎨 **毛玻璃 UI** — 自定义 GlassCard 组件、GuardianRing 动画

## 🛠️ 技术栈

| 技术 | 用途 |
|------|------|
| Swift 5.10+ | 核心语言 |
| SwiftUI | 用户界面 |
| SwiftData | 数据持久化 |
| CryptoKit | AES-256-GCM 加密 |
| LocalAuthentication | 生物认证 |
| Keychain Services | 密钥安全存储 |

## 📋 系统要求

- macOS 14+ / iOS 17+
- Xcode 15+
- Swift 5.10+

## 🚀 构建运行

```bash
# 使用 Xcode 打开
open Package.swift

# 或命令行构建 (注意: SwiftData 宏需要 Xcode 构建系统)
swift build
```

## 📁 项目结构

```
LeaveWhite/
├── Sources/
│   ├── LeaveWhiteCore/     # 核心库 (加密、安全、数据模型)
│   │   ├── CryptoBox       # AES-256-GCM 加解密
│   │   ├── VaultKeyManager # Keychain 密钥管理 (actor)
│   │   ├── SecurityManager # 生物认证 + 安全策略
│   │   └── Models/         # SwiftData 数据模型
│   └── LeaveWhite/         # SwiftUI 应用层
│       ├── Dashboard       # 主面板
│       ├── Vault           # 加密保险库
│       └── EchoChronos     # 延迟消息系统
└── Resources/              # 国际化资源 (中/英)
```

## 🔒 安全架构

- **加密**: AES-256-GCM（硬件加速）
- **密钥管理**: Apple Keychain Services + actor 隔离
- **认证**: LocalAuthentication (Face ID / Touch ID)
- **并发安全**: Swift actor 模型 + Sendable 标注

## 📄 License

MIT

# 🦞 iOS IPA Builder — OpenClaw & Hermes Agent

[![Build OpenClaw](https://github.com/xiaoxinkeji/ios/actions/workflows/build-openclaw.yml/badge.svg)](https://github.com/xiaoxinkeji/ios/actions/workflows/build-openclaw.yml)
[![Build Hermes](https://github.com/xiaoxinkeji/ios/actions/workflows/build-hermes.yml/badge.svg)](https://github.com/xiaoxinkeji/ios/actions/workflows/build-hermes.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)

> 自动构建 **OpenClaw** 和 **Hermes Agent** iOS 客户端 IPA 文件的 CI/CD 项目。

---

## 📱 项目概述

本仓库包含两个**原生 Swift iOS 客户端应用**的完整源代码和自动化构建流水线。通过 GitHub Actions，每次代码推送或手动触发即可自动生成可安装的 IPA 文件。

### 🦞 OpenClaw iOS

[openclaw.ai](https://openclaw.ai/) 的 iOS 伴侣客户端。

- 🔌 通过 WebSocket 连接你的 OpenClaw Gateway
- 📡 支持 Bonjour 局域网自动发现
- 💬 实时聊天 + Node 设备能力注册（相机、Canvas、位置等）
- 🎨 橙色/红色渐变主题，暗色模式

### ⚡ Hermes Agent iOS

[hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com/) 的 iOS 客户端（by [Nous Research](https://nousresearch.com)）。

- 🔌 通过 WebSocket 连接你的 Hermes Gateway
- 📡 支持消息流式传输（streaming）
- ⌨️ 快捷斜杠命令 (`/new`, `/model`, `/skills`, `/usage`, `/insights`)
- 🧠 技能创建/更新、记忆更新通知
- 🎨 紫色/靛蓝渐变主题，暗色模式

---

## 📁 目录结构

```
ios/
├── .github/workflows/
│   ├── build-openclaw.yml      # OpenClaw 自动构建流程
│   └── build-hermes.yml        # Hermes Agent 自动构建流程
├── OpenClaw/
│   ├── project.yml             # XcodeGen 项目配置
│   └── Sources/
│       ├── OpenClawApp.swift    # App 入口
│       ├── Info.plist           # 应用配置
│       ├── Views/
│       │   ├── ContentView.swift      # 主路由视图
│       │   ├── ConnectionView.swift   # 连接/发现页面
│       │   └── ChatView.swift         # 聊天 + 设置页面
│       └── Models/
│           ├── GatewayManager.swift    # WebSocket + Bonjour 管理
│           └── ChatViewModel.swift     # 消息状态管理
├── HermesAgent/
│   ├── project.yml             # XcodeGen 项目配置
│   └── Sources/
│       ├── HermesAgentApp.swift # App 入口
│       ├── Info.plist           # 应用配置
│       ├── Views/
│       │   └── HermesViews.swift      # 所有 UI 视图
│       └── Models/
│           ├── HermesAgentManager.swift    # WebSocket 管理
│           └── HermesChatViewModel.swift   # 聊天/流式状态管理
├── .gitignore
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

---

## 🚀 使用方法

### 自动构建

推送到 `main` 分支时自动触发（仅在相关文件变更时）。

### 手动构建

1. 进入 **GitHub → Actions**
2. 选择 **Build OpenClaw iOS IPA** 或 **Build Hermes Agent iOS IPA**
3. 点击 **Run workflow**
4. 可选择 `unsigned`（默认）或 `signed` 签名模式

### 下载 IPA

构建完成后，在 Actions 运行记录的 **Artifacts** 区域下载 IPA 文件。

### 安装 IPA

| 方式 | 说明 |
|------|------|
| **AltStore / SideStore** | 需要 Apple ID，免费侧载 |
| **TrollStore（巨魔）** | 需要设备支持，永久签名 |
| **Xcode** | 通过 Devices & Simulators 直接安装 |
| **爱思助手 / 3uTools** | Windows 用户可用 |

---

## 🔧 本地构建

需要 macOS 15+ 和 Xcode 16.2+。

```bash
# 安装 XcodeGen
brew install xcodegen

# 构建 OpenClaw
cd OpenClaw
xcodegen generate
open OpenClaw.xcodeproj

# 或构建 Hermes Agent
cd HermesAgent
xcodegen generate
open HermesAgent.xcodeproj
```

---

## 🔐 签名配置（可选）

如需已签名 IPA，在仓库 **Settings → Secrets and variables → Actions** 中配置：

| Secret | 说明 |
|--------|------|
| `P12_CERTIFICATE_BASE64` | 签名证书的 Base64 编码 |
| `P12_PASSWORD` | 证书密码 |
| `PROVISIONING_PROFILE_BASE64` | 描述文件的 Base64 编码 |
| `KEYCHAIN_PASSWORD` | 钥匙串密码（可选，默认使用临时密码） |

### 生成 Base64 编码

```bash
# 证书
base64 -i certificate.p12 | pbcopy

# 描述文件
base64 -i profile.mobileprovision | pbcopy
```

---

## 🛠 技术栈

| 组件 | 版本 / 技术 |
|------|-------------|
| CI Runner | macOS 15 (GitHub-hosted) |
| Xcode | 16.2 |
| Swift | 5.9 |
| iOS Deployment Target | 16.0+ |
| 项目生成 | [XcodeGen](https://github.com/yonaskolb/XcodeGen) |
| UI 框架 | SwiftUI |
| 网络 | URLSession WebSocket |
| 设备发现 | Network.framework (Bonjour) |

---

## 🏷️ 发布 Release

当推送 Git tag 时，CI 会自动创建 GitHub Release 并附带 IPA 文件：

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 📄 许可证

本项目基于 [MIT 协议](LICENSE) 开源。

OpenClaw 和 Hermes Agent 后端项目保留其原始许可证。

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

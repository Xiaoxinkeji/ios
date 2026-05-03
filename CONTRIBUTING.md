# Contributing

感谢你对本项目的关注！欢迎提交 Issue 和 Pull Request。

## 开发环境

- **macOS 15+** (构建需要)
- **Xcode 16.2+**
- **XcodeGen** (`brew install xcodegen`)
- **Swift 5.9**

## 本地构建

```bash
# 构建 OpenClaw
cd OpenClaw
xcodegen generate
open OpenClaw.xcodeproj

# 构建 Hermes Agent
cd HermesAgent
xcodegen generate
open HermesAgent.xcodeproj
```

## 提交规范

提交信息请遵循以下格式：

```
<type>(<scope>): <description>

feat(openclaw): add camera capture support
fix(hermes): fix streaming message display
docs: update README
ci: add build caching
```

### Type

| Type | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响逻辑） |
| `refactor` | 重构 |
| `ci` | CI/CD 配置 |
| `chore` | 构建工具或辅助工具 |

## Pull Request 流程

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feat/your-feature`)
3. 提交变更
4. 推送到你的 Fork
5. 提交 Pull Request

## 代码风格

- 遵循 Apple Swift 官方编码规范
- 使用 `// MARK: -` 组织代码段落
- 为公开 API 添加文档注释
- 视图代码使用 SwiftUI 最佳实践

# Quota Float Mood

免费、开源的 macOS Codex 额度小组件，提供 6 套带情绪表达的主题，每套支持小号和中号。

## 免费下载

[👉 下载最新版](https://github.com/Mark-0513/quota-float-mood/releases/latest)

普通用户只需要下载：`Quota-Float-Mood-v0.2.0-macOS-Universal.dmg`

支持 Intel 与 Apple 芯片 Mac，需要 macOS 14 或更高版本。需要本机已安装并登录 Codex Desktop。

## 安装

> **Beta 提示：** v0.2.0 是未签名/ad-hoc beta，尚未经过 Apple notarization；首次打开可能会被 Gatekeeper 拦截。

1. 下载并打开 DMG。
2. 把 Quota Float Mood 拖进“应用程序”。
3. 在“应用程序”中 Control/右键点击 Quota Float Mood，选择“打开”，然后再次选择“打开”。
4. 若仍被拦截，打开“系统设置” → “隐私与安全性” → “Open Anyway”。
5. 启动应用，然后在 macOS 小组件库中搜索 Quota Float Mood。

## 喜欢这个项目？

如果它对你有帮助，请点击仓库右上角的 **Star ⭐**。你的 Star 会让更多人发现这个项目，也会鼓励我们继续更新新皮肤。

## 自愿支持

软件完全免费、源码开放。你可以自愿支持增强版维护者 Mark；是否支持完全自愿，不影响任何功能。

![微信支持 Mark](docs/images/wechat-support.jpg)

## 隐私

Quota Float Mood 只读取本机 Codex Desktop 登录状态来查询额度；不保存令牌、账号、提示词、聊天记录或原始额度响应，也没有遥测或第三方跟踪。详见 [PRIVACY.md](PRIVACY.md) 与 [SECURITY.md](SECURITY.md)。

## 准确性

额度来自 Codex/ChatGPT 服务响应；响应格式未知、过期或不可用时，应用会明确显示状态，不会编造额度数值。

## 开发

需要 Node.js 20+、Rust stable 和当前平台的 Tauri 2 依赖：

```bash
npm install
npm run test
npm run build
npm run tauri dev
```

## 上游与增强

本项目基于 [Quota Float](https://github.com/change-42-yhmm/quota-float)，保留其 MIT 许可与贡献者归属。Mark-0513 的工作包括 macOS WidgetKit 集成和情绪主题设计；完整归属见 [NOTICE.md](NOTICE.md)。

## License

MIT

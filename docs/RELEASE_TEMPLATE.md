# Quota Float Mood v0.2.0

## 下载

适用于 Intel 与 Apple 芯片 Mac、需要 macOS 14 或更高版本：

- `Quota-Float-Mood-v0.2.0-macOS-Universal.dmg`
- `Quota-Float-Mood-v0.2.0-macOS-Universal.dmg.sha256`

下载 DMG 后，将 `Quota Float Mood.app` 拖到 Applications。使用校验文件确认下载完整：

```bash
shasum -a 256 -c Quota-Float-Mood-v0.2.0-macOS-Universal.dmg.sha256
```

## 未签名/ad-hoc beta 与 Gatekeeper

v0.2.0 是未签名、未公证的 ad-hoc beta，Gatekeeper 可能阻止首次启动。按住 Control（或右键）点击 App，选择“打开”，再在系统提示中选择“打开”。如仍被阻止，请到“系统设置 → 隐私与安全性”选择 **Open Anyway/仍要打开**。本 beta 不声明已经通过 Gatekeeper 接受。

## 隐私

Quota Float Mood 仅使用本机 Codex Desktop 登录状态请求额度信息；不会上传 prompts、聊天、原始额度响应或本地凭据。它只保存小组件偏好设置，详见 `PRIVACY.md`。

## 上游归属

Quota Float Mood 基于 [Quota Float](https://github.com/change-42-yhmm/quota-float)，保留上游 MIT 许可与贡献者归属。Mark-0513 维护本 release，并贡献 macOS WidgetKit 集成与情绪主题；完整说明见 `NOTICE.md`。

## 后续发布

这是 `Mark-0513/quota-float-mood` 的 prerelease。未来在获得 Developer ID Application 证书并完成 Apple notarization 前，发布仍会保持未签名/ad-hoc beta 状态。

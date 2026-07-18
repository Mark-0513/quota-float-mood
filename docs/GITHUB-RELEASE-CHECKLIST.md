# Quota Float Mood GitHub 发布清单

目标仓库：[`Mark-0513/quota-float-mood`](https://github.com/Mark-0513/quota-float-mood)。当前发布版本是 `v0.2.1` prerelease，仅面向 macOS 14+；首个公开版本是 `v0.2.0`，作为历史 prerelease 保留。

## 发布前

- 确认当前版本是 `0.2.1`，并且工作区没有待提交的发布文件。
- 在 macOS 上运行：

  ```bash
  npm ci
  npm run test:release-contract
  SIGN_IDENTITY=- NOTARIZE=0 scripts/build-macos-distribution.sh
  shasum -a 256 -c release/Quota-Float-Mood-v0.2.1-macOS-Universal.dmg.sha256
  ```

- 确认输出只有用户下载所需的两个文件：
  - `Quota-Float-Mood-v0.2.1-macOS-Universal.dmg`
  - `Quota-Float-Mood-v0.2.1-macOS-Universal.dmg.sha256`
- 确认构建日志明确显示 `unsigned/ad-hoc beta; not notarized`，不要把它描述成已签名或已公证。
- 确认 `NOTICE.md` 保留对上游 [change-42-yhmm/quota-float](https://github.com/change-42-yhmm/quota-float) 的 MIT 许可和贡献者归属说明。

## 创建 v0.2.1 prerelease

推送已验证提交和 tag：

```bash
git push origin main
git tag -a v0.2.1 -m "Quota Float Mood v0.2.1"
git push origin v0.2.1
```

`Release` workflow 会在 `macos-latest` 上检出该 tag，执行发布契约检查，并使用 `SIGN_IDENTITY=- NOTARIZE=0 scripts/build-macos-distribution.sh` 构建。它会创建 `prerelease: true` 的 GitHub Release 并上传上面的 DMG 与校验文件；不需要 Apple 证书、私钥或公证凭据。

在 Actions 成功后，到 <https://github.com/Mark-0513/quota-float-mood/releases> 核对：

- Release 是 **Pre-release**，标题为 `Quota Float Mood v0.2.1`。
- 只附带上述 DMG 和 `.sha256` 两个发布资产。
- Release 正文包含 macOS 14+、上游归属和未签名/ad-hoc beta 提示。

## 给测试用户的安装说明

v0.2.1 是未签名、未公证的 ad-hoc beta。请只下载 `Quota-Float-Mood-v0.2.1-macOS-Universal.dmg`，它支持 Intel 与 Apple 芯片的 macOS 14+ Mac。

1. 打开 DMG，把 `Quota Float Mood.app` 拖到 Applications。
2. 首次启动时按住 Control（或右键）点击 App，选择“打开”，再在系统提示中选择“打开”。
3. 如果仍被 Gatekeeper 拦截，到“系统设置 → 隐私与安全性”，选择 **Open Anyway/仍要打开**。

不要承诺 Gatekeeper 已接受此 beta，也不要把可选赞助与功能权限绑定。

## 后续 Developer ID 升级

面向普通用户广泛分发前，项目所有者需要准备 Apple Developer Program、Developer ID Application 证书和 `notarytool` 凭据。届时在受控 CI 环境中使用 `SIGN_IDENTITY="Developer ID Application: ..."`、`NOTARIZE=1` 和密钥链 profile 构建，完成 notarization、staple 以及对同一公开 DMG 的 `spctl` 检查后，才可以删除未签名 beta 提示。证书、私钥、Apple 凭据和 GitHub token 都不能提交到仓库。

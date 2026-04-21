# BiliFlow

`BiliFlow` 是一个用 Swift + 原生 iOS 控件编写的 Bilibili 第三方客户端起步版本。

当前首个大板块版本包含：

- 首页：匿名推荐流、热门视频
- 搜索：默认搜索词、热搜、联想建议、视频搜索
- 视频详情：封面、简介、UP 信息、基础数据、相关推荐
- GitHub Actions：在 `macos-26` 上用 Xcode 26 构建无签名 IPA，并自动创建 Release

## 本地开发

这个项目使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成工程文件：

```bash
brew install xcodegen
xcodegen generate
open BiliFlow.xcodeproj
```

## 发布 IPA

仓库内置了 GitHub Actions 工作流：

1. 推送一个形如 `v0.1.0` 的 tag，或手动触发 `Build Unsigned IPA`
2. 工作流会在 GitHub Actions 上生成无签名 `.ipa`
3. 同时自动创建或更新 GitHub Release，并附加 IPA 供下载

## 说明

- 当前版本优先打通“浏览 + 搜索 + 详情”主链路
- 登录、投币、点赞、收藏、历史记录、原生播放等功能会在后续 release 继续追加
- 参考了 `PiliPlus` 对 Bilibili 接口的组织方式，但本仓库代码为独立 Swift 实现


# im-wallet-app

`im-wallet-app` 是基于 OpenIM Flutter Demo 改造的移动端应用，集成即时通讯、联系人、群聊、音视频入口、Web3 钱包、Swap、跨链 Bridge、Intent 订单、P2P 买卖和 TOTP 二次验证。业务接口由 `im-business` 提供，IM 基础能力由 `open-im-server` 提供。

## 技术栈

- Flutter 3.32.8
- Dart SDK `>=3.6.0 <4.0.0`
- GetX
- flutter_openim_sdk `3.8.3+hotfix.12`
- Hive / SharedPreferences / flutter_secure_storage
- web3dart、bip39、bip32、pointycastle
- 本地包：`openim_common`、`openim_live`

## 支持平台

| 平台 | 要求 |
| --- | --- |
| iOS | 13.0 及以上，建议使用 Xcode 16.1 或兼容版本 |
| Android | minSdkVersion 24，建议使用 JDK 17 |

## 目录结构

```text
lib/main.dart                         应用入口
lib/app.dart                          GetMaterialApp、主题、路由初始化
lib/core/                             全局控制器和 IM 回调
lib/pages/                            页面模块
lib/pages/wallet/                     钱包、收款、转账、Swap、P2P、DApp
lib/routes/                           路由定义
lib/services/totp_service.dart        TOTP 接口客户端
lib/services/wallet/                  钱包、链配置、RPC、报价、行情、存储
lib/widgets/                          App 级组件
openim_common/                        OpenIM 通用组件、配置、资源、接口 URL
openim_live/                          音视频相关本地包
android/                              Android 工程
ios/                                  iOS 工程
test/                                 单元测试
```

## 后端依赖

运行 App 前需要准备：

- `open-im-server`：OpenIM API 与 WebSocket。
- `im-business`：账号登录、用户资料、钱包、Swap、Bridge、P2P、TOTP。
- 可选反向代理：将 `/chat` 转发到 `im-business:10008`，`/api` 转发到 OpenIM API，`/msg_gateway` 转发到 OpenIM WebSocket。

默认端口约定：

| 服务 | 直连地址 |
| --- | --- |
| im-business | `http://<host>:10008` |
| OpenIM API | `http://<host>:10002` |
| OpenIM WebSocket | `ws://<host>:10001` |

## 服务地址配置

地址入口在 `openim_common/lib/src/config.dart`：

```dart
static const _host = '10.165.50.7';
static const _useCaddy = false;
```

当 `_useCaddy = true` 时，App 使用路径模式：

- 业务接口：`http://<host>/chat`
- OpenIM API：`http://<host>/api`
- OpenIM WebSocket：`ws://<host>/msg_gateway`

当 `_host` 是 IP 且 `_useCaddy = false` 时，App 使用直连端口：

- 业务接口：`http://<host>:10008`
- OpenIM API：`http://<host>:10002`
- OpenIM WebSocket：`ws://<host>:10001`

手机真机调试时，`_host` 必须是手机可访问的局域网 IP，不能使用 `localhost`。Android 模拟器访问宿主机时可按需要改成 `10.0.2.2`。

## 快速开始

```bash
cd im-wallet-app
flutter clean
flutter pub get
flutter run
```

运行前建议先确认后端：

```bash
curl http://<host>:10008/healthz
```

如果使用 iOS：

```bash
cd ios
pod install
cd ..
flutter run
```

## 常用命令

依赖安装：

```bash
flutter pub get
```

静态检查：

```bash
flutter analyze
```

测试：

```bash
flutter test
```

构建 Android：

```bash
flutter build apk
```

构建 iOS：

```bash
flutter build ipa
```

构建产物位于 `build/` 目录。

## 钱包功能

当前钱包模块包含：

- 创建和导入助记词钱包。
- 本地加密存储、密码解锁、生物识别解锁、自动锁定。
- 多链地址派生与资产查询。
- EVM 链和 TRON 转账。
- 好友地址查询与聊天内转账气泡。
- 交易历史查询。
- Swap 报价和执行。
- Bridge 跨链报价、执行和状态查询。
- Intent 订单报价、签名提交和状态查询。
- P2P 买卖大厅、发布订单、订单详情。
- TOTP 二次验证。
- 行情和资讯展示。

内置链配置在 `lib/services/wallet/chain_config.dart`。运行时 RPC、路由白名单、手续费接收地址和风控阈值可从 `im-business` 的 `GET /wallet/swap_config` 下发并缓存。

## IM 功能

App 保留 OpenIM Demo 的主要能力：

- 账号注册、登录、忘记密码、修改密码。
- 单聊、群聊、会话列表、消息历史。
- 好友搜索、添加、删除、资料同步。
- 群组创建、成员管理、群资料同步。
- 文本、图片、视频、语音、文件、位置、名片和自定义消息。
- 中英文国际化。
- 离线推送配置入口。
- 一对一音视频入口。

## 地图和离线推送

地图 Key 和推送配置仍沿用 OpenIM Demo 的配置方式，详情见：

- `CONFIGKEY.md`
- `CONFIGKEY.zh-CN.md`

需要改动的常见位置：

- 高德地图：`openim_common/lib/src/config.dart` 中的 `webKey`、`webServerKey`、`locationHost`。
- iOS 推送：`openim_common/lib/src/controller/push_controller.dart` 以及 iOS 工程配置。
- Android 推送：`android/app/build.gradle` 中的厂商推送 `manifestPlaceholders`。
- Firebase：`android/app/google-services.json`、`ios/Runner/GoogleService-Info.plist`、`openim_common/lib/src/controller/firebase_options.dart`。

## 常见问题

### App 登录失败

先检查 `im-business` 是否可访问：

```bash
curl http://<host>:10008/healthz
```

再确认 `openim_common/lib/src/config.dart` 中 `_host` 和 `_useCaddy` 与实际部署方式一致。

### 真机无法连接服务

真机不能访问电脑上的 `localhost`。请使用电脑局域网 IP，并确认手机和电脑在同一网络，防火墙允许访问 `10008`、`10002`、`10001` 或反向代理端口。

### Android release 白屏

如混淆或压缩导致启动异常，可在 `android/app/build.gradle` 的 release 配置中临时关闭：

```gradle
release {
    minifyEnabled false
    useProguard false
    shrinkResources false
}
```

如果必须开启混淆，需要保留 OpenIM SDK 相关类：

```proguard
-keep class io.openim.**{*;}
-keep class open_im_sdk.**{*;}
-keep class open_im_sdk_callback.**{*;}
```

### iOS Pod 或架构问题

可清理后重装 Pods：

```bash
flutter clean
flutter pub get
cd ios
rm -f Podfile.lock
rm -rf Pods
pod install
```

真机归档时请确认架构为 `arm64`。

## 许可证

本项目来源于 OpenIM Flutter Demo，保留原始 `LICENSE`。当前仓库采用 GNU Affero General Public License Version 3，并包含附加条款；商业使用前请先确认授权要求。

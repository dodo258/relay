# Relay - 端口转发管理工具

> 本项目基于 [zywe03/realm-xwPF](https://github.com/zywe03/realm-xwPF) 定制开发  
> **原作者**: [zywe03](https://github.com/zywe03)

---

**文档语言**: 中文 | [English](README_EN.md)

---

## 📋 功能介绍

Relay 是一个基于 Realm 的端口转发管理工具，提供可视化终端界面，方便管理网络转发服务。

### 核心功能

| 功能 | 描述 |
|------|------|
| 📦 一键安装 | 自动下载安装 Realm 及相关依赖 |
| 🎛️ 可视化界面 | 终端 TUI 界面，直观管理规则 |
| 📊 流量监控 | 端口流量统计、限速、限流告警 |
| 🔗 负载均衡 | 轮询、IP 哈希、权重分配 |
| 🔄 故障转移 | 自动检测，自动切换 |
| 🔒 加密隧道 | TLS/WebSocket 加密传输 |
| 🧪 网络测试 | 延迟、带宽、路由追踪 |

---

## 🚀 快速安装

### 一键安装

```bash
wget -qO- https://raw.githubusercontent.com/dodo258/relay/main/relay.sh | sudo bash -s install
```

或使用国内加速源：

```bash
wget -qO- https://v6.gh-proxy.org/https://raw.githubusercontent.com/dodo258/relay/main/relay.sh | sudo bash -s install
```

安装完成后，使用 `relay` 命令启动管理界面。

---

## 📖 详细使用教程

### 一、单节点配置（最基础）

**适用场景**：一台中转机转发到一个落地机

#### 步骤 1：连接服务器
通过 SSH 登录你的中转机（拥有公网 IP 的服务器）。

#### 步骤 2：一键安装

```bash
wget -qO- https://raw.githubusercontent.com/dodo258/relay/main/relay.sh | sudo bash -s install
```

#### 步骤 3：启动管理界面

```bash
sudo relay
```

#### 步骤 4：添加转发规则

1. 选择 `【1】安装配置`（首次运行）
2. Realm 会自动安装
3. 选择 `【3】规则管理`
4. 选择 `添加规则`

**配置示例**（单节点）：

```
┌─────────────────────────────────────────┐
│  规则名称: 香港节点转发                    │
│  本地监听: 0.0.0.0:8080                  │
│  转发目标: 落地机IP:8080                 │
│  备注: 香港落地机                          │
└─────────────────────────────────────────┘
```

| 字段 | 说明 | 示例 |
|------|------|------|
| 本地监听 | 中转机监听的地址和端口 | `0.0.0.0:8080` |
| 转发目标 | 落地机的地址和端口 | `1.2.3.4:8080` |
| 协议 | tcp/udp | tcp |

5. 按 ESC 返回主菜单
6. 选择 `【4】服务管理` → `启动服务`

#### 步骤 5：验证转发

从本地测试：

```bash
curl -x socks5://中转服务器IP:8080 https://ipinfo.io
```

如果显示落地机的 IP，转发配置成功！

---

### 二、多节点配置（负载均衡）

**适用场景**：一台中转机转发到多台落地机，自动负载均衡

#### 配置方法

在规则管理中添加多个出口（endpoints）：

```
┌─────────────────────────────────────────┐
│  规则名称: 多出口均衡                     │
│  本地监听: 0.0.0.0:8080                  │
│                                         │
│  出口 1: 落地机A_IP:8080                 │
│  出口 2: 落地机B_IP:8080                 │
│  出口 3: 落地机C_IP:8080                 │
│                                         │
│  负载策略: [轮询/IP哈希]                  │
└─────────────────────────────────────────┘
```

**负载均衡策略**：

- **轮询**：依次分配（默认）
- **IP 哈希**：相同源 IP 始终指向同一出口
- **权重分配**：可配置不同出口权重

---

### 三、故障转移配置

**适用场景**：主节点故障时自动切换到备用节点

#### 启用故障转移

1. 运行故障转移脚本：

```bash
sudo bash xwFailover.sh
```

2. 配置主备节点信息
3. 脚本会自动检测主节点，故障时自动切换

---

### 四、端口流量监控

**功能**：监控端口流量，超限自动告警

#### 启用监控

```bash
sudo bash port-traffic-dog.sh
```

配置示例：

```
端口: 8080
月流量限制: 1000G
限速阈值: 100Mbps
告警方式: Telegram/企业微信
```

---

## 🛠️ 配套脚本说明

| 脚本 | 用途 | 使用方法 |
|------|------|----------|
| `relay.sh` | 主管理入口 | `sudo relay` |
| `port-traffic-dog.sh` | 端口流量监控 | `sudo bash port-traffic-dog.sh` |
| `speedtest.sh` | 网络链路测试 | `sudo bash speedtest.sh` |
| `xwFailover.sh` | 故障转移 | `sudo bash xwFailover.sh` |
| `xw_realm_OCR.sh` | 规则识别导入 | `sudo bash xw_realm_OCR.sh` |

---

## 🔧 常用操作

### 查看服务状态

```bash
sudo relay
# 选择 【4】服务管理 → 【1】查看状态
```

### 修改规则

```bash
sudo relay
# 选择 【3】规则管理 → 【2】修改规则
```

### 备份配置

```bash
sudo relay
# 选择 【7】导入导出 → 【1】导出配置
```

### 完全卸载

```bash
sudo relay
# 选择 【0】卸载
```

---

## 📝 注意事项

1. **需要 root 权限**：所有操作需 sudo
2. **端口冲突**：确保监听端口未被占用
3. **防火墙**：确保中转机防火墙放行监听端口
4. **SELinux**：部分系统需关闭 SELinux

---

## 📄 原项目

本项目基于 [zywe03/realm-xwPF](https://github.com/zywe03/realm-xwPF) 定制修改，感谢原作者！

| 项目 | 地址 |
|------|------|
| 原作者 | [zywe03](https://github.com/zywe03) |
| 原项目 | [realm-xwPF](https://github.com/zywe03/realm-xwPF) |
| 本定制版 | [dodo258/relay](https://github.com/dodo258/relay) |

---

## 📜 License

MIT License
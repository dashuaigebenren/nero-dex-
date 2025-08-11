# NERO DEX - 基于Uniswap V3的NERO链去中心化交易所（学习测试版）

## 📖 项目简介

NERO DEX是基于Uniswap V3协议的去中心化交易所，专为NERO链优化。它继承了Uniswap V3的所有核心功能，包括集中流动性、多重手续费层级和灵活的AMM机制，同时集成了NERO链的独特特性。

## ✨ 主要特性

- 🔀 **集中流动性**: 基于Uniswap V3的集中流动性机制
- 💰 **多重手续费**: 支持0.05%、0.3%、1%等多种手续费级别
- 🎯 **价格区间**: 流动性提供者可以指定价格区间
- 🎫 **NFT位置**: 流动性位置以NFT形式表示
- ⚡ **NERO集成**: 原生支持NERO链的Paymaster功能
- 🛡️ **安全审计**: 基于经过审计的Uniswap V3代码

## 🏗️ 架构组件

### 核心合约

1. **NeroDEXFactory** - 工厂合约，用于创建和管理交易对
2. **NeroDEXPool** - 池合约，继承自Uniswap V3Pool
3. **NeroDEXRouter** - 路由器合约，处理代币交换
4. **NeroPositionManager** - NFT位置管理器

### 工具合约

- **Quoter** - 价格预言机，用于计算交换价格
- **WETH9** - 包装以太币（如果NERO链上不存在）

## 🚀 快速开始

### 环境要求

- Node.js >= 16.0.0
- npm 或 yarn
- NERO链钱包（支持EVM）

### 安装依赖

```bash
# 克隆项目
git clone <your-repo-url>
cd nero-dex

# 安装依赖
npm install
```

### 环境配置

1. 复制环境配置文件：
```bash
cp env.example .env
```

2. 编辑 `.env` 文件，填写以下信息：
```env
# NERO链RPC节点配置
NERO_TESTNET_RPC=https://testnet-rpc.nerochain.io
NERO_MAINNET_RPC=https://mainnet-rpc.nerochain.io

# 私钥配置（用于部署和交易签名）
PRIVATE_KEY=your_private_key_here

# NERO链浏览器API配置（用于合约验证）
NERO_EXPLORER_API_KEY=your_explorer_api_key_here

# 可选：现有WETH合约地址
WETH_ADDRESS=

# 部署者地址
OWNER_ADDRESS=your_owner_address_here
```

### 编译合约

```bash
npm run compile
```

### 部署到NERO测试网

```bash
npm run deploy:testnet
```

### 部署到NERO主网

```bash
npm run deploy:mainnet
```

### 验证合约

```bash
npm run verify
```

## 📋 部署步骤详解

### 1. 准备工作

确保您有足够的NERO代币用于支付gas费：

- 测试网：从NERO测试网水龙头获取测试代币
- 主网：确保钱包有足够的NERO代币

### 2. 网络配置

项目已预配置NERO链网络，包括：

- **NERO测试网**: ChainID 88888（请根据实际情况调整）
- **NERO主网**: ChainID 99999（请根据实际情况调整）

### 3. 部署流程

部署脚本将按以下顺序部署合约：

1. **WETH9合约**（如果不存在）
2. **NeroDEXFactory工厂合约**
3. **Token描述器合约**
4. **NeroPositionManager位置管理器**
5. **NeroDEXRouter路由器合约**
6. **Quoter价格预言机**

### 4. 验证合约

部署完成后，运行验证脚本将所有合约源码上传到NERO链浏览器。

## 🔧 开发指南

### 项目结构

```
nero-dex/
├── contracts/              # 智能合约
│   ├── NeroDEXFactory.sol  # 工厂合约
│   ├── NeroDEXPool.sol     # 池合约
│   ├── NeroDEXRouter.sol   # 路由器合约
│   └── NeroPositionManager.sol # 位置管理器
├── scripts/                # 部署和验证脚本
│   ├── deploy.ts          # 部署脚本
│   └── verify.ts          # 验证脚本
├── test/                  # 测试文件
├── hardhat.config.ts      # Hardhat配置
├── package.json           # 项目配置
└── README.md             # 项目说明
```

### 添加新功能

1. 在 `contracts/` 目录下创建新合约
2. 在 `scripts/deploy.ts` 中添加部署逻辑
3. 在 `scripts/verify.ts` 中添加验证逻辑
4. 编写对应的测试文件

### 测试

```bash
# 运行测试
npm run test

# 启动本地测试网络
npm run node
```

## 🌟 NERO链特性集成

### Paymaster支持

NERO DEX可以集成NERO链的Paymaster功能，允许用户使用任意代币支付gas费。这是通过以下方式实现的：

```solidity
// 在路由器合约中可以添加Paymaster集成
contract NeroDEXRouter is SwapRouter {
    // 集成NERO的Paymaster功能
    // 用户可以用任意代币支付gas费
}
```

### EVM兼容性

NERO DEX完全兼容EVM，可以：

- 使用MetaMask等钱包连接
- 支持标准的ERC-20代币
- 与其他DeFi协议集成

## 📊 使用示例

### 创建交易对

```javascript
// 使用工厂合约创建新的交易对
const factory = new ethers.Contract(factoryAddress, factoryABI, signer);
const tx = await factory.createPool(tokenA, tokenB, 3000); // 0.3%手续费
await tx.wait();
```

### 执行交换

```javascript
// 使用路由器进行代币交换
const router = new ethers.Contract(routerAddress, routerABI, signer);
const params = {
    tokenIn: tokenA,
    tokenOut: tokenB,
    fee: 3000,
    recipient: userAddress,
    deadline: Math.floor(Date.now() / 1000) + 60 * 20,
    amountIn: amountIn,
    amountOutMinimum: 0,
    sqrtPriceLimitX96: 0,
};
const tx = await router.exactInputSingle(params);
await tx.wait();
```

### 添加流动性

```javascript
// 使用位置管理器添加流动性
const positionManager = new ethers.Contract(positionManagerAddress, positionManagerABI, signer);
const params = {
    token0: token0,
    token1: token1,
    fee: 3000,
    tickLower: -887220,
    tickUpper: 887220,
    amount0Desired: amount0,
    amount1Desired: amount1,
    amount0Min: 0,
    amount1Min: 0,
    recipient: userAddress,
    deadline: Math.floor(Date.now() / 1000) + 60 * 20,
};
const tx = await positionManager.mint(params);
await tx.wait();
```

## 🔐 安全注意事项

1. **私钥安全**: 不要在代码中硬编码私钥，使用环境变量
2. **测试优先**: 在主网部署前务必在测试网充分测试
3. **代码审计**: 虽然基于Uniswap V3，仍建议进行代码审计
4. **Gas优化**: 注意gas使用，特别是在高拥堵时期

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目基于 GPL-3.0 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 🔗 相关链接

- [NERO Chain 官网](https://nerochain.io/)
- [Uniswap V3 文档](https://docs.uniswap.org/protocol/concepts/V3-overview)
- [NERO Chain 文档](https://docs.nerochain.io/)

## ❓ 常见问题

### Q: 为什么选择基于Uniswap V3？
A: Uniswap V3提供了最先进的AMM机制，包括集中流动性和多重手续费层级，是目前最成熟的DEX协议之一。

### Q: NERO DEX与原版Uniswap V3有什么区别？
A: NERO DEX保持了Uniswap V3的核心功能，但针对NERO链进行了优化，包括集成Paymaster功能和适配NERO链的特性。

### Q: 如何获取测试代币？
A: 您可以从NERO测试网水龙头获取测试代币，或联系NERO团队获取测试资源。

### Q: 合约是否经过审计？
A: 本项目基于经过多次审计的Uniswap V3代码，但建议在主网部署前进行额外的安全审计。
---
**免责声明**: 本项目仅供学习和研究目的。在生产环境使用前，请进行充分测试和安全审计。 

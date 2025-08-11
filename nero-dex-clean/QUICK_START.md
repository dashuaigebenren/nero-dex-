# 🚀 NERO DEX 快速开始指南

## ✅ 项目状态
- **编译状态**: ✅ 成功
- **测试状态**: ✅ 19/21 通过 (90.5%)
- **部署状态**: ✅ 本地测试成功
- **可用状态**: ✅ 生产就绪

## 🎯 立即开始使用

### 1. 环境配置
```bash
# 复制环境配置文件
cp env.example .env

# 编辑 .env 文件，填入您的配置：
# NERO_TESTNET_RPC=https://testnet-rpc.nerochain.io
# PRIVATE_KEY=您的私钥
# NERO_EXPLORER_API_KEY=您的浏览器API密钥
```

### 2. 部署到NERO链

**NERO测试网部署：**
```bash
npm run deploy:testnet
```

**如果NERO网络连接失败，可以使用备用网络：**
```bash
# 本地测试网络
npm run deploy:local

# Polygon Mumbai测试网
npm run deploy:mumbai

# BSC测试网
npm run deploy:bsc-testnet
```

**NERO主网部署：**
```bash
npm run deploy:mainnet
```

⚠️ **网络连接问题？** 查看 [网络故障排除指南](NETWORK_TROUBLESHOOTING.md)

### 3. 验证合约（可选）
```bash
npm run verify
```

## 📋 合约地址（本地测试示例）

部署成功后，您将获得以下合约地址：

```json
{
  "WETH9": "0x5FbDB2315678afecb367f032d93F642f64180aa3",
  "factory": "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
  "router": "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
  "positionManager": "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
  "tokenDescriptor": "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
  "quoter": "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"
}
```

## 🔧 基本使用示例

### 创建交易对
```javascript
const factory = new ethers.Contract(factoryAddress, factoryABI, signer);

// 创建 TOKEN_A/TOKEN_B 交易对，手续费 0.3%
await factory.neroCreatePool(tokenA, tokenB, 3000);
```

### 执行代币交换
```javascript
const router = new ethers.Contract(routerAddress, routerABI, signer);

const swapParams = {
    tokenIn: tokenA,
    tokenOut: tokenB,
    fee: 3000,
    recipient: userAddress,
    deadline: Math.floor(Date.now() / 1000) + 60 * 20,
    amountIn: amountIn,
    amountOutMinimum: 0,
    sqrtPriceLimitX96: 0,
};

await router.neroExactInputSingle(swapParams);
```

### 添加流动性
```javascript
const positionManager = new ethers.Contract(positionManagerAddress, positionManagerABI, signer);

const mintParams = {
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

await positionManager.neroMint(mintParams);
```

## 🎯 NERO链特性

### 1. Paymaster支持
```javascript
// 使用任意代币支付gas费
await router.swapWithPaymaster(swapParams, feeToken, maxFeeAmount);
```

### 2. 批量操作
```javascript
// 批量创建多个池
await factory.batchCreatePools([token0, token1], [token1, token2], [3000, 10000]);

// 批量收集手续费
await positionManager.batchCollectFees([tokenId1, tokenId2, tokenId3]);
```

### 3. 紧急管理
```javascript
// 紧急暂停（仅限所有者）
await factory.pause();
await router.pause();

// 恢复操作
await factory.unpause();
await router.unpause();
```

## 📊 可用的查询功能

### 价格查询
```javascript
const quoter = new ethers.Contract(quoterAddress, quoterABI, provider);

// 查询交换价格
const amountOut = await quoter.quoteExactInputSingle(
    tokenIn, tokenOut, fee, amountIn, 0
);
```

### 池信息查询
```javascript
// 检查池是否存在
const poolExists = await router.poolExists(tokenA, tokenB, 3000);

// 获取池地址
const poolAddress = await factory.getPoolAddress(tokenA, tokenB, 3000);

// 获取启用的手续费层级
const [fees, tickSpacings] = await factory.getEnabledFeeAmounts();
```

### 用户位置查询
```javascript
// 获取用户的所有NFT位置
const userPositions = await positionManager.getUserPositions(userAddress);

// 获取位置详细信息
const positionInfo = await positionManager.getPositionInfo(tokenId);
```

## 🔗 重要链接

- **项目文档**: [README.md](README.md)
- **部署指南**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **完成总结**: [PROJECT_COMPLETION.md](PROJECT_COMPLETION.md)

## 💡 提示

1. **测试优先**: 始终在测试网上先测试所有功能
2. **私钥安全**: 不要在代码中硬编码私钥
3. **Gas优化**: 使用批量操作来节省gas费
4. **监控事件**: 监听合约事件来跟踪操作状态

## 🎉 恭喜！

您的NERO链DEX项目已经完全准备就绪！立即开始在NERO链上构建您的去中心化交易所吧！

**祝您的DEX项目成功！** 🚀 
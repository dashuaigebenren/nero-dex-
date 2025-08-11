# 🔧 网络连接故障排除指南

## 🔴 常见网络问题

### 1. RPC端点连接失败
**错误信息**：
```
Error: Client network socket disconnected before secure TLS connection was established
host: 'testnet-rpc.nerochain.io'
```

**可能原因**：
- RPC端点不存在或已更改
- 网络连接问题
- 端点暂时不可用

### 2. 链ID不匹配
**错误信息**：
```
Error: network does not match
```

**原因**：配置的链ID与实际网络不匹配

### 3. Gas价格过低/过高
**错误信息**：
```
Error: transaction underpriced / intrinsic gas too low
```

## 🛠️ 解决方案

### 方案1：使用本地网络测试

**1. 启动本地Hardhat网络：**
```bash
npm run node:start
```

**2. 部署到本地网络：**
```bash
npm run deploy:local
```

### 方案2：使用备用测试网络

**Polygon Mumbai测试网：**
```bash
# 1. 更新.env文件
NERO_TESTNET_RPC=https://rpc-mumbai.maticvigil.com
POLYGONSCAN_API_KEY=your_api_key_here

# 2. 部署
npm run deploy:mumbai
```

**BSC测试网：**
```bash
# 1. 更新.env文件  
NERO_TESTNET_RPC=https://data-seed-prebsc-1-s1.binance.org:8545
BSCSCAN_API_KEY=your_api_key_here

# 2. 部署
npm run deploy:bsc-testnet
```

### 方案3：获取NERO链官方信息

**需要从NERO链官方获取：**
1. **正确的RPC端点**
   ```
   测试网: https://rpc-testnet.nero.network
   主网: https://rpc.nero.network
   ```

2. **正确的链ID**
   ```
   测试网: 1002 (示例)
   主网: 1001 (示例)
   ```

3. **区块浏览器信息**
   ```
   测试网: https://explorer-testnet.nero.network
   主网: https://explorer.nero.network
   ```

## 🔍 网络连接测试

### 测试RPC连接
```bash
# 测试RPC端点是否可用
curl -X POST -H "Content-Type: application/json" \
--data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
https://rpc-testnet.nero.network
```

### 检查网络配置
```bash
# 检查网络配置
npm run check-networks
```

### 查看Gas价格
```javascript
// 在Hardhat控制台中
const provider = new ethers.providers.JsonRpcProvider("YOUR_RPC_URL");
const gasPrice = await provider.getGasPrice();
console.log("当前Gas价格:", ethers.utils.formatUnits(gasPrice, "gwei"), "gwei");
```

## 📋 网络配置检查清单

- [ ] **RPC端点可访问**
  ```bash
  curl -I https://your-rpc-endpoint.com
  ```

- [ ] **链ID正确**
  - 检查官方文档
  - 确认hardhat.config.ts中的chainId设置

- [ ] **私钥有效**
  - 确保私钥格式正确 (0x开头)
  - 账户有足够的原生代币用于gas费

- [ ] **Gas设置合理**
  - gasPrice不要过低或过高
  - 必要时设置gasLimit

- [ ] **网络稳定性**
  - 尝试多次连接
  - 检查网络延迟

## 🆘 应急部署方案

### 1. 本地开发环境
```bash
# 启动本地节点
npm run node:start

# 在新终端部署
npm run deploy:local
```

### 2. 公开测试网络
```bash
# Polygon Mumbai (稳定可靠)
npm run deploy:mumbai

# BSC测试网 (快速便宜)
npm run deploy:bsc-testnet
```

### 3. 获取测试代币

**Polygon Mumbai水龙头：**
- https://faucet.polygon.technology/

**BSC测试网水龙头：**
- https://testnet.binance.org/faucet-smart

## 📞 获取帮助

如果问题持续存在：

1. **检查NERO链官方文档**
   - 官网：https://nero.network
   - 开发者文档：https://docs.nero.network

2. **联系NERO链社区**
   - Discord/Telegram社区
   - 官方技术支持

3. **使用替代方案**
   - 先在稳定的测试网络上验证功能
   - 等待NERO链网络稳定后再迁移

## ✅ 成功部署确认

部署成功的标志：
```
🎉 NERO DEX部署完成！
========================================
工厂合约:         0x...
路由器:           0x...
位置管理器:       0x...
========================================
```

记录所有合约地址到 `deployments.json` 文件中。 
import { ethers } from "hardhat";
import { Contract } from "ethers";
import * as fs from "fs";
import * as path from "path";

interface DeploymentAddresses {
  WETH9?: string;
  factory?: string;
  router?: string;
  positionManager?: string;
  tokenDescriptor?: string;
  quoter?: string;
}

async function main() {
  console.log("🚀 开始部署NERO DEX...");
  
  const [deployer] = await ethers.getSigners();
  console.log("部署账户:", deployer.address);
  console.log("账户余额:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));

  const deploymentAddresses: DeploymentAddresses = {};
  
  // 1. 部署或获取WETH9合约
  let weth9Address = process.env.WETH_ADDRESS;
  if (!weth9Address) {
    console.log("\n📦 部署WETH9合约...");
    const WETH9 = await ethers.getContractFactory("WETH9");
    const weth9 = await WETH9.deploy();
    await weth9.waitForDeployment();
    weth9Address = await weth9.getAddress();
    console.log("✅ WETH9部署完成:", weth9Address);
  } else {
    console.log("✅ 使用现有WETH9:", weth9Address);
  }
  deploymentAddresses.WETH9 = weth9Address;

  // 2. 部署工厂合约
  console.log("\n📦 部署工厂合约...");
  const Factory = await ethers.getContractFactory("NeroDEXFactory");
  const factory = await Factory.deploy();
  await factory.waitForDeployment();
  const factoryAddress = await factory.getAddress();
  console.log("✅ 工厂合约部署完成:", factoryAddress);
  deploymentAddresses.factory = factoryAddress;

  // 3. 部署Token描述器（用于NFT位置管理器）
  console.log("\n📦 部署Token描述器...");
  const TokenDescriptor = await ethers.getContractFactory("NonfungibleTokenPositionDescriptor");
  const tokenDescriptor = await TokenDescriptor.deploy(weth9Address, "NERO");
  await tokenDescriptor.waitForDeployment();
  const tokenDescriptorAddress = await tokenDescriptor.getAddress();
  console.log("✅ Token描述器部署完成:", tokenDescriptorAddress);
  deploymentAddresses.tokenDescriptor = tokenDescriptorAddress;

  // 4. 部署位置管理器
  console.log("\n📦 部署位置管理器...");
  const PositionManager = await ethers.getContractFactory("NeroPositionManager");
  const positionManager = await PositionManager.deploy(
    factoryAddress,
    weth9Address,
    tokenDescriptorAddress
  );
  await positionManager.waitForDeployment();
  const positionManagerAddress = await positionManager.getAddress();
  console.log("✅ 位置管理器部署完成:", positionManagerAddress);
  deploymentAddresses.positionManager = positionManagerAddress;

  // 5. 部署路由器
  console.log("\n📦 部署路由器...");
  const Router = await ethers.getContractFactory("NeroDEXRouter");
  const router = await Router.deploy(factoryAddress, weth9Address);
  await router.waitForDeployment();
  const routerAddress = await router.getAddress();
  console.log("✅ 路由器部署完成:", routerAddress);
  deploymentAddresses.router = routerAddress;

  // 6. 部署价格预言机（Quoter）
  console.log("\n📦 部署价格预言机...");
  const Quoter = await ethers.getContractFactory("Quoter");
  const quoter = await Quoter.deploy(factoryAddress, weth9Address);
  await quoter.waitForDeployment();
  const quoterAddress = await quoter.getAddress();
  console.log("✅ 价格预言机部署完成:", quoterAddress);
  deploymentAddresses.quoter = quoterAddress;

  // 7. 保存部署地址
  const deploymentFile = path.join(__dirname, "..", "deployments.json");
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentAddresses, null, 2));
  console.log("\n📄 部署地址已保存到:", deploymentFile);

  // 8. 显示部署摘要
  console.log("\n🎉 NERO DEX部署完成！");
  console.log("========================================");
  console.log("WETH9:          ", deploymentAddresses.WETH9);
  console.log("工厂合约:        ", deploymentAddresses.factory);
  console.log("路由器:          ", deploymentAddresses.router);
  console.log("位置管理器:      ", deploymentAddresses.positionManager);
  console.log("Token描述器:     ", deploymentAddresses.tokenDescriptor);
  console.log("价格预言机:      ", deploymentAddresses.quoter);
  console.log("========================================");

  // 9. 验证部署
  console.log("\n🔍 验证部署...");
  try {
    const factoryContract = await ethers.getContractAt("NeroDEXFactory", factoryAddress);
    const owner = await factoryContract.owner();
    console.log("✅ 工厂合约所有者:", owner);
    
    const routerContract = await ethers.getContractAt("NeroDEXRouter", routerAddress);
    const routerVersion = await routerContract.version();
    console.log("✅ 路由器版本:", routerVersion);
  } catch (error) {
    console.log("❌ 验证失败:", error);
  }

  console.log("\n📋 下一步:");
  console.log("1. 复制 env.example 为 .env 并填写相关配置");
  console.log("2. 运行验证脚本: npm run verify");
  console.log("3. 创建交易对并开始使用DEX");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 
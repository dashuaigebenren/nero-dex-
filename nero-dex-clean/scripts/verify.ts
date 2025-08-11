import { run } from "hardhat";
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
  console.log("🔍 开始验证NERO DEX合约...");
  
  // 读取部署地址
  const deploymentFile = path.join(__dirname, "..", "deployments.json");
  if (!fs.existsSync(deploymentFile)) {
    console.error("❌ 找不到部署文件，请先运行部署脚本");
    return;
  }
  
  const deploymentAddresses: DeploymentAddresses = JSON.parse(
    fs.readFileSync(deploymentFile, "utf8")
  );

  console.log("部署地址:", deploymentAddresses);

  try {
    // 验证工厂合约
    if (deploymentAddresses.factory) {
      console.log("\n验证工厂合约...");
      await run("verify:verify", {
        address: deploymentAddresses.factory,
        constructorArguments: [],
      });
      console.log("✅ 工厂合约验证完成");
    }

    // 验证路由器合约
    if (deploymentAddresses.router) {
      console.log("\n验证路由器合约...");
      await run("verify:verify", {
        address: deploymentAddresses.router,
        constructorArguments: [
          deploymentAddresses.factory,
          deploymentAddresses.WETH9,
        ],
      });
      console.log("✅ 路由器合约验证完成");
    }

    // 验证Token描述器
    if (deploymentAddresses.tokenDescriptor) {
      console.log("\n验证Token描述器...");
      await run("verify:verify", {
        address: deploymentAddresses.tokenDescriptor,
        constructorArguments: [deploymentAddresses.WETH9, "NERO"],
      });
      console.log("✅ Token描述器验证完成");
    }

    // 验证位置管理器
    if (deploymentAddresses.positionManager) {
      console.log("\n验证位置管理器...");
      await run("verify:verify", {
        address: deploymentAddresses.positionManager,
        constructorArguments: [
          deploymentAddresses.factory,
          deploymentAddresses.WETH9,
          deploymentAddresses.tokenDescriptor,
        ],
      });
      console.log("✅ 位置管理器验证完成");
    }

    // 验证价格预言机
    if (deploymentAddresses.quoter) {
      console.log("\n验证价格预言机...");
      await run("verify:verify", {
        address: deploymentAddresses.quoter,
        constructorArguments: [
          deploymentAddresses.factory,
          deploymentAddresses.WETH9,
        ],
      });
      console.log("✅ 价格预言机验证完成");
    }

    console.log("\n🎉 所有合约验证完成！");
  } catch (error) {
    console.error("❌ 验证过程中出现错误:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 
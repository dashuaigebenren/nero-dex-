import { expect } from "chai";
import hre from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { Contract } from "ethers";

const { ethers } = hre;

describe("NERO DEX", function () {
  let factory: Contract;
  let router: Contract;
  let positionManager: Contract;
  let weth9: Contract;
  let tokenDescriptor: Contract;
  let quoter: Contract;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // 部署WETH9
    const WETH9 = await ethers.getContractFactory("WETH9");
    weth9 = await WETH9.deploy();
    await weth9.waitForDeployment();

    // 部署工厂合约
    const Factory = await ethers.getContractFactory("NeroDEXFactory");
    factory = await Factory.deploy();
    await factory.waitForDeployment();

    // 部署Token描述器
    const TokenDescriptor = await ethers.getContractFactory("NonfungibleTokenPositionDescriptor");
    tokenDescriptor = await TokenDescriptor.deploy(await weth9.getAddress(), "NERO");
    await tokenDescriptor.waitForDeployment();

    // 部署位置管理器
    const PositionManager = await ethers.getContractFactory("NeroPositionManager");
    positionManager = await PositionManager.deploy(
      await factory.getAddress(),
      await weth9.getAddress(),
      await tokenDescriptor.getAddress()
    );
    await positionManager.waitForDeployment();

    // 部署路由器
    const Router = await ethers.getContractFactory("NeroDEXRouter");
    router = await Router.deploy(
      await factory.getAddress(),
      await weth9.getAddress()
    );
    await router.waitForDeployment();

    // 部署Quoter
    const Quoter = await ethers.getContractFactory("Quoter");
    quoter = await Quoter.deploy(
      await factory.getAddress(),
      await weth9.getAddress()
    );
    await quoter.waitForDeployment();
  });

  describe("工厂合约", function () {
    it("应该正确设置所有者", async function () {
      expect(await factory.owner()).to.equal(owner.address);
    });

    it("应该有默认的手续费层级", async function () {
      expect(await factory.feeAmountTickSpacing(500)).to.equal(10);
      expect(await factory.feeAmountTickSpacing(3000)).to.equal(60);
      expect(await factory.feeAmountTickSpacing(10000)).to.equal(200);
    });

    it("应该允许所有者启用新的手续费层级", async function () {
      await factory.neroEnableFeeAmount(100, 1);
      expect(await factory.feeAmountTickSpacing(100)).to.equal(1);
    });

    it("应该拒绝非所有者启用手续费层级", async function () {
      await expect(
        factory.connect(user1).enableFeeAmount(100, 1)
      ).to.be.reverted;
    });

    it("应该能够检查手续费层级是否启用", async function () {
      expect(await factory.isFeeAmountEnabled(3000)).to.be.true;
      expect(await factory.isFeeAmountEnabled(12345)).to.be.false;
    });

    it("应该能够暂停和恢复工厂", async function () {
      await factory.pause();
      expect(await factory.paused()).to.be.true;
      
      await factory.unpause();
      expect(await factory.paused()).to.be.false;
    });
  });

  describe("路由器合约", function () {
    it("应该返回正确的版本信息", async function () {
      expect(await router.version()).to.equal("NERO DEX Router v1.0.0");
    });

    it("应该正确设置factory地址", async function () {
      expect(await router.neroFactory()).to.equal(await factory.getAddress());
    });

    it("应该正确设置WETH9地址", async function () {
      expect(await router.neroWETH9()).to.equal(await weth9.getAddress());
    });

    it("应该允许所有者暂停路由器", async function () {
      await router.pause();
      expect(await router.paused()).to.be.true;
    });
  });

  describe("位置管理器合约", function () {
    it("应该返回正确的版本信息", async function () {
      expect(await positionManager.version()).to.equal("NERO Position Manager v1.0.0");
    });

    it("应该正确设置工厂地址", async function () {
      expect(await positionManager.factory()).to.equal(await factory.getAddress());
    });

    it("应该正确设置WETH9地址", async function () {
      expect(await positionManager.WETH9()).to.equal(await weth9.getAddress());
    });
  });

  describe("WETH9合约", function () {
    it("应该正确设置名称和符号", async function () {
      expect(await weth9.name()).to.equal("Wrapped Ether");
      expect(await weth9.symbol()).to.equal("WETH");
      expect(await weth9.decimals()).to.equal(18);
    });

    it("应该允许存入和取出ETH", async function () {
      const depositAmount = ethers.parseEther("1.0");
      
      // 存入ETH
      await weth9.deposit({ value: depositAmount });
      expect(await weth9.balanceOf(owner.address)).to.equal(depositAmount);
      
      // 取出ETH
      const balanceBefore = await owner.provider.getBalance(owner.address);
      await weth9.withdraw(depositAmount);
      expect(await weth9.balanceOf(owner.address)).to.equal(0);
    });
  });

  describe("Quoter合约", function () {
    it("应该能够提供价格报价", async function () {
      const amountIn = ethers.parseEther("1.0");
      const amountOut = await quoter.quoteExactInputSingle(
        await weth9.getAddress(),
        await weth9.getAddress(), // 同一代币，仅用于测试
        3000,
        amountIn,
        0
      );
      
      expect(amountOut).to.be.greaterThan(0);
    });
  });

  describe("集成测试", function () {
    let token0: Contract;
    let token1: Contract;

    beforeEach(async function () {
      // 创建测试代币
      const TestERC20 = await ethers.getContractFactory("TestERC20");
      
      const tokenA = await TestERC20.deploy("Token A", "TKNA", 18);
      await tokenA.waitForDeployment();
      
      const tokenB = await TestERC20.deploy("Token B", "TKNB", 18);
      await tokenB.waitForDeployment();

      // 确保token0 < token1（地址排序）
      if ((await tokenA.getAddress()) < (await tokenB.getAddress())) {
        token0 = tokenA;
        token1 = tokenB;
      } else {
        token0 = tokenB;
        token1 = tokenA;
      }
    });

    it("应该能够创建新的交易对", async function () {
      const fee = 3000; // 0.3%
      
      const tx = await factory.neroCreatePool(
        await token0.getAddress(),
        await token1.getAddress(),
        fee
      );
      
      const receipt = await tx.wait();
      
      // 检查是否触发了事件
      expect(receipt.logs.length).to.be.greaterThan(0);
      
      // 检查池地址是否正确存储
      const poolAddress = await factory.getPoolAddress(
        await token0.getAddress(),
        await token1.getAddress(),
        fee
      );
      expect(poolAddress).to.not.equal(ethers.ZeroAddress);
    });

    it("应该拒绝创建重复的交易对", async function () {
      const fee = 3000;
      
      // 创建第一个池
      await factory.neroCreatePool(
        await token0.getAddress(),
        await token1.getAddress(),
        fee
      );
      
      // 尝试创建重复的池
      await expect(
        factory.createPool(
          await token0.getAddress(),
          await token1.getAddress(),
          fee
        )
      ).to.be.reverted;
    });

    it("应该拒绝使用无效的手续费创建池", async function () {
      const invalidFee = 1234; // 未启用的手续费层级
      
      await expect(
        factory.createPool(
          await token0.getAddress(),
          await token1.getAddress(),
          invalidFee
        )
      ).to.be.reverted;
    });

    it("应该能够批量创建多个池", async function () {
      const tokenC = await (await ethers.getContractFactory("TestERC20")).deploy("Token C", "TKNC", 18);
      await tokenC.waitForDeployment();

      const tokens0 = [await token0.getAddress(), await token1.getAddress()];
      const tokens1 = [await token1.getAddress(), await tokenC.getAddress()];
      const fees = [3000, 10000];

      const pools = await factory.batchCreatePools(tokens0, tokens1, fees);
      
      expect(pools.length).to.equal(2);
      expect(pools[0]).to.not.equal(ethers.ZeroAddress);
      expect(pools[1]).to.not.equal(ethers.ZeroAddress);
    });

    it("应该能够获取所有启用的手续费层级", async function () {
      const [fees, tickSpacings] = await factory.getEnabledFeeAmounts();
      
      expect(fees.length).to.be.greaterThan(0);
      expect(fees.length).to.equal(tickSpacings.length);
      
      // 检查默认的手续费层级
      expect(fees).to.include(500);
      expect(fees).to.include(3000);
      expect(fees).to.include(10000);
    });
  });
}); 
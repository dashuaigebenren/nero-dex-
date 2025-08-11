// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

/// @title NERO DEX Factory
/// @notice 基于Uniswap V3理念的NERO链去中心化交易所工厂合约
contract NeroDEXFactory {
    address public owner;
    string public constant version = "NERO DEX Factory v1.0.0";
    
    /// @dev 手续费率到tick间距的映射
    mapping(uint24 => int24) public feeAmountTickSpacing;
    
    /// @dev token0 -> token1 -> fee -> pool地址的映射
    mapping(address => mapping(address => mapping(uint24 => address))) public getPool;
    
    // NERO链特定的事件
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );
    
    event NeroPoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool,
        uint256 timestamp
    );
    
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);
    
    event NeroFeeAmountEnabled(
        uint24 indexed fee,
        int24 indexed tickSpacing,
        uint256 timestamp
    );
    
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    
    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        // 初始化标准手续费级别
        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
    }
    
    /// @notice 创建新的交易池
    /// @param tokenA 第一个代币地址
    /// @param tokenB 第二个代币地址
    /// @param fee 手续费率
    /// @return pool 新创建的池地址
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external notPaused returns (address pool) {
        return _createPoolInternal(tokenA, tokenB, fee);
    }
    
    /// @notice 内部池创建函数
    function _createPoolInternal(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal returns (address pool) {
        require(!paused, "Factory is paused");
        require(tokenA != tokenB, "Identical tokens");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Zero address");
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0, "Fee not enabled");
        require(getPool[token0][token1][fee] == address(0), "Pool exists");
        
        // 使用CREATE2创建确定性地址
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, fee));
        bytes memory bytecode = type(SimplePool).creationCode;
        
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        
        require(pool != address(0), "Pool creation failed");
        
        // 初始化池
        SimplePool(pool).initialize(token0, token1, fee);
        
        getPool[token0][token1][fee] = pool;
        getPool[token1][token0][fee] = pool;
        
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
        
        return pool;
    }
    
    /// @notice NERO链特定的创建池函数
    function neroCreatePool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool) {
        pool = _createPoolInternal(tokenA, tokenB, fee);
        
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        int24 tickSpacing = feeAmountTickSpacing[fee];
        
        emit NeroPoolCreated(token0, token1, fee, tickSpacing, pool, block.timestamp);
        
        return pool;
    }
    
    /// @notice 启用新的手续费层级
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external {
        require(msg.sender == owner, "Not owner");
        require(fee < 1000000, "Fee too high");
        require(tickSpacing > 0 && tickSpacing < 16384, "Invalid tick spacing");
        require(feeAmountTickSpacing[fee] == 0, "Fee already enabled");

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }
    
    /// @notice NERO链特定的启用手续费层级函数
    function neroEnableFeeAmount(uint24 fee, int24 tickSpacing) external {
        require(msg.sender == owner, "Not owner");
        require(fee < 1000000, "Fee too high");
        require(tickSpacing > 0 && tickSpacing < 16384, "Invalid tick spacing");
        require(feeAmountTickSpacing[fee] == 0, "Fee already enabled");

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
        emit NeroFeeAmountEnabled(fee, tickSpacing, block.timestamp);
    }
    
    /// @notice 设置新的所有者
    function setOwner(address _owner) external {
        require(msg.sender == owner, "Not owner");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }
    
    /// @notice 获取池地址
    function getPoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (address pool) {
        return getPool[token0][token1][fee];
    }
    
    /// @notice 检查手续费层级是否已启用
    function isFeeAmountEnabled(uint24 fee) external view returns (bool enabled) {
        return feeAmountTickSpacing[fee] != 0;
    }
    
    /// @notice 获取所有启用的手续费层级
    function getEnabledFeeAmounts() 
        external 
        view 
        returns (uint24[] memory fees, int24[] memory tickSpacings) 
    {
        uint24[] memory allFees = new uint24[](6);
        allFees[0] = 100;
        allFees[1] = 500;
        allFees[2] = 3000;
        allFees[3] = 10000;
        allFees[4] = 30000;
        allFees[5] = 100000;
        
        uint256 enabledCount = 0;
        for (uint256 i = 0; i < allFees.length; i++) {
            if (feeAmountTickSpacing[allFees[i]] != 0) {
                enabledCount++;
            }
        }
        
        fees = new uint24[](enabledCount);
        tickSpacings = new int24[](enabledCount);
        
        uint256 index = 0;
        for (uint256 i = 0; i < allFees.length; i++) {
            if (feeAmountTickSpacing[allFees[i]] != 0) {
                fees[index] = allFees[i];
                tickSpacings[index] = feeAmountTickSpacing[allFees[i]];
                index++;
            }
        }
        
        return (fees, tickSpacings);
    }
    
    /// @notice 批量创建多个池
    function batchCreatePools(
        address[] calldata tokens0,
        address[] calldata tokens1,
        uint24[] calldata fees
    ) external returns (address[] memory pools) {
        require(
            tokens0.length == tokens1.length && tokens1.length == fees.length,
            "Array lengths mismatch"
        );
        
        pools = new address[](tokens0.length);
        
        for (uint256 i = 0; i < tokens0.length; i++) {
            pools[i] = _createPoolInternal(tokens0[i], tokens1[i], fees[i]);
        }
        
        return pools;
    }
    
    // 紧急暂停功能
    bool public paused = false;
    
    modifier notPaused() {
        require(!paused, "Factory is paused");
        _;
    }
    
    function pause() external {
        require(msg.sender == owner, "Not owner");
        paused = true;
    }
    
    function unpause() external {
        require(msg.sender == owner, "Not owner");
        paused = false;
    }
}

/// @title Simple Pool
/// @notice 简化的池合约实现
contract SimplePool {
    address public token0;
    address public token1;
    uint24 public fee;
    bool public initialized;
    
    event Initialized(address token0, address token1, uint24 fee);
    
    function initialize(address _token0, address _token1, uint24 _fee) external {
        require(!initialized, "Already initialized");
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        initialized = true;
        
        emit Initialized(_token0, _token1, _fee);
    }
    
    function getPoolInfo() external view returns (address, address, uint24) {
        return (token0, token1, fee);
    }
} 
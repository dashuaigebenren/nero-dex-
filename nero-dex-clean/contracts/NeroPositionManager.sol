// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

/// @title NERO Position Manager
/// @notice 基于Uniswap V3理念的NERO链NFT位置管理器合约
contract NeroPositionManager {
    address public immutable factory;
    address public immutable WETH9;
    address public immutable tokenDescriptor;
    
    uint256 private _tokenIdCounter = 1;
    mapping(uint256 => Position) public positions;
    mapping(uint256 => address) public tokenOwners;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    
    struct Position {
        uint96 nonce;
        address operator;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }
    
    // NERO链特定的事件
    event NeroPositionMinted(
        uint256 indexed tokenId,
        address indexed owner,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 timestamp
    );
    
    event NeroPositionBurned(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 timestamp
    );
    
    event NeroFeesCollected(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 amount0,
        uint256 amount1,
        uint256 timestamp
    );
    
    // ERC721事件
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    // 铸造参数
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    
    // 增加流动性参数
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    
    // 减少流动性参数
    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    
    // 收集参数
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    
    constructor(
        address _factory,
        address _WETH9,
        address _tokenDescriptor
    ) {
        factory = _factory;
        WETH9 = _WETH9;
        tokenDescriptor = _tokenDescriptor;
    }
    
    /// @notice 获取位置管理器版本信息
    /// @return version 版本字符串
    function version() external pure returns (string memory) {
        return "NERO Position Manager v1.0.0";
    }
    
    /// @notice 铸造新的位置NFT
    /// @param params 铸造参数
    /// @return tokenId 新创建的NFT ID
    /// @return liquidity 流动性数量
    /// @return amount0 token0数量
    /// @return amount1 token1数量
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(block.timestamp <= params.deadline, "Transaction expired");
        require(params.amount0Desired > 0 || params.amount1Desired > 0, "Invalid amounts");
        
        tokenId = _tokenIdCounter++;
        
        // 简化的流动性计算
        liquidity = uint128((params.amount0Desired + params.amount1Desired) / 2);
        amount0 = params.amount0Desired;
        amount1 = params.amount1Desired;
        
        require(amount0 >= params.amount0Min, "Insufficient amount0");
        require(amount1 >= params.amount1Min, "Insufficient amount1");
        
        // 创建位置
        positions[tokenId] = Position({
            nonce: 0,
            operator: address(0),
            token0: params.token0,
            token1: params.token1,
            fee: params.fee,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            liquidity: liquidity,
            feeGrowthInside0LastX128: 0,
            feeGrowthInside1LastX128: 0,
            tokensOwed0: 0,
            tokensOwed1: 0
        });
        
        // 铸造NFT
        _mint(params.recipient, tokenId);
        
        emit NeroPositionMinted(
            tokenId,
            params.recipient,
            params.token0,
            params.token1,
            params.fee,
            params.tickLower,
            params.tickUpper,
            liquidity,
            block.timestamp
        );
        
        return (tokenId, liquidity, amount0, amount1);
    }
    
    /// @notice NERO链特定的铸造位置NFT
    function neroMint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        return this.mint(params);
    }
    
    /// @notice 增加流动性
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(block.timestamp <= params.deadline, "Transaction expired");
        require(_exists(params.tokenId), "Invalid token ID");
        require(_isApprovedOrOwner(msg.sender, params.tokenId), "Not approved");
        
        Position storage position = positions[params.tokenId];
        
        // 简化的流动性计算
        liquidity = uint128((params.amount0Desired + params.amount1Desired) / 2);
        amount0 = params.amount0Desired;
        amount1 = params.amount1Desired;
        
        require(amount0 >= params.amount0Min, "Insufficient amount0");
        require(amount1 >= params.amount1Min, "Insufficient amount1");
        
        position.liquidity += liquidity;
        
        return (liquidity, amount0, amount1);
    }
    
    /// @notice NERO链特定的增加流动性
    function neroIncreaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        return this.increaseLiquidity(params);
    }
    
    /// @notice 减少流动性
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1)
    {
        require(block.timestamp <= params.deadline, "Transaction expired");
        require(_exists(params.tokenId), "Invalid token ID");
        require(_isApprovedOrOwner(msg.sender, params.tokenId), "Not approved");
        
        Position storage position = positions[params.tokenId];
        require(position.liquidity >= params.liquidity, "Insufficient liquidity");
        
        // 简化的计算
        amount0 = (uint256(params.liquidity) * 100) / 100; // 简化示例
        amount1 = (uint256(params.liquidity) * 100) / 100;
        
        require(amount0 >= params.amount0Min, "Insufficient amount0");
        require(amount1 >= params.amount1Min, "Insufficient amount1");
        
        position.liquidity -= params.liquidity;
        position.tokensOwed0 += uint128(amount0);
        position.tokensOwed1 += uint128(amount1);
        
        return (amount0, amount1);
    }
    
    /// @notice NERO链特定的减少流动性
    function neroDecreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1)
    {
        return this.decreaseLiquidity(params);
    }
    
    /// @notice 收集手续费
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1)
    {
        require(_exists(params.tokenId), "Invalid token ID");
        require(_isApprovedOrOwner(msg.sender, params.tokenId), "Not approved");
        
        Position storage position = positions[params.tokenId];
        
        amount0 = params.amount0Max > position.tokensOwed0 ? position.tokensOwed0 : params.amount0Max;
        amount1 = params.amount1Max > position.tokensOwed1 ? position.tokensOwed1 : params.amount1Max;
        
        position.tokensOwed0 -= uint128(amount0);
        position.tokensOwed1 -= uint128(amount1);
        
        emit NeroFeesCollected(
            params.tokenId,
            msg.sender,
            amount0,
            amount1,
            block.timestamp
        );
        
        return (amount0, amount1);
    }
    
    /// @notice NERO链特定的收集手续费
    function neroCollect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1)
    {
        return this.collect(params);
    }
    
    /// @notice 销毁位置NFT
    function burn(uint256 tokenId) external payable {
        require(_exists(tokenId), "Invalid token ID");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        
        Position storage position = positions[tokenId];
        require(position.liquidity == 0, "Not cleared");
        require(position.tokensOwed0 == 0 && position.tokensOwed1 == 0, "Not collected");
        
        delete positions[tokenId];
        _burn(tokenId);
        
        emit NeroPositionBurned(tokenId, msg.sender, block.timestamp);
    }
    
    /// @notice NERO链特定的销毁位置NFT
    function neroBurn(uint256 tokenId) external payable {
        this.burn(tokenId);
    }
    
    /// @notice 获取位置的详细信息
    function getPositionInfo(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        Position memory position = positions[tokenId];
        return (
            position.nonce,
            position.operator,
            position.token0,
            position.token1,
            position.fee,
            position.tickLower,
            position.tickUpper,
            position.liquidity,
            position.feeGrowthInside0LastX128,
            position.feeGrowthInside1LastX128,
            position.tokensOwed0,
            position.tokensOwed1
        );
    }
    
    /// @notice 批量收集多个位置的手续费
    function batchCollectFees(uint256[] calldata tokenIds)
        external
        returns (uint256 totalAmount0, uint256 totalAmount1)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (uint256 amount0, uint256 amount1) = this.collect(
                CollectParams({
                    tokenId: tokenIds[i],
                    recipient: msg.sender,
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
            
            totalAmount0 += amount0;
            totalAmount1 += amount1;
        }
        
        return (totalAmount0, totalAmount1);
    }
    
    /// @notice 获取用户的所有位置
    function getUserPositions(address user) 
        external 
        view 
        returns (uint256[] memory tokenIds) 
    {
        uint256 balance = balanceOf[user];
        tokenIds = new uint256[](balance);
        
        uint256 index = 0;
        for (uint256 i = 1; i < _tokenIdCounter && index < balance; i++) {
            if (tokenOwners[i] == user) {
                tokenIds[index] = i;
                index++;
            }
        }
        
        return tokenIds;
    }
    
    // 基本ERC721功能
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = tokenOwners[tokenId];
        require(owner != address(0), "Invalid token ID");
        return owner;
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenOwners[tokenId] != address(0);
    }
    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Mint to zero address");
        require(!_exists(tokenId), "Token already minted");
        
        balanceOf[to]++;
        tokenOwners[tokenId] = to;
        
        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        
        balanceOf[owner]--;
        delete tokenOwners[tokenId];
        delete tokenApprovals[tokenId];
        
        emit Transfer(owner, address(0), tokenId);
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "Invalid token ID");
        address owner = ownerOf(tokenId);
        return (spender == owner || tokenApprovals[tokenId] == spender || operatorApprovals[owner][spender]);
    }
} 
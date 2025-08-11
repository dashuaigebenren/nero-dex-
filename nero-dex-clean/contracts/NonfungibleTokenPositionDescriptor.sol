// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

/// @title Describes NFT token positions
/// @notice Produces a string containing the data URI for a JSON metadata string
contract NonfungibleTokenPositionDescriptor {
    address public immutable WETH9;
    bytes32 public immutable nativeCurrencyLabelBytes;

    constructor(address _WETH9, string memory _nativeCurrencyLabel) {
        WETH9 = _WETH9;
        nativeCurrencyLabelBytes = keccak256(bytes(_nativeCurrencyLabel));
    }

    /// @notice Produces the URI describing a particular token ID for a position manager
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @param tokenId The ID of the token for which to produce a description, which may not be valid
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                base64encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name":"NERO DEX Position #',
                                toString(tokenId),
                                '","description":"This NFT represents a liquidity position in a NERO DEX pool.","image":"data:image/svg+xml;base64,',
                                base64encode(bytes(generateSVG())),
                                '"}'
                            )
                        )
                    )
                )
            )
        );
    }

    function generateSVG() internal pure returns (string memory) {
        return '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300"><rect width="300" height="300" fill="#1f2937"/><text x="150" y="150" text-anchor="middle" fill="white" font-size="16">NERO DEX Position</text></svg>';
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function base64encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            
            for { let i := 0 } lt(i, mload(data)) { i := add(i, 3) } {
                let input := shl(248, mload(add(add(data, 32), i)))
                
                mstore8(resultPtr, mload(add(tablePtr, and(shr(250, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(244, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(238, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(232, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
} 
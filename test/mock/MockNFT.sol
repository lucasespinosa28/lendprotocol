// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title MockNFT
 * @author Your Name
 * @notice A simple mock ERC721 contract for testing purposes.
 * It allows anyone to mint NFTs.
 */
contract MockNFT is ERC721 {
    uint256 private _tokenCounter;

    constructor() ERC721("Mock NFT", "MOCK") {}

    /**
     * @notice Mints a new NFT and assigns it to the specified address.
     * @param to The address to mint the NFT to.
     * @return The ID of the newly minted token.
     */
    function mint(address to) public returns (uint256) {
        uint256 tokenId = _tokenCounter;
        _safeMint(to, tokenId);
        _tokenCounter++;
        return tokenId;
    }
}

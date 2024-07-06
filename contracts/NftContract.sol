// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NftContract is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter public tokenIdCounter;

    constructor() Ownable(msg.sender) ERC721("YourCollectible", "YCB") {}

    // The following functions are overrides required by Solidity.

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    function mintItem(address to, string memory uri) public returns (uint256) {
        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function _increaseBalance(address _account, uint128 _value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(_account, _value);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function _update(
        address _to,
        uint256 _tokenId,
        address _auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(_to, _tokenId, _auth);
    }
}

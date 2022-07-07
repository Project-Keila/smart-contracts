//SPDX-License-Identifier: UNLICENSED

/* @dev use the local compiler downloaded in this folder */
pragma solidity ^0.8.0;

/*
@dev import openzeppelin token and ownable contracts
 */
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Keila is ERC1155, Ownable{

    string public name;
    string public symbol;

    mapping(uint256 => string) public tokenURI;

    constructor() ERC1155("https:/metadata_url/${id}.json") {
      name = "Project Keila";
      symbol = "";
  }

  function mint(uint256 id, uint16 amount) external {
     _mint(msg.sender, id, amount, "");
  }

  function mintBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _mintBatch(msg.sender, _ids, _amounts, "");
  }
  
  function setUri(uint _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }
}
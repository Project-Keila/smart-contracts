// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./libraries/String.sol";

contract Certificate is ERC721URIStorage, ChainlinkClient, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Chainlink for Chainlink.Request;
    using String for string;

    bytes32 private jobId;
    uint256 private fee;
    uint256 public tokenId;
    uint256 public offsetCapacity;

    address private oracle;
    address private linkToken;

    string public apiUrl;

    mapping(uint256 => uint256) public offsetCapacities;

    modifier checkPrice(uint256 price) {
        require(msg.value >= price, "Amount less than the Certificate Price");
        _;
    }

    event Minted(string tokenUri, uint256 timestamp, uint256 tokenId);

    event TreeBurnt(uint256 timestamp, uint256 tokenId);

    mapping(uint256 => bool) public treeStatus;

    constructor(
        address _oracle,
        address _linkToken,
        bytes32 _jobId,
        string memory _apiUrl
    ) ERC721("Project Keila", "KEILA") {
        linkToken = _linkToken;
        oracle = _oracle;
        setChainlinkToken(_linkToken);
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
        apiUrl = _apiUrl;
    }

    function setOracleDetails(
        address _oracle,
        address _linkToken,
        bytes32 _jobId,
        uint256 _fee
    ) private onlyOwner {
        linkToken = _linkToken;
        oracle = _oracle;
        setChainlinkToken(_linkToken);
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        fee = (_fee * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    function mint(string memory tokenURI, uint256 price)
        public
        payable
        checkPrice(price)
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        treeStatus[newItemId] = true;
        address _contractOwner = owner();
        payable(_contractOwner).transfer(msg.value);
        emit Minted(tokenURI, block.timestamp, newItemId);

        return newItemId;
    }

    function setApiUrl(string memory _url) public {
        apiUrl = _url;
    }

    function getTreeDetails(string memory _tokenId) public payable {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        req.add("get", apiUrl.concat(_tokenId));
        req.add("pathTOKEN", "TOKEN");
        req.add("pathOFFSET", "OFFSET");
        sendChainlinkRequest(req, fee); // MWR API.
    }

    /**
     * @notice Fulfillment function for multiple parameters in a single request
     * @dev This is called by the oracle. recordChainlinkFulfillment must be used.
     */

    function fulfill(
        bytes32 requestId,
        uint256 tokenResponse,
        uint256 offsetResponse
    ) public recordChainlinkFulfillment(requestId) {
        emit TreeBurnt(block.timestamp, 1);
        offsetCapacities[tokenResponse] = offsetResponse;
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}

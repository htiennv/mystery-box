// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

error InvalidPrice();
error OwnerWithdrawalFailed();

contract MysteryBox is ERC721URIStorage, VRFConsumerBaseV2, Ownable {
    // Chainlink config
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 constant CALLBACK_GAS_LIMIT = 500000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 1;

    string[] listNftURI;

    mapping(uint256 => address) public s_requestIdToSender;

    mapping(address => bool) public whitelists;

    uint256 private s_tokenCounter;

    uint256 private price;

    event PurchaseRequested(
        uint256 indexed requestId,
        address requester,
        uint256 price
    );
    event NftMinted(address minter, uint256 rnd);
    event NftMintFailed(address minter, uint256 rnd);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 _price
    ) VRFConsumerBaseV2(vrfCoordinator) ERC721("Mystery Box", "MSB") {
        price = _price;
        s_tokenCounter = 0;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
    }

    function requestPurchaseBox() public payable returns (uint256 requestId) {
        if (msg.value != price) {
            revert InvalidPrice();
        }
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        s_requestIdToSender[requestId] = msg.sender;

        emit PurchaseRequested(requestId, msg.sender, price);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(listNftURI.length > 0, "Need have nft uri");
        address sender = s_requestIdToSender[requestId];

        uint256 rnd = randomWords[0] % 100;

        if (whitelists[sender] == true) {
            rnd = 10;
        }

        if (rnd > 30) {
            emit NftMintFailed(sender, rnd);
            return;
        }
        uint256 newTokenId = s_tokenCounter;
        _safeMint(sender, newTokenId);
        _setTokenURI(newTokenId, listNftURI[0]);

        s_tokenCounter += 1;

        emit NftMinted(sender, rnd);
    }

    function getTokenUri(uint256 index) public view returns (string memory) {
        return listNftURI[index];
    }

    function setTokenUriAtHead(string memory uri) public {
        listNftURI[0] = uri;
    }

    function addNftUri(string memory uri) public {
        listNftURI.push(uri);
    }

    function addListNtfUri(string[] memory listUri) public {
        for (uint256 i = 0; i < listUri.length; i++) {
            listNftURI.push(listUri[i]);
        }
    }

    function totalNft() public view returns (uint256) {
        return listNftURI.length;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert OwnerWithdrawalFailed();
        }
    }

    function addWhitelist(address wl) public onlyOwner {
        whitelists[wl] = true;
    }
}

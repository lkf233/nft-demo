// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "NFT.sol";

contract NFTSwap is IERC721Receiver {
    event List(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event Purchase(
        address indexed buyer,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event Revoke(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId
    );
    event Update(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 newPrice
    );

    struct Order {
        address owner;
        uint price;
    }

    mapping(address => mapping(uint => Order)) public nftList;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // 合约能接收 ERC721 代币，直接返回 selector
        return IERC721Receiver.onERC721Received.selector;
    }

    //挂单要求挂单者必须是该tokenId的owner
    function list(address _nftAddr, uint _tokenId, uint _price) public {
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.getApproved(_tokenId) == address(this), "no approved");
        require(_price > 0, "price must > 0");

        Order storage _order = nftList[_nftAddr][_tokenId];
        _order.owner = msg.sender;
        _order.price = _price;
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    function revoke(address _nftAddr, uint _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId];
        //必须由持有人发起
        require(_order.owner == msg.sender, "not owner");
        IERC721 _nft = IERC721(_nftAddr);
        //nft在合约中
        require(_nft.ownerOf(_tokenId) == address(this));

        //将nft转回卖家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddr][_tokenId];

        //触发Revoke事件
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    function update(address _nftAddr, uint _tokenId, uint _newPrice) public {
        require(_newPrice > 0, "price <0");
        Order storage order = nftList[_nftAddr][_tokenId];
        require(msg.sender == order.owner, "not owner");

        IERC721 _nft = IERC721(_nftAddr);
        //nft必须在合约中
        require(_nft.ownerOf(_tokenId) == address(this), "invalid order");
        //调整价格
        order.price = _newPrice;
        //触发update事件
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

    function purchase(address _nftAddr, uint _tokenId) public payable {
        //取得订单
        Order storage order = nftList[_nftAddr][_tokenId];
        //判断订单是否存在
        require(order.price > 0, "order not exist");
        //支付的eth是否大于price
        require(msg.value >= order.price, "msg.value<order.price");
        //声明IERC721接口变量
        IERC721 _nft = IERC721(_nftAddr);
        //该nft在合约中
        require(address(this) == _nft.ownerOf(_tokenId));
        //将合约中的nft转给买家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);

        //将eth转给卖家
        payable(order.owner).transfer(order.price);
        //将多余的eth退还买家
        payable(msg.sender).transfer(msg.value - order.price);

        //删除订单
        delete nftList[_nftAddr][_tokenId];

        //触发Purchase事件
        emit Purchase(msg.sender, _nftAddr, _tokenId, order.price);
    }

    receive() external payable {}

    fallback() external payable {}
}

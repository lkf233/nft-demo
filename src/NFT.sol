// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /**
     * @dev 如果合约实现了查询的`interfaceId`，则返回true
     * 规则详见：https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     *
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev ERC721标准接口.
 */
interface IERC721 is IERC165 {
    //转账事件
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    //授权事件
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    //批量授权事件
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// ERC721接收者接口：合约必须实现这个接口来通过安全转账接收ERC721
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is IERC721 {
    //tokenId的持有人
    mapping(uint => address) private _ownerOf;

    //某地址持有的token数量
    mapping(address => uint) private _balanceOf;

    mapping(uint => address) private _approval;
    mapping(address => mapping(address => bool)) private _isApprovedForAll;

    error MyError(string errorMessage);

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        if (owner == address(0)) {
            revert MyError("owner=zero address");
        }
        balance = _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        if (_ownerOf[tokenId] == address(0)) {
            revert MyError("this tokenId no exist");
        }
        owner = _ownerOf[tokenId];
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool) {
        return _isApprovedForAll[owner][operator];
    }

    function setApprovalForAll(address operator, bool _approved) external {
        _isApprovedForAll[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function approve(address to, uint256 tokenId) external {
        //该token拥有者的地址
        address owner = _ownerOf[tokenId];
        require(
            msg.sender == owner ||
                msg.sender == _approval[tokenId] ||
                _isApprovedForAll[owner][msg.sender],
            "no priviledage to control this token"
        );
        _approval[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator) {
        if (_ownerOf[tokenId] == address(0)) {
            revert MyError("token no exist");
        }
        operator = _approval[tokenId];
    }

    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint tokenId
    ) internal view returns (bool) {
        return
            owner == spender ||
            _approval[tokenId] == spender ||
            _isApprovedForAll[owner][spender];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(from == _ownerOf[tokenId], "from != ownerOfToken");
        require(to != address(0), "to =zero address");
        require(_isApprovedOrOwner(from, msg.sender, tokenId));
        _balanceOf[from]--;
        _balanceOf[to]++;
        _ownerOf[tokenId] = to;

        delete _approval[tokenId];
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        if (to.code.length != 0) {
            if (
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    ""
                ) != IERC721Receiver.onERC721Received.selector
            ) {
                revert MyError("unsafe recipient");
            }
        }
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        if (to.code.length != 0) {
            if (
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                ) != IERC721Receiver.onERC721Received.selector
            ) {
                revert MyError("unsafe recipient");
            }
        }
        transferFrom(from, to, tokenId);
    }

    function _mint(address to, uint tokenId) internal virtual {
        require(_ownerOf[tokenId] == address(0), "tokenId already exist");
        require(to != address(0), "to = zero address");
        _balanceOf[to]++;
        _ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint tokenId) internal virtual {
        require(_ownerOf[tokenId] != address(0), "tokenId no exist");
        address owner = _ownerOf[tokenId];
        _balanceOf[owner]--;
        _ownerOf[tokenId] = address(0);
        delete _approval[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }
}

contract MyNFT is ERC721 {
    uint public constant TOTAL = 1000;

    function mint(address to, uint tokenId) external {
        require(tokenId <= TOTAL, "tokenId out of range");
        _mint(to, tokenId);
    }
}

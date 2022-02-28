// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HodlBankTokens {
    struct User {
        uint256 tokenOwned;
        uint256 timeLocked; //in seconds
        uint256 timeOfDeposit;
    }
    address payable public owner;
    uint256 fee;
    mapping(address => mapping(address => User)) public tokenUserInfo;

    constructor(uint256 _fee) {
        owner = payable(msg.sender);
        fee = _fee;
    }

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _timeLocked
    ) public {
        require(_amount > 0, "Amount staked must be more than 0");
        uint256 _tokenOwned = (_amount * (1000 - fee)) / 1000;
        uint256 _bankFee = (_amount * fee) / 1000;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(_token).transfer(owner, _bankFee);
        if (tokenUserInfo[_token][msg.sender].tokenOwned > 0) {
            tokenUserInfo[_token][msg.sender].tokenOwned =
                tokenUserInfo[_token][msg.sender].tokenOwned +
                _tokenOwned;
        } else {
            tokenUserInfo[_token][msg.sender] = User(
                _tokenOwned,
                _timeLocked,
                block.timestamp
            );
        }
    }

    function withdraw(address _token) public {
        User storage user = tokenUserInfo[_token][msg.sender];
        require(user.tokenOwned > 0, "You have none of this Token staked.");
        require(
            block.timestamp >= (user.timeOfDeposit + user.timeLocked),
            "You tried to withdraw too soon!"
        );
        uint256 withdrawBalance = user.tokenOwned;
        user.tokenOwned = 0;
        user.timeLocked = 0;
        user.timeOfDeposit = 0;
        IERC20(_token).transfer(msg.sender, withdrawBalance);
    }

    function getUserInfo(address _userAddress, address _token)
        public
        view
        returns (uint256, bool)
    {
        User memory user = tokenUserInfo[_userAddress][_token];
        require(user.tokenOwned > 0, "This user has no deposit of this token.");
        bool canWithdraw = block.timestamp >=
            (user.timeOfDeposit + user.timeLocked);
        return (user.tokenOwned, canWithdraw);
    }
}

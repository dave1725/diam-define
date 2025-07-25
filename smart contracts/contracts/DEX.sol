// contracts/FlashLoan.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
    @title DEX.sol
    @notice a mock decentralized exchange with arbitrage pair
    @author techmac
 */

import { IERC20 } from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract Dex {
    bool public locked;

    address private immutable daiToken =
        0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
    address private immutable usdcToken =
        0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

    IERC20 private dai;
    IERC20 private usdc;

    uint256 dexARate = 90; // 1 DAI = 0.9 USDC
    uint256 dexBRate = 100; // 1 DAI = 1.0 USDC

    mapping(address => uint256) public daiBalances; // to keep track of users DAI balance during the process
    mapping(address => uint256) public usdcBalances; // to keep track of users USDC balance during the process

    constructor() {
        dai = IERC20(daiToken);
        usdc = IERC20(usdcToken);
    }
    
    function depositUSDC(uint256 _amount) external {
        usdcBalances[msg.sender] += _amount;
        uint256 allowance = usdc.allowance(msg.sender, address(this));
        require(allowance >= _amount, "token allowance < amount");
        usdc.transferFrom(msg.sender, address(this), _amount);
    }

    function depositDAI(uint256 _amount) external {
        daiBalances[msg.sender] += _amount;
        uint256 allowance = dai.allowance(msg.sender, address(this));
        require(allowance >= _amount, "token allowance < amount");
        dai.transferFrom(msg.sender, address(this), _amount);
    }

    function buyDAI() external {
        uint256 daiToReceive = ((usdcBalances[msg.sender] / dexARate) * 100) *
            (10**12);
        dai.transfer(msg.sender, daiToReceive);
    }

    function sellDAI() external {
        uint256 usdcToReceive = ((daiBalances[msg.sender] * dexBRate) / 100) /
            (10**12);
        usdcBalances[msg.sender] = 0;
        daiBalances[msg.sender] = 0;
        usdc.transfer(msg.sender, usdcToReceive);
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }
    
    function withdraw(address _tokenAddress) external nonReentrant {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier nonReentrant() {
        require(!locked,"arena locked");
        locked = true;
        _;
        locked = false;
    }
    receive() external payable {}
}
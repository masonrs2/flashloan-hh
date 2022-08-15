// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}

contract FlashLoan is ReentrancyGuard {
    using SafeMath for uint256;

    // Error functions
    error FlashLoan__NotEnoughDeposited();

    Token public token;
    uint256 public poolBalance;

    constructor(address _tokenAddress) {
        token = Token(_tokenAddress);
    }

    function depositTokens(uint256 _amount) external nonReentrant {
        if(_amount <= 0) {
            revert FlashLoan__NotEnoughDeposited();
        }
        token.transferFrom(msg.sender, address(this), _amount);
        poolBalance = poolBalance.add(_amount);
    }

    function flashLoan(uint256 _borrowAmount) external nonReentrant{
        // Send the "flash loan" to the borrower
        require(_borrowAmount > 0, "Borrow amount must be greater than 0 tokens");

        uint256 balanceBefore = token.balanceOf(address(this));

        //Ensure that the poolBalance is greater than the borrow amount 
        //Ensure the pool balance is equal to balance before loan is repaid
        require(poolBalance >= _borrowAmount, "Borrow amount is greater than the flash loan pool balance");
        assert(poolBalance == balanceBefore);

        token.transfer(msg.sender, _borrowAmount);
        
        // Use loan & receive original funds back from the borrower
        IReceiver(msg.sender).receiveTokens(address(token), _borrowAmount);

        // Ensure loan is repaid along with any interest/fees
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore,"Flash loan hasn't been repaid yet");
    }
}
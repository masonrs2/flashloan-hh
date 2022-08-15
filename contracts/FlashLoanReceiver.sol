// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";
import "./FlashLoan.sol";

contract FlashLoanReceiver { 
    FlashLoan private pool;
    address private owner;
    
    event loanReceived(address token, uint256 amount);

    constructor(address _poolAddress) {
        pool = FlashLoan(_poolAddress);
        owner = msg.sender;
    }

    function receiveTokens(address _tokenAddress, uint256 _amount) external {
        require(msg.sender == address(pool), "Sender is not the pool");
        // Loan received and emit transfer event
        require(Token(_tokenAddress).balanceOf(address(this)) == _amount, "Failed to receive loan funds");
        emit loanReceived(_tokenAddress, _amount);

        // Do whatever with the money loaned before having to repay it...

        // Pay back loan + interest + fees     
        require(Token(_tokenAddress).transfer(msg.sender, _amount), "Failed to pay back loan");
    }
    
     function executeFlashLoan(uint _amount) external {
        require(msg.sender == owner);
        pool.flashLoan(_amount);
    }
}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import {Token} from "./Token.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// import { console } from "hardhat/console.sol";

// instead of importing the receiver contract which will not be possible for different receivers,
// we can have a generate an interface that all receivers must implement
interface IReceiver {
  function receiveTokens(address tokenAddress, uint256 amount) external;
}

// Errors
error FlashLoan__InsufficientDepositAmount(string message);
error FlashLoan__InsufficientBorrowAmount(string message);
error FlashLoan__InsufficientPoolToken(string message);
error FlashLoan__LoanNotPaid(string message);

contract FlashLoan is ReentrancyGuard{
  Token private immutable CUSTOM_TOKEN;
  uint256 private poolBalance;

  modifier validateBorrowAmount(uint256 amount) {
    if (0 > amount)
      revert FlashLoan__InsufficientBorrowAmount({
        message: "The amount should be greater than 0"
      });
    _;
  }

  constructor(address _tokenAddress) {
    CUSTOM_TOKEN = Token(_tokenAddress);
  }

  function depositToken(uint256 _amount) external nonReentrant{
    if (_amount < 0)
      revert FlashLoan__InsufficientDepositAmount({
        message: "Deposit amount must be greater than zero"
      });
    CUSTOM_TOKEN.transferFrom(msg.sender, address(this), _amount);
    poolBalance = poolBalance + _amount;
  }

  function executeLoan(
    uint256 _borrowAmount
  ) external validateBorrowAmount(_borrowAmount) nonReentrant {
    uint256 balanceBefore = CUSTOM_TOKEN.balanceOf(address(this));

    // ensure that pool balance is same as the balance before
    assert(poolBalance == balanceBefore);

    if (balanceBefore < _borrowAmount)
      revert FlashLoan__InsufficientPoolToken({
        message: " Not enough token to lend"
      });

    // send token to receiver (msg.sender, which is the contract calling the pool)
    CUSTOM_TOKEN.transfer(msg.sender, _borrowAmount);
    IReceiver(msg.sender).receiveTokens(address(CUSTOM_TOKEN), _borrowAmount);

    uint256 balanceAfter = CUSTOM_TOKEN.balanceOf(address(this));
    // ensure that loan is paid back
    if (balanceAfter < balanceBefore)
      revert FlashLoan__LoanNotPaid({message: "Loan has not been paid"});
  }
}

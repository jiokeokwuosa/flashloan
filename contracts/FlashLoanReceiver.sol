//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import {FlashLoan} from "./FlashLoan.sol";
import {Token} from "./Token.sol";

// Errors
error FlashLoanReceiver__OnlyOwner(string message);
error FlashLoanReceiver__LoanRequestFailed();
error FlashLoanReceiver__OnlyPool(string message);

contract FlashLoanReceiver {
  FlashLoan private immutable POOL;
  address private immutable OWNER;

  // modifiers
  modifier onlyOwner() {
    if (msg.sender != OWNER)
      revert FlashLoanReceiver__OnlyOwner({
        message: "Only owner can perform this transaction"
      });
    _;
  }

  modifier onlyPool() {
    if (msg.sender != address(POOL))
      revert FlashLoanReceiver__OnlyPool({
        message: "Only pool contract can perform this transaction"
      });
    _;
  }

  // events
  event LoanReceived(address token, uint256 amount);

  constructor(address _poolAddress) {
    POOL = FlashLoan(_poolAddress);
    OWNER = msg.sender;
  }

  function executeFlashLoan(uint256 _amount) external onlyOwner {
    POOL.executeLoan(_amount);
  }

  // the flash loan contract will call this function when i request for flashloan
  // in this function i can do stuffs with the borrowed tokens and return it back
  function receiveTokens(address _tokenAddress, uint256 _amount) external  onlyPool{
    if (Token(_tokenAddress).balanceOf(address(this)) < _amount)
      revert FlashLoanReceiver__LoanRequestFailed();
      emit LoanReceived(_tokenAddress, _amount);

      // do stuffs with the loan ----------

      // return the loan
      require(Token(_tokenAddress).transfer(msg.sender, _amount), "Transfer of tokens failed");

    
  }
}

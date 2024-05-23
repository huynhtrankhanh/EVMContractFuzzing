pragma solidity ^0.8.0;

import "./PrimeFactorization.sol";

contract PushCall {
    PrimeFactorizationGame public primeContract;
    uint256 public counter = 0;
    uint256 public totalMoneyReceived = 0;

    struct Call {
        uint256 fnCode;
        uint256 arg1;
        uint256[] arg2;
    }

    Call[] public calls;

    constructor() {
        primeContract = new PrimeFactorizationGame();
    }

    function push(uint256 fnCode, uint256 arg1, uint256[] calldata arg2) external {
        calls.push(Call(fnCode, arg1, arg2));
    }

    function take() external payable {
        require(counter < calls.length, "No more calls to process.");
        Call storage currentCall = calls[counter];
        counter++;
        assert(totalMoneyReceived <= 200 ether);

        if (currentCall.fnCode % 3 == 0) {
            // Call claimPrize(uint256 numberIndex, uint256[] calldata factors) on primeContract
            uint256 initialBalance = address(this).balance;
            primeContract.claimPrize(currentCall.arg1 % 20, [currentCall.arg2[0] % 20]);
            uint256 finalBalance = address(this).balance;
            totalMoneyReceived += finalBalance - initialBalance;
        } else if (currentCall.fnCode % 3 == 1) {
            // Call deposit() on primeContract with arg1 as value
            (bool success, ) = address(primeContract).call{value: currentCall.arg1}(
                abi.encodeWithSignature("deposit()")
            );
            require(success, "Deposit failed");
        } else if (currentCall.fnCode % 3 == 2) {
            // Call withdraw(uint256 amount) on primeContract
            primeContract.withdraw(currentCall.arg1);
        } else {
            revert("Invalid function code");
        }
    }

    // Fallback function to receive Ether
    receive() external payable {}
}

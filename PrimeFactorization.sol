pragma solidity ^0.8.0;

contract PrimeFactorizationGame {
    address public owner;

    struct Number {
        uint256 value;
        uint256 prize;
        bool claimed;
    }

    Number[20] public numbers;
    mapping(uint256 => bool) public isPrimeFactorizationSubmitted;

    event PrizeClaimed(address claimant, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Explicit full initialization of all 20 numbers for completeness
        numbers[0] = Number(2, 0.5 ether, false);
        numbers[1] = Number(3, 0.5 ether, false);
        numbers[2] = Number(5, 1 ether, false);
        numbers[3] = Number(7, 1.5 ether, false);
        numbers[4] = Number(11, 2 ether, false);
        numbers[5] = Number(13, 2.5 ether, false);
        numbers[6] = Number(17, 3 ether, false);
        numbers[7] = Number(19, 3.5 ether, false);
        numbers[8] = Number(23, 4 ether, false);
        numbers[9] = Number(29, 4.5 ether, false);
        numbers[10] = Number(31, 5 ether, false);
        numbers[11] = Number(37, 5.5 ether, false);
        numbers[12] = Number(41, 6 ether, false);
        numbers[13] = Number(43, 6.5 ether, false);
        numbers[14] = Number(47, 7 ether, false);
        numbers[15] = Number(53, 7.5 ether, false);
        numbers[16] = Number(59, 8 ether, false);
        numbers[17] = Number(61, 8.5 ether, false);
        numbers[18] = Number(67, 9 ether, false);
        numbers[19] = Number(71, 9.5 ether, false);
    }

    function claimPrize(uint256 numberIndex, uint256[] calldata factors) external {
        require(numberIndex < numbers.length, "Invalid number index.");
        Number storage number = numbers[numberIndex];
        require(!number.claimed, "Prize already claimed.");
        require(isValidFactorization(number.value, factors), "Invalid or non-prime factorization.");
        
        (bool success, ) = msg.sender.call{value: number.prize}("");
        require(success, "Failed to send Ether");
        number.claimed = true;
        emit PrizeClaimed(msg.sender, number.prize);
    }

    function isValidFactorization(uint256 number, uint256[] calldata factors) internal pure returns (bool) {
        uint256 product = 1;
        for (uint256 i = 0; i < factors.length; i++) {
            if (!isPrime(factors[i]) || product * factors[i] > number) {
                return false;
            }
            product *= factors[i];
        }
        return product == number;
    }

    function isPrime(uint256 _number) internal pure returns (bool) {
        if (_number < 2) return false;
        for (uint256 i = 2; i * i <= _number; i++) {
            if (_number % i == 0) return false;
        }
        return true;
    }

    // Function to add funds to the contract. Only the owner can add funds.
    function deposit() external payable onlyOwner {
        require(msg.value > 0, "Deposit must be more than 0.");
    }

    // Withdraw function for extracting funds. Only the owner can withdraw.
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient funds.");
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether.");
    }
}

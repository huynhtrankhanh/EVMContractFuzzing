pragma solidity ^0.8.0;

contract FestivalContract {
    address public winner;

    // Event to log contributions
    event Contribution(address indexed sender, uint256 amount);

    // Event to announce the winner
    event WinnerAnnounced(address winner, uint256 totalAmount);

    // Function to contribute to the festival
    function contribute() external payable {
        require(msg.value == 1 ether, "You can only send 1 ether at a time");
        emit Contribution(msg.sender, msg.value);

        // Check if total balance reaches 10 ether
        if (address(this).balance == 10 ether) {
            winner = msg.sender;
            emit WinnerAnnounced(winner, address(this).balance);
        }
    }

    // Function for winner to claim their reward
    function claim() external {
        require(winner == msg.sender, "You are not the winner");
        payable(msg.sender).transfer(address(this).balance);
    }
}


import "./Festival.sol";
import "./ForcedEtherTransfer.sol";

contract FuzzFestival {
    ForcedEtherTransfer public forcedEtherTransfer;
    FestivalContract public festivalContract;
    uint256 counter;
    constructor() {
        forcedEtherTransfer = new ForcedEtherTransfer();
        festivalContract = new FestivalContract();
        counter = 0;
    }
    function shootEther(address payable _target) external payable {
        forcedEtherTransfer.shoot{value: msg.value}(_target);
    }
    function sendNormal() external payable {
        require(msg.value >= 1, "");
        festivalContract.contribute{value: 1 ether}();
        counter = counter + 1;
    }
}

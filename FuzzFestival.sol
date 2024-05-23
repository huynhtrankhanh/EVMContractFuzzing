import "./Festival.sol";
import "./ForcedEtherTransfer.sol";

contract AAAAAAAAAAAAAAAAAAAAAAAAAAAFuzzFestival {
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
        require(msg.value >= 1 ether, "");
        festivalContract.contribute{value: 1 ether}();
        counter = counter + 1;
    }
    function sendAnonymous() external payable {
        require(msg.value >= 1 ether, "");
        new Anonymous{value: 1 ether}(festivalContract);
    }
}

contract Anonymous {
    constructor(FestivalContract festivalContract) {
        festivalContract.contribute{value: 1 ether}();
    }
}

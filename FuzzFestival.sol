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
        require(msg.value >= 1 ether, "");
        festivalContract.contribute{value: 1 ether}();
        counter = counter + 1;
        if (counter == 3) {
            // can claim!
            uint256 previous = address(this).balance;
            festivalContract.claim();
            uint256 current = address(this).balance;
            assert(current - previous >= 3 ether);
            assert(false);
        }
    }
    function sendAnonymous() external payable {
        require(msg.value >= 1 ether, "");
        Anonymous entity = new Anonymous{value: 1 ether}(festivalContract);
        counter = counter + 1;
    }
}

contract Anonymous {
    FestivalContract saved;
    constructor(FestivalContract festivalContract) payable {
        festivalContract.contribute{value: 1 ether}();
        saved = festivalContract;
    }
}

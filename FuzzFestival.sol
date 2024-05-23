import "./Festival.sol";
import "./ForcedEtherTransfer.sol";

contract FuzzFestival {
    event AssertionFailed(string x);
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
        if (counter == 10) {
            // can claim!
            uint256 previous = address(this).balance;
            try festivalContract.claim() {
            } catch {
                emit AssertionFailed("no");
            }
            uint256 current = address(this).balance;
            assert(current - previous >= 3 ether);
        }
    }
    function sendAnonymous() external payable {
        require(msg.value >= 1 ether, "");
        Anonymous entity = new Anonymous{value: 1 ether}(festivalContract);
        counter = counter + 1;
    }
    fallback() external payable {}
}

contract Anonymous {
    FestivalContract saved;
    constructor(FestivalContract festivalContract) payable {
        festivalContract.contribute{value: 1 ether}();
        saved = festivalContract;
    }
}

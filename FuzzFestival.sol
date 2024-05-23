import "./Festival.sol";
import "./ForcedEtherTransfer.sol";

contract FuzzFestival {
    ForcedEtherTransfer public forcedEtherTransfer;
    FestivalContract public festivalContract;
    constructor() {
        forcedEtherTransfer = new ForcedEtherTransfer();
        festivalContract = new FestivalContract();
    }
    function shootEther(address payable _target) external payable {
        forcedEtherTransfer.shoot{value: msg.value}(_target);
    }
}

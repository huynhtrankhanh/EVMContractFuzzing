contract ForcedEtherTransfer {
    
    // Function to forcefully send Ether to an address
    function shoot(address payable _target) external payable {
        require(msg.value > 0, "Must send some ether");
        
        // Deploy a self-destructible contract and send ether to the target address
        new SelfDestructContract{value: msg.value}(_target);
    }
}

contract SelfDestructContract {
    constructor(address payable _target) payable {
        // Transfer all the ether stored in this contract to the target address and self-destruct
        selfdestruct(_target);
    }
}

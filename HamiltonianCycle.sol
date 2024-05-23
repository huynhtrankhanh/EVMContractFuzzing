pragma solidity ^0.8.0;

contract AAAAAAAAAAAAAMasterContract {
    ForcedEtherTransfer public forcedEtherTransfer;
    HamiltonianCycle public hamiltonianCycle;

    constructor() {
        forcedEtherTransfer = new ForcedEtherTransfer();
        hamiltonianCycle = new HamiltonianCycle();
    }

    function echidna_invariant() external returns (bool) {
        return address(hamiltonianCycle).balance == hamiltonianCycle.balance();
    }

    // Function to call shoot from ForcedEtherTransfer
    function shootEther(address payable _target) external payable {
        forcedEtherTransfer.shoot{value: msg.value}(_target);
    }

    // Function to deposit ether into HamiltonianCycle
    function depositEther() external payable {
        hamiltonianCycle.deposit{value: msg.value}();
    }

    // Function to set a graph in HamiltonianCycle
    function setGraph(uint256 _nodeCount, uint256[][] memory _edges) external {
        hamiltonianCycle.setGraph(_nodeCount, _edges);
    }

    // Function to find Hamiltonian cycle in HamiltonianCycle
    function findCycle(uint256[] memory _cycle) external {
        hamiltonianCycle.findHamiltonianCycle(_cycle);
    }
}

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

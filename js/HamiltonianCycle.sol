pragma solidity ^0.8.0;

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

    function setGraph(uint256 _nodeCount, uint256[][] memory _edges) external onlyOwner {
        require(!isGraphSet, "Graph is already set");
        nodeCount = _nodeCount;
        for (uint256 i = 0; i < _edges.length; i++) {
            uint256 from = _edges[i][0];
            uint256 to = _edges[i][1];
            require(from < nodeCount && to < nodeCount, "Invalid node index");
            edges[from][to] = true;
        }
        isGraphSet = true;
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

        assert(address(this).balance == balance, "Contract balance mismatch");

        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external  view returns (uint balance);
    function allowance(address tokenOwner, address spender) external  view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SafeMath {
    function safeAdd (uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "Invalid operation!");
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a==0 || c/a==b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract myToken is ERC20Interface, SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) lastCalled;
    address public contractCreator;

    // Lottery variables
    address public manager;
    address[] public players;
    address[] private nonReapeat;
    address public winner;
    uint public drawTime;
    uint public ticketPrice = 100;
    uint public prizePercentage = 90;
    uint public cooldown = 2 minutes;

    constructor() {
        name = "myToken";
        symbol = "WIR";
        decimals = 3;
        _totalSupply = 123456000; 
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        contractCreator = msg.sender;

        // Lottery initialization
        manager = msg.sender;
        drawTime = block.timestamp - cooldown;
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function faucet() public returns (bool success)
    {
        require(block.timestamp >= lastCalled[msg.sender] + 10 seconds, "You must wait 30 minutes between calls");
        lastCalled[msg.sender] = block.timestamp;
        balances[contractCreator] = safeSub(balances[contractCreator], 500);
        balances[msg.sender] = safeAdd(balances[msg.sender], 500);
        return true;
    }

    // Lottery functions
    function enter() public
    {
        require(balances[msg.sender] >= ticketPrice, "Insufficient balance to enter");
        require(msg.sender != manager, "Manager cannot participate");
        balances[msg.sender] = safeSub(balances[msg.sender], ticketPrice);
        players.push(msg.sender);
    }

    function random() private view returns (uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function draw() public
    {
        require(msg.sender == contractCreator, "Only contractCreator can draw");
        require(block.timestamp >= drawTime + cooldown, "Cannot draw within 2 minutes");
        require(players.length > 0, "At least one player is required");

        uint index = random() % players.length;
        winner = players[index];

        uint prize = safeMul(ticketPrice, players.length) * prizePercentage / 100;
        balances[winner] = safeAdd(balances[winner], prize);

        delete players;
        drawTime = block.timestamp;
    }

    function getAllPlayers() public returns (address[] memory)
    {
        delete nonReapeat;
        bool exist = false;

        for(uint i = 0; i < players.length; i++)
        {

            for(uint j = 0; j < nonReapeat.length; j++)
            {
                if(players[i] == nonReapeat[j])
                {
                    exist = true;
                    break;
                }
            }
            if(exist == false)
            {
                nonReapeat.push(players[i]);
            }
        }
        
        return nonReapeat;
    }
}

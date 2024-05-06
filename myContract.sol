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

    // 3 optional rules
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) lastCalled;

    constructor()
    {
        // optional rules
        name = "myToken";  // Name of the token 
        symbol = "WIR";    // Symbol of the token
        decimals = 3;      // The minimum unit value of a token.

        _totalSupply = 123456000; 
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        // faucet
        contractCreator = msg.sender;
    }

    // implement mandatory rules
    function totalSupply() public view override returns (uint)
    {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public override returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint remaining)                                       
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success)
    {
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
        //approve(contractCreator, 500);
        //transferFrom(contractCreator, msg.sender, 500);
        
        return true;
    }
    // ---------------------------------------------------------------
    // faucet function
    // ---------------------------------------------------------------

    function random() private view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
    }

    


    address public contractCreator;

}
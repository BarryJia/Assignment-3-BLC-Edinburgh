// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Token {
    // Public and private variables of the token
    string private i_name;
    string private i_symbol;
    uint128 private price_per_token;
    uint256 private totalSupply;
    address payable public immutable owner;
    bool private isStopped = false;
    bool internal inProgress = false;
    mapping(address => uint256) private balanceOfToken;
    mapping(address => uint256) private last_transaction_time;
    mapping(address => uint256) private gasPrice;
    uint256 private maxGas;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 mintedValue);
    event Sell(address indexed from, uint256 soldValue);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) {
        totalSupply = initialSupply; // Update total supply with the deployed amount
        balanceOfToken[msg.sender] = totalSupply; // Give the creator all initial tokens
        i_name = tokenName; // Set the name for display purposes
        i_symbol = tokenSymbol; // Set the symbol for display purposes
        owner = payable(msg.sender); // Set the owner of the contract
        price_per_token = 600; // Set the price per token as 600 Wei.
        maxGas = 9000000; // Set the maximum gas for the contract
    }

    modifier reentrancyGuard() {
        require(!inProgress, "The function is already in progress");
        require(
            last_transaction_time[msg.sender] + 10 minutes <= block.timestamp,
            "Too many transactions in short time."
        );
        inProgress = true;
        last_transaction_time[msg.sender] = block.timestamp;
        _;
        inProgress = false;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(!isStopped, "The contract is stopped");
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOfToken[_from] >= _value);
        // Check for overflows
        require(balanceOfToken[_to] + _value >= balanceOfToken[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balanceOfToken[_from] + balanceOfToken[_to];
        // Subtract from the sender
        balanceOfToken[_from] -= _value;
        // Add the same to the recipient
        balanceOfToken[_to] += _value;
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOfToken[_from] + balanceOfToken[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(
        address _to,
        uint256 _value
    ) public reentrancyGuard returns (bool success) {
        last_transaction_time[msg.sender] = block.timestamp;
        gasPrice[msg.sender] = 300000;
        if (_value > 20) {
            gasPrice[msg.sender] = 2 * gasPrice[msg.sender];
        }
        require(gasleft() >= gasPrice[msg.sender], "Insufficient gas");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Mints a specified amount of tokens and adds them to the contract owner's balance.
     * @param _amount Amount of tokens to be minted.
     */
    function mint(address _to, uint256 _amount) public returns (bool success) {
        require(_amount > 0, "Invalid amount.");
        require(msg.sender == owner, "Only the owner can mint tokens.");
        totalSupply += _amount;
        balanceOfToken[msg.sender] += _amount;
        _transfer(msg.sender, _to, _amount);
        emit Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Sells an amount of tokens from the token-holders.
     * @param _amount Amount of tokens to be sold.
     */
    function sell(
        uint256 _amount
    ) public payable reentrancyGuard returns (bool success) {
        last_transaction_time[msg.sender] = block.timestamp;
        gasPrice[msg.sender] = 300000;
        if (_amount > 20) {
            gasPrice[msg.sender] = 2 * gasPrice[msg.sender];
        }
        require(gasleft() >= gasPrice[msg.sender], "Insufficient gas");
        require(_amount > 0, "Invalid amount.");
        require(totalSupply >= _amount, "Insufficient supply.");
        totalSupply -= _amount;
        balanceOfToken[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount * price_per_token);
        emit Sell(msg.sender, _amount);
        return true;
    }

    /**
     * @dev Close and destroy the contract, transfer the contract balance to owner.
     */
    function close() public {
        require(msg.sender == owner, "Only the owner can close the contract");
        owner.transfer(address(this).balance);
        selfdestruct(owner);
    }

    function getName() public view returns (string memory) {
        return i_name;
    }

    function getSymbol() public view returns (string memory) {
        return i_symbol;
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getPrice() public view returns (uint128) {
        return price_per_token;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balanceOfToken[_user];
    }

    fallback() external payable {
        // Do nothing, as the fallback function does not need to perform any action
    }

    receive() external payable {
        // to ignore warnings
    }
}

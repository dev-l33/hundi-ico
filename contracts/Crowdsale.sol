pragma solidity ^0.4.18;

import "./HundiToken.sol";
import "./Ownable.sol";
/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
    
    // The token being sold
    HundiToken public token;

    // No-bonus price: 1 ether = 1800 HND $0.5 per coin
    uint public rate = 1800;

    // minium contribution value: 0.01 ether
    uint public constant MIN_VALUE = 0.01 ether;

    // Date for main ICO: June 15, 2018 12:00 pm UTC to July 15, 2018 12:00 pm UTC
    uint public saleStartDate = 1529064000;
    uint public saleEndDate = 1531656000;

    // The owner of this address is the Marketing fund
    address public marketingFundAddress;

    uint public constant MARKETING_FUND = 30000000 ether;

    // The owner of this address is the Bounty fund
    address public bountyFundAddress;

    uint public constant BOUNTY_FUND = 15000000 ether;

    // crowdsale + reserved fund 180,000,000
    uint public constant CROWDSALE_FUND = 45000000 ether;
    uint public constant RESERVED_FUND = 210000000 ether;

    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    // amount of purchased token
    uint256 public tokenSold;

    // whether token can be sold or not
    bool inSale = true;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, uint value, uint amount);

    function Crowdsale(
        address _wallet,
        address _marketingFundAddress,
        address _bountyFundAddress) public
        {
        require(_wallet != address(0));
        require(_marketingFundAddress != address(0));
        require(_bountyFundAddress != address(0));

        token = createTokenContract();

        wallet = _wallet;
        marketingFundAddress = _marketingFundAddress;
        bountyFundAddress = _bountyFundAddress;

        // // Emission 300,000,000

        token.mint(marketingFundAddress, MARKETING_FUND);
        token.mint(bountyFundAddress, BOUNTY_FUND);
        
        // reserve fund
        token.mint(wallet, RESERVED_FUND);

        // pre sale ico + main sale ico
        token.mint(this, CROWDSALE_FUND);
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() internal returns (HundiToken) {
        return new HundiToken();
    }

    // @return if main sale is in progress
    function isMainSale() internal view returns(bool) {
        return (now >= saleStartDate && now <= saleEndDate);
    }

    // buy tokens from contract by sending ether
    function () public payable {
        // only accept a minimum amount of ETH?
        require(msg.value >= MIN_VALUE && inSale);

        uint tokens = getTokenAmount(msg.value);
        
        token.transfer(msg.sender, tokens);

        tokenSold += tokens;
        weiRaised += msg.value;

        TokenPurchase(msg.sender, msg.value, tokens);
        forwardFunds();
    }

    // calculate token amount for wei
    function getTokenAmount(uint weiAmount) internal view returns(uint) {
        uint tokens = weiAmount * rate;
        uint bonus;

        // calculate bonus amount
        if (isMainSale()) {
            if (weiAmount >= 100 ether)
                bonus = tokens / 4; // 25% for 100 eth or more
            else if (weiAmount >= 50 ether)
                bonus = tokens / 5; // 20% for 50 eth or more
            else if (weiAmount >= 10 ether)
                bonus = tokens * 15 / 100; // 15%
            else
                bonus = tokens / 10; // 10% for others
        }

        return tokens + bonus;
    }

    // allocate token manually
    function allocate(address _address, uint _amount) public onlyOwner returns (bool success) {
        return token.transfer(_address, _amount);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function setSaleState(bool _inSale) onlyOwner public {
        inSale = _inSale;
    }

    function setSaleStartDate(uint _date) onlyOwner public {
        saleStartDate = _date;
    }

    function setSaleEndDate(uint _date) onlyOwner public {
        saleEndDate = _date;
    }

    function setRate(uint _rate) onlyOwner public {
        rate = _rate;
    }

    /**
    * @dev Transfers the current balance to the owner and terminates the contract.
    */
    function destroy() onlyOwner public {
        token.destroy();
        selfdestruct(owner);
    }

    function destroyAndSend(address _recipient) onlyOwner public {
        token.destroyAndSend(_recipient);
        selfdestruct(_recipient);
    }
}
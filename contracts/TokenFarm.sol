// Features
// 1. Stake Tokens
// 2. unstake Tokens
// 3. Issue Tokens
// 4. add allowed Tokens
// 5. get Eth Value

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    //mapping  token address => staker address => amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers;

    //list of Allowed Tokens
    address[] public allowedTokens;
    IERC20 public dappToken;

    //100 ETH 1:1 for every 1 ETH, we give 1 DappToken
    //50 ETH and 50 DAI staked, and we want to give a reward of 1 DAPP / 1 DAI

    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    //map the tokens to priceFeed
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Issue tokens to all stakers
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            //Grab the recipient and send them a token reward based on
            //their total value lokced
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        //gas expensive, looking through all the addresses and stuff.
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No Tokens Staked!!");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        //1 ETH -> $ 3584
        //2000
        //200 DAI -> $200
        //200

        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }

        //get the price of token
        //price of token * stakingBalance[_token][user]
        getTokenValue(_token);
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        //10 ETH
        //ETH/USD -> 100
        //10*100 = 1,000
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        //What tokens can they stake ?
        //How much can they stake ?
        require(_amount > 0, "Amount should be greater than 0");
        //Check if the token is allowed
        require(tokenIsAllowed(_token), "Token is Currently not allowed!!");
        //Now we transfer the tokens
        //We need abi to call transferFrom funvtinos
        //so we're gonna need IERC20
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        // If this is the users first token, then add it to the list
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unStakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0!!");
        IERC20(_token).transfer(msg.sender, balance);
        // Coz we are gonna transfer the entire balance here
        stakingBalance[_token][msg.sender] = 0;
        //reinterancy attack
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;

        //add functionality to renove the stakers as they unstake
    }

    // internal means only this contract can call this function
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    //only owner can do this
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        //so we loop through the list to see if the token
        //is present or not, if its not present we return false

        for (
            uint256 allowedTokenIndex = 0;
            allowedTokenIndex < allowedTokens.length;
            allowedTokenIndex++
        ) {
            if (allowedTokens[allowedTokenIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}

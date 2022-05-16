// Features
// 1. Stake Tokens
// 2. unstake Tokens
// 3. Issue Tokens
// 4. add allowed Tokens
// 5. get Eth Value

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFarm is Ownable {
    //list of Allowed Tokens
    address[] public allowedTokens;

    function stakeTokens(uint256 _amount, address _token) public {
        //What tokens can they stake ?
        //How much can they stake ?
        require(_amount > 0, "Amount should be greater than 0");
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

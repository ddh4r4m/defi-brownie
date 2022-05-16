pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DharmaToken is ERC20 {
    constructor() ERC20("Dharma Token", "DHRMA") {
        //1 million initial supply (18 + 6 zeros )
        _mint(msg.sender, 1000000000000000000000000);
    }
}

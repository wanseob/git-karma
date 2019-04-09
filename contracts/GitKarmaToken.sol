pragma solidity >=0.4.21 < 0.6.0;

import "casper-pepow-token/contracts/ERC1913.sol";

contract GitKarmaToken is ERC1913 {
    uint256 constant DAY = 86400;

    uint256 timestamp;
    bytes32 public anchorHash;

    constructor() public ERC1913('GitKarmaToken', 'GKT', 18, 32, 10368000, 540){}

    function updateTimestamp() public {
        require(now > timestamp + DAY);
        timestamp = now;
    }
}

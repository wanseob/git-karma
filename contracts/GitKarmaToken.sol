pragma solidity >=0.4.21 < 0.6.0;

import "casper-pepow-token/contracts/ERC1913.sol";
import {PatriciaTree} from "solidity-patricia-tree/contracts/tree.sol";

contract GitKarmaToken is ERC1913 {
    uint256 constant DAY = 86400;
    using SafeMath for uint256;

    uint256 timestamp;
    bytes32 public anchorHash;
    mapping(address => uint256) karma;

    constructor() public ERC1913('GitKarmaToken', 'GKT', 18, 32 ether, 10368000, 540){
        timestamp = now;
        anchorHash = keccak256(abi.encodePacked(now, blockhash(block.number - 1)));
    }

    function updateTimestamp() public {
        require(now > timestamp + DAY);
        timestamp = now;
        anchorHash = keccak256(abi.encodePacked(now, blockhash(block.number - 1)));
    }

    function applyKarma(address _user, uint256 _karma, uint _branchMask, bytes32[] memory _siblings) public {
        // Verify merkle proof first
//        PatriciaTree.verifyProof(
//            finalizedCheckpoint,
//            abi.encodePacked(_user),
//            abi.encodePacked(_karma),
//            _branchMask,
//            _siblings
//        );

        // Check previous karma
        uint256 _prevKarma = karma[_user];
        require(_prevKarma <= _karma, "Karma does not decrease");

        // Mint karma
        uint256 _amountToMint = _karma.sub(_prevKarma);
        _mint(_user, _amountToMint);

        // Update total karma
        karma[_user] = _karma;

        // Update timestamp if needed
        if (now > timestamp + DAY) {
            updateTimestamp();
        }
    }
}

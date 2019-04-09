pragma solidity >=0.4.21 < 0.6.0;

import {PatriciaTree} from "solidity-patricia-tree/contracts/tree.sol";
import {BloomFilter} from "solidity-bloom-filter/contracts/BloomFilter.sol";
import {ECDSA} from "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";


contract PlasmaContract {
    using BloomFilter for uint256;
    using PatriciaTree for PatriciaTree.Tree;
    using ECDSA for bytes32;

    uint8 public constant HASH_COUNT = 3;
    address public operator;

    PatriciaTree.Tree tree;
    mapping(address=>bytes32) lastVote;

    constructor() public {
        operator = msg.sender;
    }

    event Upvote(bytes32 indexed _repoId, address indexed _voter, bytes32 _anchorHash);
    event Karma(address indexed _user, uint256 _totalKarma);
    event Mint(address indexed _to, bytes32 indexed _repoId);

    function registerRepository(bytes32 _repoId, bytes memory _ownerSign, bytes memory _operatorSign) public {
        // Check multi sig first
        require(_repoId.toEthSignedMessageHash().recover(_ownerSign) == msg.sender, "invalid owner signature");
        bytes32 _signedHash = keccak256(abi.encodePacked(_repoId, _ownerSign));
        require(_signedHash.toEthSignedMessageHash().recover(_operatorSign) == operator, "invalid operator signature");

        // Check already exist
        require(tree.get(abi.encodePacked(_repoId)).length == 0, "Already registered");
        // Add to the merkle tree
        tree.insert(abi.encodePacked(_repoId), abi.encodePacked(msg.sender, uint256(0), uint32(0)));
    }

    /**
     * @dev
     * @param _repoId bytes32 value of repository id on gitcoin
     * @param _anchorHash Anchor contract on the main chain updates the anchor hash everyday
     * @param _voterSign Multi-sig 1
     * @param _operatorSign Multi-sig 2
     */
    function upvote(bytes32 _repoId, bytes32 _anchorHash, bytes memory _voterSign, bytes memory _operatorSign) public {
        // Check multi sig first
        bytes32 _originalHash = keccak256(abi.encodePacked(_repoId, _anchorHash));
        require(_originalHash.toEthSignedMessageHash().recover(_voterSign) == msg.sender, "invalid voter signature");
        bytes32 _signedHash = keccak256(abi.encodePacked(_repoId, _anchorHash, _voterSign));
        require(_signedHash.toEthSignedMessageHash().recover(_operatorSign) == operator, "invalid operator signature");

        // Do not accept if it is already voted for this time
        require(_anchorHash !=  lastVote[msg.sender], "Already voted");

        // Should already exist
        bytes memory _item = tree.get(abi.encodePacked(_repoId));
        require(_item.length != 0);

        // Decode stored item
        (address _owner, uint256 _filter, uint32 _token) = abi.decode(_item, (address, uint256, uint32));

        // Update filter
        _filter = _filter.addToBitmap(HASH_COUNT, keccak256(abi.encodePacked(msg.sender)));

        // Mint a karma token when it filled out all bit field
        if(_filter == uint256(0) - 1) {
            // Mint karma token
            _filter = 0;
            _token = _token + 1;
            emit Mint(_owner, _repoId);

            // Update total karma
            (uint256 _totalKarma) = abi.decode(tree.get(abi.encodePacked(_owner)), (uint256));
            _totalKarma = _totalKarma + 1;
            tree.insert(abi.encodePacked(_owner), abi.encodePacked(_totalKarma));
            emit Karma(_owner, _totalKarma);
        }
        // Apply upvote result
        tree.insert(abi.encodePacked(_repoId), abi.encodePacked(_owner, _filter, _token));

        emit Upvote(_repoId, msg.sender, _anchorHash);
    }

    function getKarmaProof(address _user) public view returns (uint256 _karma, uint _branchMask, bytes32[] memory _siblings) {
        _karma = abi.decode(tree.get(abi.encodePacked(_user)), (uint256));
        (_branchMask, _siblings) = tree.getProof(abi.encodePacked(_user));
    }
}

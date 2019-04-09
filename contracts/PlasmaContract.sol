pragma solidity >=0.4.21 < 0.6.0;

import {PatriciaTree} from "solidity-patricia-tree/contracts/tree.sol";
import {BloomFilter} from "solidity-bloom-filter/contracts/BloomFilter.sol";


contract PlasmaContract {
    using BloomFilter for uint256;
    using PatriciaTree for PatriciaTree.Tree;

    uint8 public constant HASH_COUNT = 64; // KARMA MINING DIFFICULTY
    address public superAdmin; // only for demo play

    PatriciaTree.Tree tree;
    mapping(address => bytes32) lastVote;
    mapping(address => bool) operators;

    constructor() public {
        superAdmin = msg.sender;
    }

    modifier adminOnly() {
        require(msg.sender == superAdmin);
        _;
    }

    event Upvote(bytes32 indexed _repoId, address indexed _voter, bytes32 _anchorHash);
    event Karma(address indexed _user, uint256 _totalKarma);
    event Mint(address indexed _to, bytes32 indexed _repoId);

    function addOperator(address _operator) adminOnly public {
        operators[_operator] = true;
    }

    function registerRepository(bytes32 _repoId, bytes memory _ownerSign, bytes memory _operatorSign) public {
        // Check multi sig first
        require(recover(_repoId, _ownerSign) == msg.sender, "invalid owner signature");
        address _operator = recover(keccak256(_ownerSign), _operatorSign);
        require(operators[_operator], "invalid operator signature");

        // Check already exist
        require(tree.get(abi.encodePacked(_repoId)).length == 0, "Already registered");
        // Add to the merkle tree
        tree.insert(abi.encodePacked(_repoId), abi.encode(msg.sender, uint256(0), uint256(0)));
    }

    function recover(bytes32 _val, bytes memory _signature) public pure returns (address) {
        bytes32 _hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _val));
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        return ecrecover(_hash, v, r, s);
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
        require(recover(_originalHash, _voterSign) == msg.sender, "invalid voter signature");
        address _operator = recover(keccak256(_voterSign), _operatorSign);
        require(operators[_operator], "invalid operator signature");

        // Do not accept if it is already voted for this time
        require(_anchorHash != lastVote[msg.sender], "Already voted");

        // Should already exist
        bytes memory _item = tree.get(abi.encodePacked(_repoId));
        require(_item.length == 96, "invalid size");

        // Decode stored item
        (address _owner, uint256 _filter, uint256 _token) = abi.decode(_item, (address, uint256, uint256));

        // Update filter
        _filter = _filter.addToBitmap(HASH_COUNT, keccak256(abi.encodePacked(msg.sender)));

        // Mint a karma token when it filled out all bit field
        if (_filter == uint256(0) - 1) {
            // Mint karma token
            _filter = 0;
            _token = _token + 1;
            emit Mint(_owner, _repoId);

            // Update total karma
            bytes memory _storedKarma = tree.get(abi.encodePacked(_owner));
            uint256 _totalKarma;
            if(_storedKarma.length == 0) _totalKarma = 0;
            else (_totalKarma) = abi.decode(_storedKarma, (uint256));
            _totalKarma = _totalKarma + 1;
            tree.insert(abi.encodePacked(_owner), abi.encodePacked(_totalKarma));
            emit Karma(_owner, _totalKarma);
        }
        // Apply upvote result
        tree.insert(abi.encodePacked(_repoId), abi.encode(_owner, _filter, _token));

        emit Upvote(_repoId, msg.sender, _anchorHash);
    }

    function getKarmaProof(address _user) public view returns (uint256 _karma, uint _branchMask, bytes32[] memory _siblings) {
        _karma = abi.decode(tree.get(abi.encodePacked(_user)), (uint256));
        (_branchMask, _siblings) = tree.getProof(abi.encodePacked(_user));
    }

    function getRootHash() public view returns(bytes32) {
        return tree.root;
    }
}

pragma solidity ^0.5.6;

import "./nft/KlayChicken.sol";
import "./nft/KlayChickenSunsal.sol";
import "./ownership/Ownable.sol";
import "./math/SafeMath.sol";

contract GovernanceV1 is Ownable {
    using SafeMath for uint256;

    uint8 public constant voting = 0;
    uint8 public constant sameResult = 1;
    uint8 public constant forResult = 2;
    uint8 public constant againstResult = 3;

    uint256 public minProposePeriod = 86400;
    uint256 public maxProposePeriod = 259200;
    KlayChicken public chickenContract;
    KlayChickenSunsal public sunsalContract;

    constructor(KlayChicken _chickenContract, KlayChickenSunsal _sunsalContract)
        public
    {
        chickenContract = _chickenContract;
        sunsalContract = _sunsalContract;
    }

    bool public governIsActive = true;
    uint256 public proposePrice = 5;
    uint256 public multiplier = 1000000000000000000;

    // propose struct
    struct Proposal {
        address proposer;
        string title;
        string content;
        uint256 blockNumber;
        uint256 votePeriod;
    }

    Proposal[] public proposalArray;
    // 안건번호 => tokenNum => true or false
    mapping(uint256 => mapping(uint256 => bool)) public voteBool;
    mapping(uint256 => uint256[]) public votedList;
    mapping(uint256 => uint256) public votesFor;
    mapping(uint256 => uint256) public votesAgainst;

    function setGovernState(bool newState) public onlyOwner {
        governIsActive = newState;
    }

    function setProposePrice(uint256 newPrice) public onlyOwner {
        proposePrice = newPrice;
    }

    // Propose 함수
    function propose(
        string calldata _title,
        string calldata _content,
        uint256 _votePeriod
    ) external payable {
        uint256 _proposePrice = proposePrice.mul(multiplier);
        uint256 _chickenBalance = chickenContract.balanceOf(msg.sender).add(
            sunsalContract.balanceOf(msg.sender)
        );
        require(governIsActive, "govern OFF now");
        require(msg.value >= _proposePrice, "proposal money is not enough");
        require(_chickenBalance > 2, "your chicken is less than 3");
        require(
            minProposePeriod <= _votePeriod && _votePeriod <= maxProposePeriod,
            "votePeriod is not correct"
        );

        uint256 _proposalNum = proposalArray.length;

        proposalArray.push(
            Proposal({
                proposer: msg.sender,
                title: _title,
                content: _content,
                blockNumber: block.number,
                votePeriod: _votePeriod
            })
        );

        votesFor[_proposalNum] = 0;
        votesAgainst[_proposalNum] = 0;
    }

    // 스페셜은 4표, 일반은 1표
    function voteFor(uint256 _proposalNum, uint256[] calldata _voteNum)
        external
    {
        require(governIsActive, "govern OFF now");
        require(
            proposalArray.length > _proposalNum,
            "there's not yet proposal"
        );
        require(voteResult(_proposalNum) == voting, "it's not on a vote now");
        uint256 _voteNumLength = _voteNum.length;
        for (uint256 i = 0; i < _voteNumLength; i += 1) {
            require(
                voteBool[_proposalNum][_voteNum[i]] != true,
                "already voted"
            );
            require(
                chickenContract.ownerOf(_voteNum[i]) == msg.sender ||
                    sunsalContract.ownerOf(_voteNum[i]) == msg.sender,
                "msg sender is not owner of this token"
            );

            if (_voteNum[i] > 899) {
                votesFor[_proposalNum] += 4;
            } else {
                votesFor[_proposalNum] += 1;
            }

            voteBool[_proposalNum][_voteNum[i]] = true;
            votedList[_proposalNum].push(_voteNum[i]);
        }
    }

    function voteAgainst(uint256 _proposalNum, uint256[] calldata _voteNum)
        external
    {
        require(governIsActive, "govern OFF now");
        require(
            proposalArray.length > _proposalNum,
            "there's not yet proposal"
        );
        require(voteResult(_proposalNum) == voting, "it's not on a vote now");
        uint256 _voteNumLength = _voteNum.length;
        for (uint256 i = 0; i < _voteNumLength; i += 1) {
            require(
                voteBool[_proposalNum][_voteNum[i]] != true,
                "already voted"
            );
            require(
                chickenContract.ownerOf(_voteNum[i]) == msg.sender ||
                    sunsalContract.ownerOf(_voteNum[i]) == msg.sender,
                "msg sender is not owner of this token"
            );

            if (_voteNum[i] > 899) {
                votesAgainst[_proposalNum] += 4;
            } else {
                votesAgainst[_proposalNum] += 1;
            }

            voteBool[_proposalNum][_voteNum[i]] = true;
            votedList[_proposalNum].push(_voteNum[i]);
        }
    }

    // 정보 받아오는 함수들

    function getVoteList(uint256 _proposalNum)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _votingList = votedList[_proposalNum];
        return _votingList;
    }

    function totalProposals() public view returns (uint256) {
        uint256 _totalProposal = proposalArray.length;
        return _totalProposal;
    }

    function voteResult(uint256 _proposalNum) public view returns (uint8) {
        Proposal memory _wantProposal = proposalArray[_proposalNum];
        uint256 _for = votesFor[_proposalNum];
        uint256 _against = votesAgainst[_proposalNum];

        if (
            _wantProposal.blockNumber.add(_wantProposal.votePeriod) >=
            block.number
        ) {
            return voting;
        } else if (_for == _against) {
            return sameResult;
        } else if (_for > _against) {
            return forResult;
        } else if (_for < _against) {
            return againstResult;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}

pragma solidity ^0.5.6;

import "./ownership/Ownable.sol";

contract TugOfWar is Ownable {
    uint8 public constant abstention = 0;
    uint8 public constant rock = 1;
    uint8 public constant scissors = 2;
    uint8 public constant paper = 3;
    // 현재 뼈파, 순살파 점수
    uint256 public boneTotalScore = 0;
    uint256 public sunsalTotalScore = 0;
    // 현재 라운드
    uint256 public gameRound = 0;
    // 이겼을 때 비겼을 때 점수
    uint8 public winScore = 2;
    uint8 public drawScore = 1;

    bool public gameIsActive = true;

    // 일회용
    uint8 public __result;
    uint8 public __win;

    // 랭킹용
    uint256 rankingGetNum = 0;
    mapping(uint256 => uint256[]) rankingList;

    // 라운드 => chickenList
    mapping(uint256 => uint256[]) eachBetList;
    // 라운드 => 치킨번호 => bool
    mapping(uint256 => mapping(uint256 => bool)) eachBetBool;
    // 라운드 => 묵찌빠 => chickenList
    mapping(uint256 => mapping(uint8 => uint256[])) eachRSPList;
    // 치킨번호 => 점수
    mapping(uint256 => uint256) eachScore;
    // 치킨번호 => 참여수
    mapping(uint256 => uint256) eachParticipate;
    // 라운드 => 묵찌빠 => 표
    mapping(uint256 => mapping(uint8 => uint256)) boneTotalBet;
    mapping(uint256 => mapping(uint8 => uint256)) sunsalTotalBet;

    // propose struct
    struct RoundInfo {
        uint8 boneScore;
        uint8 sunsalScore;
        uint8 result;
        uint8 boneResult;
        uint8 sunsalResult;
    }

    RoundInfo[] public roundInfoArray;

    function setGameState(bool newState) public onlyOwner {
        gameIsActive = newState;
    }

    function setScore(uint8 _winScore, uint8 _drawScore) public onlyOwner {
        winScore = _winScore;
        drawScore = _drawScore;
    }

    // 가위바위보 함수
    function boneRSP(uint8 _rsp, uint256[] calldata _rspNum) external {
        require(gameIsActive, "game OFF now");
        uint256 _listLength = _rspNum.length;
        for (uint256 i = 0; i < _listLength; i += 1) {
            if (eachBetBool[gameRound][_rspNum[i]] != true) {
                eachBetList[gameRound].push(_rspNum[i]);
                eachRSPList[gameRound][_rsp].push(_rspNum[i]);
                eachParticipate[_rspNum[i]] += 1;
                eachBetBool[gameRound][_rspNum[i]] = true;
                boneTotalBet[gameRound][_rsp] += 1;
            }
        }
    }

    function sunsalRSP(uint8 _rsp, uint256[] calldata _rspNum) external {
        require(gameIsActive, "game OFF now");
        uint256 _listLength = _rspNum.length;
        for (uint256 i = 0; i < _listLength; i += 1) {
            if (eachBetBool[gameRound][_rspNum[i]] != true) {
                eachBetList[gameRound].push(_rspNum[i]);
                eachRSPList[gameRound][_rsp].push(_rspNum[i]);
                eachParticipate[_rspNum[i]] += 1;
                eachBetBool[gameRound][_rspNum[i]] = true;
                sunsalTotalBet[gameRound][_rsp] += 1;
            }
        }
    }

    function raffle(uint8 _result, uint8 _win) public onlyOwner {
        gameIsActive = false;

        __result = _result;
        __win = _win;

        uint256 _boneR = boneTotalBet[gameRound][rock];
        uint256 _boneS = boneTotalBet[gameRound][scissors];
        uint256 _boneP = boneTotalBet[gameRound][paper];
        uint256 _sunsalR = sunsalTotalBet[gameRound][rock];
        uint256 _sunsalS = sunsalTotalBet[gameRound][scissors];
        uint256 _sunsalP = sunsalTotalBet[gameRound][paper];
        uint8 _boneResult;
        uint8 _sunsalResult;
        uint8 _boneScore;
        uint8 _sunsalScore;

        // each
        uint256 _drawNum = eachRSPList[gameRound][__result].length;
        uint256 _winNum = eachRSPList[gameRound][__win].length;

        // boneResult 뽑는과정
        if (_boneR > _boneS) {
            if (_boneR > _boneP) {
                _boneResult = rock;
            } else if (_boneR < _boneP) {
                _boneResult = paper;
            } else {
                _boneResult = abstention;
            }
        } else if (_boneR < _boneS) {
            if (_boneS > _boneP) {
                _boneResult = scissors;
            } else if (_boneS < _boneP) {
                _boneResult = paper;
            } else {
                _boneResult = abstention;
            }
        } else {
            if (_boneR < _boneP) {
                _boneResult = paper;
            } else {
                _boneResult = abstention;
            }
        }

        // boneScore
        if (_boneResult == _result) {
            _boneScore = drawScore;
        } else if (_boneResult == _win) {
            _boneScore = winScore;
        } else {
            _boneScore = 0;
        }

        boneTotalScore += _boneScore;

        // sunsalResult 뽑는과정
        if (_sunsalR > _sunsalS) {
            if (_sunsalR > _sunsalP) {
                _sunsalResult = rock;
            } else if (_sunsalR < _sunsalP) {
                _sunsalResult = paper;
            } else {
                _sunsalResult = abstention;
            }
        } else if (_sunsalR < _sunsalS) {
            if (_sunsalS > _sunsalP) {
                _sunsalResult = scissors;
            } else if (_sunsalS < _sunsalP) {
                _sunsalResult = paper;
            } else {
                _sunsalResult = abstention;
            }
        } else {
            if (_sunsalR < _sunsalP) {
                _sunsalResult = paper;
            } else {
                _sunsalResult = abstention;
            }
        }

        // sunsalScore
        if (_sunsalResult == _result) {
            _sunsalScore = drawScore;
        } else if (_sunsalResult == _win) {
            _sunsalScore = winScore;
        } else {
            _sunsalScore = 0;
        }

        sunsalTotalScore += _sunsalScore;

        uint256 __chickenNum;
        // total 점수 넣기
        for (uint256 i = 0; i < _drawNum; i += 1) {
            __chickenNum = eachRSPList[gameRound][__result][i];
            eachScore[__chickenNum] += drawScore;
        }

        for (uint256 i = 0; i < _winNum; i += 1) {
            __chickenNum = eachRSPList[gameRound][__win][i];
            eachScore[__chickenNum] += winScore;
        }

        roundInfoArray.push(
            RoundInfo({
                boneScore: _boneScore,
                sunsalScore: _sunsalScore,
                result: __result,
                boneResult: _boneResult,
                sunsalResult: _sunsalResult
            })
        );

        gameRound += 1;
    }

    // 정보 받아오는 함수들

    // 현재 RSP 투표 정보 (return 뼈 묵찌빠 / 순살 묵찌빠)
    function getRSP(uint256 _round)
        public
        view
        returns (uint256[6] memory _rspNum)
    {
        uint256 _boneR = boneTotalBet[_round][rock];
        uint256 _boneS = boneTotalBet[_round][scissors];
        uint256 _boneP = boneTotalBet[_round][paper];
        uint256 _sunsalR = sunsalTotalBet[_round][rock];
        uint256 _sunsalS = sunsalTotalBet[_round][scissors];
        uint256 _sunsalP = sunsalTotalBet[_round][paper];

        _rspNum = [_boneR, _boneS, _boneP, _sunsalR, _sunsalS, _sunsalP];
        return _rspNum;
    }

    // 치킨 정보 (return 점수 / 참여)
    function getEachInfo(uint256 _chickenNum)
        public
        view
        returns (uint256 _score, uint256 _participate)
    {
        _score = eachScore[_chickenNum];
        _participate = eachParticipate[_chickenNum];
        return (_score, _participate);
    }

    function getAllInfo() public onlyOwner {
        uint256 _rankingGetNum = rankingGetNum;
        for (uint256 i = 0; i < 1000; i += 1) {
            uint256 _score = eachScore[i];
            rankingList[_rankingGetNum].push(_score);
        }

        rankingGetNum += 1;
    }

    function getBetList() public view returns (uint256[] memory) {
        uint256[] memory _betList = eachBetList[gameRound];
        return _betList;
    }

    function getRankingList() public view returns (uint256[] memory) {
        return rankingList[(rankingGetNum - 1)];
    }

    function getWinnerList(uint8 _round, uint8 _win)
        public
        view
        returns (uint256[] memory)
    {
        return eachRSPList[_round][_win];
    }
}

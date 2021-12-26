pragma solidity ^0.5.6;

import "./nft/KlayChicken.sol";
import "./nft/KlayChickenSunsal.sol";
import "./ownership/Ownable.sol";
import "./math/SafeMath.sol";

contract Swap is Ownable {
    using SafeMath for uint256;

    KlayChicken public chickenContract;
    KlayChickenSunsal public sunsalContract;

    bool public swapIsActive = true;
    uint256 public swapPrice = 0;
    uint256 public multiplier = 100000000000000000;
    uint256 public chickenNum = 0;
    uint256 public sunsalNum = 900;

    constructor(KlayChicken _chickenContract, KlayChickenSunsal _sunsalContract)
        public
    {
        chickenContract = _chickenContract;
        sunsalContract = _sunsalContract;
    }

    function setSwapState(bool newState) public onlyOwner {
        swapIsActive = newState;
    }

    function setSwapPrice(uint256 newPrice) public onlyOwner {
        swapPrice = newPrice;
    }

    function C2S(uint256 num) public payable {
        uint256 _swapPrice = swapPrice.mul(multiplier);
        require(swapIsActive, "swap is now unavailable");
        require(
            msg.sender == chickenContract.ownerOf(num),
            "this address is not owner"
        );
        require(msg.value >= _swapPrice, "Klay value is not correct");

        uint256 tokenNum = num;
        chickenContract.transferFrom(msg.sender, address(this), tokenNum);
        sunsalContract.transferFrom(address(this), msg.sender, tokenNum);
        chickenNum += 1;
        sunsalNum -= 1;
    }

    function S2C(uint256 num) public payable {
        uint256 _swapPrice = swapPrice.mul(multiplier);
        require(swapIsActive, "swap is now unavailable");
        require(
            msg.sender == sunsalContract.ownerOf(num),
            "this address is not owner"
        );
        require(msg.value >= _swapPrice, "Klay value is not correct");

        uint256 tokenNum = num;
        sunsalContract.transferFrom(msg.sender, address(this), tokenNum);
        chickenContract.transferFrom(address(this), msg.sender, tokenNum);
        sunsalNum += 1;
        chickenNum -= 1;
    }

    function massC2S(uint256[] memory numList) public payable {
        uint256 _swapPrice = swapPrice.mul(multiplier);
        require(swapIsActive, "swap is now unavailable");
        require(
            msg.value >= _swapPrice.mul(numList.length),
            "Klay value is not correct"
        );

        uint256[] memory tokenList = numList;
        uint256 listLength = tokenList.length;
        for (uint256 i = 0; i < listLength; i += 1) {
            if (chickenContract.ownerOf(tokenList[i]) == msg.sender) {
                chickenContract.transferFrom(
                    msg.sender,
                    address(this),
                    tokenList[i]
                );
                sunsalContract.transferFrom(
                    address(this),
                    msg.sender,
                    tokenList[i]
                );
            }
        }
        chickenNum += listLength;
        sunsalNum -= listLength;
    }

    function massS2C(uint256[] memory numList) public payable {
        uint256 _swapPrice = swapPrice.mul(multiplier);
        require(swapIsActive, "swap is now unavailable");
        require(
            msg.value >= _swapPrice.mul(numList.length),
            "Klay value is not correct"
        );

        uint256[] memory tokenList = numList;
        uint256 listLength = tokenList.length;
        for (uint256 i = 0; i < listLength; i += 1) {
            if (sunsalContract.ownerOf(tokenList[i]) == msg.sender) {
                sunsalContract.transferFrom(
                    msg.sender,
                    address(this),
                    tokenList[i]
                );
                chickenContract.transferFrom(
                    address(this),
                    msg.sender,
                    tokenList[i]
                );
            }
        }
        sunsalNum += listLength;
        chickenNum -= listLength;
    }

    function chickenWithdraw(uint256[] memory numList) public onlyOwner {
        uint256 listLength = numList.length;
        for (uint256 i = 0; i < listLength; i += 1) {
            chickenContract.transferFrom(address(this), msg.sender, numList[i]);
        }
    }

    function sunsalWithdraw(uint256[] memory numList) public onlyOwner {
        uint256 listLength = numList.length;
        for (uint256 i = 0; i < listLength; i += 1) {
            sunsalContract.transferFrom(address(this), msg.sender, numList[i]);
        }
    }

    function setCSNum(uint256 _chickenNum, uint256 _sunsalNum)
        public
        onlyOwner
    {
        chickenNum = _chickenNum;
        sunsalNum = _sunsalNum;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}

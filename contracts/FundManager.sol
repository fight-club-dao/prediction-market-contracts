// SPDX-License-Identifier: UNLICENSED

// This contract locks uniswap v2 liquidity tokens pairs with a betting parameter. the wining side will be able to claim the losing side liquidity tokens

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./interfaces/IPredictionMarketManager.sol";
import "./libraries/SharedStructs.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IHumaPool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FundManager is Ownable {
    using SafeMath for uint256;

    address public fundsToken;
    address public predictionMarket;
    IHumaPool public humaPool;

    constructor(address _fundsToken,IHumaPool _humaPool) public Ownable()  {
        fundsToken = _fundsToken;
        humaPool = _humaPool;
    }

    function setToken(address _fundsToken) external onlyOwner() {
        fundsToken = _fundsToken;
    }

    function setBorrower(address _predictionMarket) external onlyOwner() {
        predictionMarket = _predictionMarket;
    }

    function setHumaPool(IHumaPool _humaPool) external onlyOwner() {
        humaPool = _humaPool;
    }

    function drawDownFunds(uint256 _amount) public {
        humaPool.drawdown(_amount);
    }

    function paybackLoan(uint256 _amount) public {
        ERC20(fundsToken).approve(address (humaPool), _amount);
        humaPool.makePayment(address(this), _amount);
    }

    function borrowFunds(uint256 _amount) external {
        require(msg.sender == predictionMarket, "only prediction market can request funds");
        drawDownFunds(_amount);
        require(_amount <= ERC20(fundsToken).balanceOf(address(this)), "not enough funds");
        ERC20(fundsToken).transfer(msg.sender, _amount);
    }

    function returnFunds(uint256 _amount) external {
        require(msg.sender == predictionMarket, "only prediction market can return funds");
        ERC20(fundsToken).transferFrom(msg.sender, address(this),_amount);
        paybackLoan(_amount);
    }


}
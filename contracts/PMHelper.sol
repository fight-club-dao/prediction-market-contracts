// SPDX-License-Identifier: UNLICENSED

// This contract locks uniswap v2 liquidity tokens pairs with a betting parameter. the wining side will be able to claim the losing side liquidity tokens

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./interfaces/IPredictionMarketManager.sol";
import "./libraries/SharedStructs.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20BettingToken.sol";

contract PMHelper {
    using SafeMath for uint256;

    IPredictionMarketManager pmManager;

    constructor(IPredictionMarketManager _predictionMarketManager) public {
        pmManager = _predictionMarketManager;

    }

    /**
       * @notice get the current total prize for each team
   * @param _betId the id of the lock bet
   */
    function getCurrentTotalPrizes(uint256 _betId) public view returns (uint256, uint256) {
        uint256 totalPrizeA;
        uint256 totalPrizeB;
        SharedStructs.Match memory matchData = pmManager.getMatchData(_betId);

        address stableCoin = IUniswapV2Pair(matchData.player1.lpToken).token1();
        if(stableCoin == matchData.player1.token){
            stableCoin =  IUniswapV2Pair(matchData.player1.lpToken).token0();
        }

        if(matchData.matchResult == 0){

            totalPrizeA = IERC20BettingToken(stableCoin).balanceOf(matchData.player2.lpToken).sub(matchData.player2.initialStableAmount);
            totalPrizeB = IERC20BettingToken(stableCoin).balanceOf(matchData.player1.lpToken).sub(matchData.player1.initialStableAmount);

        }else if(matchData.matchResult == 1){
            totalPrizeA = IERC20BettingToken(stableCoin).balanceOf(matchData.player2.lpToken);
            totalPrizeB = 0;

        }else if(matchData.matchResult == 2){
            totalPrizeA = 0;
            totalPrizeB = IERC20BettingToken(stableCoin).balanceOf(matchData.player1.lpToken);

        }

        //remove fee
//        uint256 fee = 0;
//        uint256 feePercent = pmManager.feePercent();
//        if(feePercent > 0){
//            if(totalPrizeA > 0){
//                fee = totalPrizeA.mul(feePercent).div(10000);
//                totalPrizeA = totalPrizeA.sub(fee);
//            }
//            if(totalPrizeB > 0){
//                fee = totalPrizeB.mul(feePercent).div(10000);
//                totalPrizeB = totalPrizeB.sub(fee);
//            }
//        }

        return (totalPrizeA, totalPrizeB);

    }

    /**
       * @notice retruns stats of a match
   * @param _betId the id of the lock bet
   */
    function getStats(uint256 _betId) external view returns (SharedStructs.PlayerStats memory, SharedStructs.PlayerStats memory,uint256 result,string memory status) {
        SharedStructs.Match memory matchData = pmManager.getMatchData(_betId);
        require(matchData.player1.lpToken != address(0x0000000000000000000000000000000000000000),"match id is not exist");
        (uint256 prizeA,uint256 prizeB) = getCurrentTotalPrizes(_betId);
        SharedStructs.PlayerStats memory statsA;
        address pool = matchData.player1.lpToken;
        statsA.token = matchData.player1.token;
        statsA.pool = matchData.player1.lpToken;

        (statsA.amountToken0,statsA.amountToken1,statsA.timestampLast) = IUniswapV2Pair(pool).getReserves();

        uint256 tokenDecimals = IERC20BettingToken(statsA.token).decimals();
        address stableAddress;

        if(statsA.token == IUniswapV2Pair(pool).token0()){
            stableAddress = IUniswapV2Pair(pool).token1();
        }else{
            stableAddress = IUniswapV2Pair(pool).token0();
            uint256 amountStables = statsA.amountToken0;
            statsA.amountToken1 = statsA.amountToken0;
            statsA.amountToken0 = amountStables;
        }

        uint256 decimalsDiff = tokenDecimals.sub(IERC20BettingToken(stableAddress).decimals());
        uint256 amountStable = IERC20BettingToken(stableAddress).balanceOf(statsA.pool);
        uint256 amountToken = IERC20BettingToken(statsA.token).balanceOf(statsA.pool);
        uint256 amountStableAfterDecimals = amountStable.mul(10 ** decimalsDiff);
        statsA.price = amountStableAfterDecimals.mul(1000000000).div(amountToken);
        statsA.marketcap = statsA.price * IERC20BettingToken(statsA.token).totalSupply().div(1000000000);
        statsA.traded = !IERC20BettingToken(statsA.token).isPaused();
        statsA.tokenName = IERC20BettingToken(statsA.token).name();
        statsA.tokenSymbol = IERC20BettingToken(statsA.token).symbol();
        statsA.circulationSupply = IERC20BettingToken(statsA.token).totalSupply().sub(IERC20BettingToken(statsA.token).balanceOf(statsA.pool));
        statsA.liquidityAmount = IERC20BettingToken(stableAddress).balanceOf(statsA.pool).mul(2);

        if(statsA.circulationSupply > 0){
            statsA.prizePerUnit = prizeA.mul(1000000000).div(statsA.circulationSupply);
        }else{
            statsA.prizePerUnit = prizeA.mul(1000000000);
        }

        SharedStructs.PlayerStats memory statsB;
        pool = matchData.player2.lpToken;
        statsB.token = matchData.player2.token;
        statsB.pool = pool;
        (statsB.amountToken0,statsB.amountToken1,statsB.timestampLast) = IUniswapV2Pair(pool).getReserves();
        tokenDecimals = IERC20BettingToken(statsB.token).decimals();

        if(statsB.token == IUniswapV2Pair(statsB.pool).token0()){
            stableAddress = IUniswapV2Pair(statsB.pool).token1();
        }else{
            stableAddress = IUniswapV2Pair(statsB.pool).token0();
            uint256 amountStables = statsB.amountToken0;
            statsB.amountToken1 = statsB.amountToken0;
            statsB.amountToken0 = amountStables;
        }
        decimalsDiff = tokenDecimals.sub(IERC20BettingToken(stableAddress).decimals());
        amountStable = IERC20BettingToken(stableAddress).balanceOf(statsB.pool);
        amountToken = IERC20BettingToken(statsB.token).balanceOf(statsB.pool);
        amountStableAfterDecimals = amountStable.mul(10 ** decimalsDiff);
        statsB.price = amountStableAfterDecimals.mul(1000000000).div(amountToken);
        statsB.marketcap = statsB.price * IERC20BettingToken(statsB.token).totalSupply().div(1000000000);
        statsB.traded = !IERC20BettingToken(statsB.token).isPaused();
        statsB.tokenName = IERC20BettingToken(statsB.token).name();
        statsB.tokenSymbol = IERC20BettingToken(statsB.token).symbol();
        statsB.circulationSupply = IERC20BettingToken(statsB.token).totalSupply().sub(IERC20BettingToken(statsB.token).balanceOf(statsB.pool));
        statsB.liquidityAmount = IERC20BettingToken(stableAddress).balanceOf(statsB.pool).mul(2);

        if(statsB.circulationSupply > 0){
            statsB.prizePerUnit = prizeB.mul(1000000000).div(statsB.circulationSupply);
        }else{
            statsB.prizePerUnit = prizeB.mul(1000000000);
        }
        return(statsA, statsB, matchData.matchResult, matchData.status);
    }

}
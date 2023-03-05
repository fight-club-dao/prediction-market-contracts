// SPDX-License-Identifier: UNLICENSED

// This contract locks uniswap v2 liquidity tokens pairs with a betting parameter. the wining side will be able to claim the losing side liquidity tokens

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IERC20BettingToken.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IFunctionsConsumer.sol";
import "./interfaces/IUSDT.sol";
import "./libraries/SharedStructs.sol";
import "./interfaces/IFundManager.sol";
import "./BettingToken.sol";


interface IUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}


contract PredictionMarketManager is Ownable {
    using SafeMath for uint256;

    IUniFactory public uniswapFactory;
    IUniswapV2Router01 public uniswapV2Router;
    IFunctionsConsumer public functionsConsumer;
    IFundManager public fundManager;

    string constant BEFORE_START="BEFORE_START";
    string constant ON_GOING="ON_GOING";
    string constant ENDED="ENDED";

    uint256 public feePercent = 1000; // 1000 = 10%

    mapping(uint256 => SharedStructs.Match) public matches; //map univ2 pair to all its locks
    mapping(address => mapping(uint => bool)) claimedMapping;
    uint256 public matchCounter = 1;
    uint256 totalLockTime;

    constructor(
        IUniFactory _uniswapFactory,
        IUniswapV2Router01 _uniswapV2Router,
        IFunctionsConsumer _functionsConsumer,
        IFundManager _fundManager
    ) public {
        uniswapFactory = _uniswapFactory;
        uniswapV2Router = _uniswapV2Router;
        functionsConsumer = _functionsConsumer;
        fundManager = _fundManager;
        totalLockTime = block.timestamp + 60*60*24*90; //3 month total lock
    }

    function setFunctionConsumer(IFunctionsConsumer _functionsConsumer) external {
        functionsConsumer = _functionsConsumer;
    }
    function getMatchData(uint256 betId) public view returns(SharedStructs.Match memory){
        return matches[betId];
    }
    function setFeePercent(uint256 _percent) public onlyOwner {
        require(_percent < 10 && _percent > 5, "fee precent is not in the range");
        feePercent = _percent;
    }

    function _newMatch(address token1, address pair1, address token2, address pair2, uint256 initial_stable_amount) internal returns (uint256){
        SharedStructs.Match memory matchData;

        matchData.player1 = createPlayerStuct(pair1, address(token1),initial_stable_amount);
        matchData.player2 = createPlayerStuct(pair2, address(token2),initial_stable_amount);
        matchData.matchID = matchCounter;
        matchData.matchResult = 0;
        matchData.status = BEFORE_START;
        matches[matchCounter] = matchData;
        matchCounter = matchCounter + 1;

        return (matchCounter - 1);
    }
    function _deployTokenAndAddLiquidity(string memory token_name, string memory token_symbol,address stable_token,
        uint256 initial_stable_amount) internal returns (BettingToken, address){
        uint256 deadline = block.timestamp;
        //deploy
        BettingToken token = new BettingToken(token_name, token_symbol,address(this), address(uniswapV2Router),stable_token);
        //approve and provide liquidity
        IERC20(address(token)).approve(address(uniswapV2Router),token.balanceOf(address(this)));

        uniswapV2Router.addLiquidity(
            address(token),
            stable_token,
            token.balanceOf(address(this)),
            initial_stable_amount,
            token.balanceOf(address(this)),
            initial_stable_amount,
            address(this),
            deadline
        );

        address pair = uniswapFactory.getPair(address(token), address(stable_token));
        IERC20BettingToken(address(token)).setPoolAddress(pair);
        return(token, pair);

    }
    function _getFunds(address stable_token, uint256  _amount) internal {

        fundManager.borrowFunds(_amount);

        require(IERC20(stable_token).balanceOf(address(this)) >= _amount, "not enough funds");
    }
    function newMatch(
        string memory token1_name,
        string memory token1_symbol,
        string memory token2_name,
        string memory token2_symbol,
        address stable_token,
        uint256 initial_stable_amount
    ) external onlyOwner returns (uint256) { //todo add modifier
        //Take loan here

        IERC20(stable_token).approve(address(uniswapV2Router), initial_stable_amount.mul(2));

        _getFunds(stable_token, initial_stable_amount.mul(2));

        (BettingToken token1 ,address pair1)= _deployTokenAndAddLiquidity(token1_name, token1_symbol, stable_token, initial_stable_amount);
        (BettingToken token2 ,address pair2)= _deployTokenAndAddLiquidity(token2_name, token2_symbol, stable_token, initial_stable_amount);

        return _newMatch(address(token1), pair1, address(token2), pair2, initial_stable_amount);
    }

    function newMatchOneNewToken(
        BettingToken token1,
        address pair1,
        string memory token2_name,
        string memory token2_symbol,
        address stable_token,
        uint256 initial_stable_amount
    ) external onlyOwner returns (uint256){
        //Take loan here
        require(IERC20(stable_token).balanceOf(address(this)) >= initial_stable_amount.mul(2), "not enough funds. take a loan");

        IERC20(stable_token).approve(address(uniswapV2Router), initial_stable_amount.mul(2));

        (BettingToken token2 ,address pair2)= _deployTokenAndAddLiquidity(token2_name, token2_symbol, stable_token, initial_stable_amount);

        return _newMatch(address(token1), pair1, address(token2), pair2, initial_stable_amount);
    }

    function newMatchNoNewTokens(
        BettingToken token1,
        address pair1,
        BettingToken token2,
        address pair2,
        address stable_token,
        uint256 initial_stable_amount
    ) external onlyOwner returns (uint256){
        //Take loan here
        require(IERC20(stable_token).balanceOf(address(this)) >= initial_stable_amount.mul(2), "not enough funds. take a loan");

        IERC20(stable_token).approve(address(uniswapV2Router), initial_stable_amount.mul(2));

        return _newMatch(address(token1), pair1, address(token2), pair2, initial_stable_amount);
    }

    function createPlayerStuct(address pair, address token, uint256 initial_stable_amount) internal returns(SharedStructs.Player memory){
        SharedStructs.Player memory player;
        player.lpToken = pair;
        player.token = address(token);
        player.amountLp = ERC20(pair).balanceOf(address (this));
        player.initialStableAmount = initial_stable_amount;
        return player;
    }

    /**
     * @notice Claim the prize in LP if the user has won
   * @param _betId the id of the lock bet
   */
    function claim(uint256 _betId) external {
        require(!claimedMapping[msg.sender][_betId], "User already claimed");

        require(matches[_betId].matchResult != 0,"results was not announced yet");

        (address losingLpToken,uint256 share) = amountAbleToClaim(msg.sender,_betId, matches[_betId].matchResult);

        IERC20BettingToken(losingLpToken).transfer(msg.sender,share);
//        TransferHelper.safeTransfer(losingLpToken, msg.sender, share);
        claimedMapping[msg.sender][_betId] = true;

    }

    /**
     * @notice returns the lp amount the user is able to claim if a certain side was winning
   * @param user the user address
   * @param _betId the id of the lock bet
   * @param match_results the result of the match (1 for lpA, 2 for lpB)
   */
    function amountAbleToClaim(address user,uint256 _betId,uint256 match_results) public view returns(address, uint256){
        require(!claimedMapping[user][_betId], "User already claimed");
        SharedStructs.Match memory lock = matches[_betId];

        address winningToken;
        address losingLpToken;
        address winningLpToken;
        uint256 losingLpTokenAmount;
        uint256 winningSnapshotId;

        if(match_results == 1){
            winningToken = lock.player1.token;
            winningSnapshotId = lock.player1.snapshotId;
            losingLpToken = lock.player2.lpToken;
            winningLpToken = lock.player1.lpToken;
            losingLpTokenAmount = lock.player2.amountLp;
        }else if(match_results == 2){
            winningToken = lock.player2.token;
            winningSnapshotId = lock.player2.snapshotId;
            losingLpToken = lock.player1.lpToken;
            winningLpToken = lock.player2.lpToken;
            losingLpTokenAmount = lock.player1.amountLp;
        }
        require(losingLpTokenAmount > 0, "not enough liquidity locked in contract");

        uint256 winningTokenUserBalance = IERC20BettingToken(winningToken).balanceOfAt(msg.sender, winningSnapshotId);
        uint256 winningTokenTotalCirculationSupply = IERC20BettingToken(winningToken).totalSupplyAt(winningSnapshotId).sub(IERC20BettingToken(winningToken).balanceOfAt(winningLpToken, winningSnapshotId));
        uint256 amount = winningTokenUserBalance.mul(losingLpTokenAmount).div(winningTokenTotalCirculationSupply);

        return (losingLpToken, amount);
    }

    /**
     * @notice Claim the prize in LP and remove liquidity to get the 2 assets
   * @param _betId the id of the lock bet
   */
    function claimAndRemoveLiquidity(uint256 _betId, uint256 deadline) external {

        require(!claimedMapping[msg.sender][_betId], "User already claimed");

        SharedStructs.Match memory matchData = matches[_betId];
        require(matchData.matchResult != 0);

        (address losingLpToken,uint256 share) = amountAbleToClaim(msg.sender,_betId, matchData.matchResult);

        IERC20BettingToken(losingLpToken).approve(address(uniswapV2Router), share);

        if(deadline == 0){
            deadline = block.timestamp + 60*2;
        }

        IUniswapV2Router01(uniswapV2Router).removeLiquidity(
            IUniswapV2Pair(losingLpToken).token0(),
            IUniswapV2Pair(losingLpToken).token1(),
            share,
            0,
            0,
            msg.sender,
            deadline
        );
        claimedMapping[msg.sender][_betId] = true;

    }

    /**
     * @notice start the match
   * @param _betId the id of the lock bet
   */
    function startMatch(uint256 _betId) external onlyOwner{
        SharedStructs.Match storage matchData = matches[_betId];
        matchData.status = ON_GOING;

        IERC20BettingToken(matchData.player1.token).pause();
        IERC20BettingToken(matchData.player2.token).pause();
    }

    /**
    * @notice announce result
   * @param _betId the id of the lock bet
   */
    function matchEnded(uint256 _betId) external onlyOwner {
        uint256 result = functionsConsumer.getMatchResults(_betId);
        require(result == 1 || result == 2,"result value can only be 1 or 2");
        _matchEnded(_betId, result, true);

    }

    function _matchEnded(uint256 _betId, uint256 result,bool removeInitial) internal {
        SharedStructs.Match storage lock = matches[_betId];

        _takeSnapshot(_betId);

        lock.matchResult = result;
        matches[_betId] = lock;

        address winningToken;
        address losingLPtoken;
        address losingToken;
        uint256 initial;
        if(lock.matchResult == 1){
            winningToken = lock.player1.token;
            losingLPtoken = lock.player2.lpToken;
            losingToken = lock.player2.token;
            initial = lock.player2.initialStableAmount;
        }else if(lock.matchResult == 2){
            winningToken = lock.player2.token;
            losingLPtoken = lock.player1.lpToken;
            losingToken = lock.player1.token;
            initial = lock.player1.initialStableAmount;
        }

        IERC20BettingToken(winningToken).unpause();
        IERC20BettingToken(losingToken).unpauseExceptSelling();

        //remove intial liquidity.
        address stableToken = IUniswapV2Pair(losingLPtoken).token1();
        if(stableToken == losingToken){
            stableToken =  IUniswapV2Pair(losingLPtoken).token0();
        }

        uint256 totalInPool = IERC20BettingToken(stableToken).balanceOf(losingLPtoken);
        uint256 losingLPtokenAmount = IERC20BettingToken(losingLPtoken).balanceOf(address(this));

        uint256 initialAmountToRemove = initial.mul(100000).div(totalInPool).mul(losingLPtokenAmount).div(100000);


        uint256 feeToAmountToClaim = 0;

        if(feePercent > 0){
            if(losingLPtokenAmount > initialAmountToRemove){
                feeToAmountToClaim = losingLPtokenAmount.sub(initialAmountToRemove).mul(feePercent).div(10000);

            }
        }


        uint256 amountToRemove = initialAmountToRemove.add(feeToAmountToClaim);

        if(amountToRemove > losingLPtokenAmount){
            amountToRemove = losingLPtokenAmount;
        }
        if(removeInitial){
            IERC20BettingToken(losingLPtoken).approve(address(uniswapV2Router), amountToRemove);

            (uint256 amount0, uint256 amount1) = IUniswapV2Router01(uniswapV2Router).removeLiquidity(
                IUniswapV2Pair(losingLPtoken).token0(),
                IUniswapV2Pair(losingLPtoken).token1(),
                amountToRemove,
                0,
                0,
                address(this),
                block.timestamp + 60*10
            );

            uint256 removedAmount;
            if(IUniswapV2Pair(losingLPtoken).token0() == stableToken){
                removedAmount = amount0;
            }else{
                removedAmount = amount1;
            }

            //return funds to fundManager
            IERC20(stableToken).approve(address(fundManager), removedAmount);
            fundManager.returnFunds(removedAmount);

        }else{
            IERC20BettingToken(losingToken).transfer(owner(),amountToRemove);
        }

        lock.player1.amountLp = IERC20BettingToken(lock.player1.lpToken).balanceOf(address(this));
        lock.player2.amountLp = IERC20BettingToken(lock.player2.lpToken).balanceOf(address(this));
        lock.status = ENDED;

    }

    function _takeSnapshot(uint256 _betId) internal{
        SharedStructs.Match memory matchData = matches[_betId];
        matches[_betId].player1.snapshotId = IERC20BettingToken(matchData.player1.token).snapshot();
        matches[_betId].player2.snapshotId = IERC20BettingToken(matchData.player2.token).snapshot();
    }


    function withdrawLockedLP(uint256 _betId) external onlyOwner {
        SharedStructs.Match memory matchData = matches[_betId];
        IERC20BettingToken(matchData.player1.lpToken).transfer(owner(), IERC20BettingToken(matchData.player1.lpToken).balanceOf(address(this)));
        IERC20BettingToken(matchData.player2.lpToken).transfer(owner(), IERC20BettingToken(matchData.player2.lpToken).balanceOf(address(this)));
    }

    function withdrawToken(address token, uint256 amount) external onlyOwner {
        require(totalLockTime < block.timestamp, 'NOT YET');
        IERC20BettingToken(token).transfer(owner(), amount);
    }

    /**
     * @notice returns a bool if user already claimed a specific bet id
   * @param _betId the id of the lock bet
   */
    function isUserClaimed(uint256 _betId,address user) external view returns (bool) {
        return(claimedMapping[msg.sender][_betId]);
    }




}
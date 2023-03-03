// SPDX-License-Identifier: UNLICENSED

// This contract locks uniswap v2 liquidity tokens pairs with a betting parameter. the wining side will be able to claim the losing side liquidity tokens

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

//import "./TransferHelper.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IERC20BettingToken.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IFunctionsConsumer.sol";
import "./interfaces/IUSDT.sol";
import "./libraries/SharedStructs.sol";
import "./BettingToken.sol";

interface IUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IUSDTapprover {
    function approve(address spender, uint256 amount) external;
}

contract PredictionMarketManager is Ownable {
    using SafeMath for uint256;

    IUniFactory public uniswapFactory;
    IUniswapV2Router01 public uniswapV2Router;
    IFunctionsConsumer public functionsConsumer;

    string constant BEFORE_START="BEFORE_START";
    string constant ON_GOING="ON_GOING";
    string constant ENDED="ENDED";

    uint256 public feePercent = 1000; // 1000 = 10%

    mapping(uint256 => SharedStructs.Match) public matches; //map univ2 pair to all its locks
    mapping(address => mapping(uint => bool)) claimedMapping;
    uint256 matchCounter = 1;
    uint256 totalLockTime;

    constructor(
        IUniFactory _uniswapFactory,
        IUniswapV2Router01 _uniswapV2Router,
        IFunctionsConsumer _functionsConsumer
    ) public {
        uniswapFactory = _uniswapFactory;
        uniswapV2Router = _uniswapV2Router;
        functionsConsumer = _functionsConsumer;
        totalLockTime = block.timestamp + 60*60*24*30; //1 month total lock
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
        matchData.lockID = matchCounter;
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
    function newMatch(
        string memory token1_name,
        string memory token1_symbol,
        string memory token2_name,
        string memory token2_symbol,
        address stable_token,
        uint256 initial_stable_amount
    ) external returns (uint256){ //todo add modifier
        //Take loan here
        require(IERC20(stable_token).balanceOf(address(this)) >= initial_stable_amount.mul(2), "not enough funds. take a loan");

        IUSDTapprover(stable_token).approve(address(uniswapV2Router), initial_stable_amount.mul(2));

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
    ) external returns (uint256){
        //Take loan here
        require(IERC20(stable_token).balanceOf(address(this)) >= initial_stable_amount.mul(2), "not enough funds. take a loan");

        IUSDTapprover(stable_token).approve(address(uniswapV2Router), initial_stable_amount.mul(2));

        (BettingToken token2 ,address pair2)= _deployTokenAndAddLiquidity(token2_name, token2_symbol, stable_token, initial_stable_amount);

        return _newMatch(address(token1), pair1, address(token2), pair2, initial_stable_amount);
    }
//
    function newMatchNoNewTokens(
        BettingToken token1,
        address pair1,
        BettingToken token2,
        address pair2,
        address stable_token,
        uint256 initial_stable_amount
    ) external returns (uint256){
        //Take loan here
        require(IERC20(stable_token).balanceOf(address(this)) >= initial_stable_amount.mul(2), "not enough funds. take a loan");

        IUSDTapprover(stable_token).approve(address(uniswapV2Router), initial_stable_amount.mul(2));

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

//    /**
//     * @notice Creates a new lock with a bet between lp's
//   * @param _lpTokenA the univ2 token address
//   * @param _tokenA the univ2 token address
//   * @param _amountA amount of LP tokens to lock
//   * @param _lpTokenB the univ2 token address
//   * @param _tokenB the univ2 token address
//   * @param _amountB amount of LP tokens to lock
//   * @param _unlock_date the unix timestamp (in seconds) until unlock
//   * @param intialLiquidity the stable token amount that was added to the pools when initialized
//   */
//    function lockLPTokenWithBet(
//        address _lpTokenA,
//        address _tokenA,
//        uint256 _amountA,
//        address _lpTokenB,
//        address _tokenB,
//        uint256 _amountB,
//        uint256 _unlock_date,
//        uint256 intialLiquidity
//    ) external nonReentrant returns (uint256) {
//        require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
//        require(_amountA > 0, 'INSUFFICIENT');
//        require(_amountB > 0, 'INSUFFICIENT');
//
//        // ensure this pair is a univ2 pair by querying the factory
//        IUniswapV2Pair lpairA = IUniswapV2Pair(address(_lpTokenA));
//        address factoryPairAddressA = uniswapFactory.getPair(lpairA.token0(), lpairA.token1());
//        require(factoryPairAddressA == address(_lpTokenA), 'NOT UNIV2');
//
//        // ensure this pair is a univ2 pair by querying the factory
//        IUniswapV2Pair lpairB = IUniswapV2Pair(address(_lpTokenB));
//        address factoryPairAddressB = uniswapFactory.getPair(lpairB.token0(), lpairB.token1());
//        require(factoryPairAddressB == address(_lpTokenB), 'NOT UNIV2');
//
//        if(IERC20BettingToken(_lpTokenA).balanceOf(address(msg.sender)) == _amountA){
//            IERC20BettingToken(_lpTokenA).transferFrom(address(msg.sender), address(this), _amountA);
//        }
//        if(IERC20BettingToken(_lpTokenB).balanceOf(address(msg.sender)) == _amountB){
//            IERC20BettingToken(_lpTokenB).transferFrom(address(msg.sender), address(this), _amountB);
//        }
//
//        SharedStructs.BetLock memory bet_lock;
//        SharedStructs.Player memory playerA;
//        playerA.lpToken = _lpTokenA;
//        playerA.token = _tokenA;
//        playerA.amountLp = _amountA;
//        playerA.initialStableAmount = intialLiquidity;
//        SharedStructs.Player memory playerB;
//        playerB.lpToken = _lpTokenB;
//        playerB.token = _tokenB;
//        playerB.amountLp = _amountB;
//        playerB.initialStableAmount = intialLiquidity;
//        bet_lock.playerA = playerA;
//        bet_lock.playerB = playerB;
//        bet_lock.unlockDate = _unlock_date;
//        bet_lock.lockID = betLockCounter;
//        bet_lock.result = 0;
//        bet_lock.status = BEFORE_START;
//        betLocks[betLockCounter] = bet_lock;
//        betLockCounter = betLockCounter + 1;
//        //set pool address
//        IERC20BettingToken(_tokenA).setPoolAddress(bet_lock.playerA.lpToken);
//        IERC20BettingToken(_tokenB).setPoolAddress(bet_lock.playerB.lpToken);
//        return (betLockCounter - 1);
//    }

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

//    /**
//     * @notice Claim the prize in LP and remove liquidity to get the 2 assets
//   * @param _betId the id of the lock bet
//   */
//    function claimAndRemoveLiquidity(uint256 _betId, uint256 deadline) external nonReentrant {
//
//        require(!claimedMapping[msg.sender][_betId], "User already claimed");
//
//        BetLock memory lock = betLocks[_betId];
//        require(lock.result != 0);
//
//        (address losingLpToken,uint256 share) = amountAbleToClaim(msg.sender,_betId, lock.result);
//
//        IERC20u(losingLpToken).approve(address(uniswapV2Router), share);
//
//        if(deadline == 0){
//            deadline = block.timestamp + 60*2;
//        }
//
//        IUniswapV2Router01(uniswapV2Router).removeLiquidity(
//            IUniswapV2Pair(losingLpToken).token0(),
//            IUniswapV2Pair(losingLpToken).token1(),
//            share,
//            0,
//            0,
//            msg.sender,
//            deadline
//        );
//        claimedMapping[msg.sender][_betId] = true;
//
//    }

    /**
     * @notice start the match
   * @param _betId the id of the lock bet
   */
    function startMatch(uint256 _betId) external onlyOwner{
        SharedStructs.Match storage lock = matches[_betId];
        lock.status = ON_GOING;

        IERC20BettingToken(lock.player1.token).pause();
        IERC20BettingToken(lock.player2.token).pause();
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
//    /**
//     * @notice announce result
//   * @param _betId the id of the lock bet
//   * @param result the match results
//   */
//    function announceResult(uint256 _betId, uint256 result,bool removeInitial) external onlyOwner {
//        startMatchEndedProccess(_betId, result, removeInitial);
//    }
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

            IUniswapV2Router01(uniswapV2Router).removeLiquidity(
                IUniswapV2Pair(losingLPtoken).token0(),
                IUniswapV2Pair(losingLPtoken).token1(),
                amountToRemove,
                0,
                0,
                owner(),
                block.timestamp + 60*10
            );

        }else{
            IERC20BettingToken(losingToken).transfer(owner(),amountToRemove);
        }

        lock.player1.amountLp = IERC20BettingToken(lock.player1.lpToken).balanceOf(address(this));
        lock.player2.amountLp = IERC20BettingToken(lock.player2.lpToken).balanceOf(address(this));
        lock.status = ENDED;

    }

    function _takeSnapshot(uint256 _betId) internal{
        SharedStructs.Match memory lock = matches[_betId];
        matches[_betId].player1.snapshotId = IERC20BettingToken(lock.player1.token).snapshot();
        matches[_betId].player2.snapshotId = IERC20BettingToken(lock.player2.token).snapshot();
    }


    function withdrawLockedLP(uint256 _betId) external onlyOwner {
        SharedStructs.Match memory lock = matches[_betId];
        IERC20BettingToken(lock.player1.lpToken).transfer(owner(), IERC20BettingToken(lock.player1.lpToken).balanceOf(address(this)));
        IERC20BettingToken(lock.player2.lpToken).transfer(owner(), IERC20BettingToken(lock.player2.lpToken).balanceOf(address(this)));
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

//    function getLpAmountAbleToClaim(uint256 _betId,uint8 result, uint256 winningTokenAmount) external view returns (uint256) {
//        BetLock memory lock = betLocks[_betId];
//
//        address winningToken;
//        address losingLpToken;
//        uint256 losingLpTokenAmount;
//
//        if(result == 1){
//            winningToken = lock.teamA.token;
//            losingLpToken = lock.teamB.lpToken;
//        }else if(result == 2){
//            winningToken = lock.teamB.token;
//            losingLpToken = lock.teamA.lpToken;
//        }
//        losingLpTokenAmount = IERC20u(losingLpToken).balanceOf(address(this));
//
//        uint256 winningTokenTotalSupply = IERC20u(winningToken).totalSupply();
//        uint256 share = winningTokenAmount.mul(losingLpTokenAmount).div(winningTokenTotalSupply);
//
//        return share;
//    }

//    /**
//       * @notice get the current total prize for each team
//   * @param _betId the id of the lock bet
//   */
//    function getCurrentTotalPrizes(uint256 _betId) public view returns (uint256, uint256) {
//        uint256 totalPrizeA;
//        uint256 totalPrizeB;
//        BetLock memory lock = betLocks[_betId];
//
//        address stableCoin = IUniswapV2Pair(lock.teamA.lpToken).token1();
//        if(stableCoin == lock.teamA.token){
//            stableCoin =  IUniswapV2Pair(lock.teamA.lpToken).token0();
//        }
//
//        if(lock.result == 0){
//            totalPrizeA = IERC20u(stableCoin).balanceOf(lock.teamB.lpToken).sub(lock.teamB.initialStableAmount);
//            totalPrizeB = IERC20u(stableCoin).balanceOf(lock.teamA.lpToken).sub(lock.teamA.initialStableAmount);
//
//        }else if(lock.result == 1){
//            totalPrizeA = IERC20u(stableCoin).balanceOf(lock.teamB.lpToken);
//            totalPrizeB = 0;
//
//        }else if(lock.result == 2){
//            totalPrizeA = 0;
//            totalPrizeB = IERC20u(stableCoin).balanceOf(lock.teamA.lpToken);
//        }
//
//        //remove fee
//        uint256 fee = 0;
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
//
//        return (totalPrizeA, totalPrizeB);
//    }

//    /**
//       * @notice retruns stats of a match
//   * @param _betId the id of the lock bet
//   */
//    function getStats(uint256 _betId) external view returns (TeamStats memory,TeamStats memory,uint256 result,string memory status) {
//        BetLock memory lock = betLocks[_betId];
//        require(lock.teamA.lpToken != address(0x0000000000000000000000000000000000000000),"lock id is not exist");
//        (uint256 prizeA,uint256 prizeB) = getCurrentTotalPrizes(_betId);
//        TeamStats memory statsA;
//        address pool = lock.teamA.lpToken;
//        statsA.token = lock.teamA.token;
//        statsA.pool = lock.teamA.lpToken;
//
//        (statsA.amountToken0,statsA.amountToken1,statsA.timestampLast) = IUniswapV2Pair(pool).getReserves();
//
//        uint256 tokenDecimals = IERC20u(statsA.token).decimals();
//        address stableAddress;
//
//        if(statsA.token == IUniswapV2Pair(pool).token0()){
//            stableAddress = IUniswapV2Pair(pool).token1();
//        }else{
//            stableAddress = IUniswapV2Pair(pool).token0();
//            uint256 amountStables = statsA.amountToken0;
//            statsA.amountToken1 = statsA.amountToken0;
//            statsA.amountToken0 = amountStables;
//        }
//
//        uint256 decimalsDiff = tokenDecimals.sub(IERC20u(stableAddress).decimals());
//        uint256 amountStable = IERC20u(stableAddress).balanceOf(statsA.pool);
//        uint256 amountToken = IERC20u(statsA.token).balanceOf(statsA.pool);
//        uint256 amountStableAfterDecimals = amountStable.mul(10 ** decimalsDiff);
//        statsA.price = amountStableAfterDecimals.mul(1000000000).div(amountToken);
//        statsA.marketcap = statsA.price * IERC20u(statsA.token).totalSupply().div(1000000000);
//        statsA.traded = !IERC20u(statsA.token).isPaused();
//        statsA.tokenName = IERC20u(statsA.token).name();
//        statsA.tokenSymbol = IERC20u(statsA.token).symbol();
//        statsA.circulationSupply = IERC20u(statsA.token).totalSupply().sub(IERC20u(statsA.token).balanceOf(statsA.pool));
//        statsA.liquidityAmount = IERC20u(stableAddress).balanceOf(statsA.pool).mul(2);
//
//        if(statsA.circulationSupply > 0){
//            statsA.prizePerUnit = prizeA.mul(1000000000).div(statsA.circulationSupply);
//        }else{
//            statsA.prizePerUnit = prizeA.mul(1000000000);
//        }
//
//        TeamStats memory statsB;
//        pool = lock.teamB.lpToken;
//        statsB.token = lock.teamB.token;
//        statsB.pool = pool;
//        (statsB.amountToken0,statsB.amountToken1,statsB.timestampLast) = IUniswapV2Pair(pool).getReserves();
//        tokenDecimals = IERC20u(statsB.token).decimals();
//
//        if(statsB.token == IUniswapV2Pair(statsB.pool).token0()){
//            stableAddress = IUniswapV2Pair(statsB.pool).token1();
//        }else{
//            stableAddress = IUniswapV2Pair(statsB.pool).token0();
//            uint256 amountStables = statsB.amountToken0;
//            statsB.amountToken1 = statsB.amountToken0;
//            statsB.amountToken0 = amountStables;
//        }
//        decimalsDiff = tokenDecimals.sub(IERC20u(stableAddress).decimals());
//        amountStable = IERC20u(stableAddress).balanceOf(statsB.pool);
//        amountToken = IERC20u(statsB.token).balanceOf(statsB.pool);
//        amountStableAfterDecimals = amountStable.mul(10 ** decimalsDiff);
//        statsB.price = amountStableAfterDecimals.mul(1000000000).div(amountToken);
//        statsB.marketcap = statsB.price * IERC20u(statsB.token).totalSupply().div(1000000000);
//        statsB.traded = !IERC20u(statsB.token).isPaused();
//        statsB.tokenName = IERC20u(statsB.token).name();
//        statsB.tokenSymbol = IERC20u(statsB.token).symbol();
//        statsB.circulationSupply = IERC20u(statsB.token).totalSupply().sub(IERC20u(statsB.token).balanceOf(statsB.pool));
//        statsB.liquidityAmount = IERC20u(stableAddress).balanceOf(statsB.pool).mul(2);
//
//        if(statsB.circulationSupply > 0){
//            statsB.prizePerUnit = prizeB.mul(1000000000).div(statsB.circulationSupply);
//        }else{
//            statsB.prizePerUnit = prizeB.mul(1000000000);
//        }
//        return(statsA, statsB, lock.result, lock.status);
//    }

}
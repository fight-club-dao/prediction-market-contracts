pragma solidity 0.8.17;

library SharedStructs {
    struct Match {
        uint256 startDate; // the date the token was deployed
        Player player1;
        Player player2;
        string status;
        uint256 matchID; // lockID nonce per uni pair
        address owner;
        uint256 matchResult;
    }

    struct PlayerStats {
        address token;
        address pool;
        string tokenName;
        string tokenSymbol;
        uint256 price;
        uint256 amountToken0;
        uint256 amountToken1;
        uint32 timestampLast;
        uint256 marketcap;
        uint256 liquidityAmount;
        uint256 prizePerUnit;
        uint256 circulationSupply;
        bool traded;
    }

    struct Player {
        address lpToken;
        address token;
        uint256 amountLp;
        uint256 initialStableAmount;
        uint256 snapshotId;
    }
}

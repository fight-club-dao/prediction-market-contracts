import "../libraries/SharedStructs.sol";

interface IPredictionMarketManager{

    function getMatchData(uint256 betId) external view returns(SharedStructs.Match memory);
    function feePercent() external view returns(uint256);
}

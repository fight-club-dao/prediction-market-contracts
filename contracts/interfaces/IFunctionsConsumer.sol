interface IFunctionsConsumer {
    function getMatchResults(uint256 _matchId) external returns(uint256);
    function requestMatchResults(string[] calldata args) external view returns (bytes32);
}
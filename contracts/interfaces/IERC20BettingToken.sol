interface IERC20BettingToken {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
    function decimals() external view returns (uint);
    function snapshot() external returns(uint256);
    function unpause() external;
    function pause() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function unpauseExceptSelling() external;
    function setPoolAddress(address pool) external;
    function isPaused() external view returns(bool);
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
}
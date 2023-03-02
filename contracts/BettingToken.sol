// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Factory.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
}

/// @notice Mock ERC20 contract for testing purposes
contract BettingToken is ERC20Snapshot,Pausable, Ownable {

    address private _manager;
    address private _pool;
    bool private _pauseExceptSelling = false;

    constructor(
        string memory name,
        string memory symbol,
        address manager,
        address uniswapRouter,
        address stableToken
    ) public payable ERC20(name, symbol) Ownable() {
        _mint(msg.sender, 1000000000000000000000000); //mint 1 million tokens
        _manager = manager;

    }

    /**
     * @dev Returns the address of the current owner.
     */
    function manager() public view returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        require(_manager == _msgSender(), "caller is not the manager");
        _;
    }

    function setManager(address manager) external onlyManager{
        _manager = manager;
    }

    function snapshot() external  onlyManager returns(uint256){
        uint256 snapshotId = _snapshot();
        return snapshotId;
    }

    function setPoolAddress(address pool) external onlyManager {
        _pool = pool;
    }

    function pause() external  onlyManager{
        _pause();
    }

    function unpause() external  onlyManager{
        _unpause();
    }

    function unpauseExceptSelling() external  onlyManager{
        _unpause();
        _pauseExceptSelling = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
        if(_pauseExceptSelling){
            require(from == _pool,"can only transfer from pool");
        }

    }

    function isPaused() external view returns(bool){
        return paused() || _pauseExceptSelling;
    }


}
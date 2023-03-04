// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Mock ERC20 contract for testing purposes
contract MockToken is ERC20, Ownable {

    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public payable ERC20(name, symbol) Ownable() {
        _decimals = decimals;
        _mint(msg.sender, 1000000000000000); //mint 1 million tokens
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {

        require(allowance(account, _msgSender()) - amount >=0,"ERC20: burn amount exceeds allowance");
        uint256 decreasedAllowance = allowance(account, _msgSender()) - amount;

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}
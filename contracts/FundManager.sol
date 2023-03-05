// SPDX-License-Identifier: UNLICENSED

// This contract locks uniswap v2 liquidity tokens pairs with a betting parameter. the wining side will be able to claim the losing side liquidity tokens

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./interfaces/IPredictionMarketManager.sol";
import "./libraries/SharedStructs.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IHumaPool.sol";
import "./interfaces/circle/ITokenMessanger.sol";
import "./interfaces/circle/IMessageTransmitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FundManager is Ownable {
    using SafeMath for uint256;

    address public fundsToken;
    address public predictionMarket;
    IHumaPool public humaPool;
    ITokenMessanger public tokenMessanger;
    IMessageTransmitter public messageTransmitter;
    uint32 AVAX_DESTINATION_DOMAIN = 1;
    mapping(uint256 => address) chainToFundManager;
    bool isMainChain = false;
    address usdc;
    constructor(
        address _fundsToken,
        IHumaPool _humaPool,
        ITokenMessanger _tokenMessanger,
        IMessageTransmitter _messageTransmitter,
        address _usdc,
        bool _isMainChain
    ) public Ownable()  {
        fundsToken = _fundsToken;
        humaPool = _humaPool;
        tokenMessanger = _tokenMessanger;
        messageTransmitter = _messageTransmitter;
        isMainChain = _isMainChain;
        usdc = _usdc;
    }

    function addFundManagerToMapping(uint256 _chainId, address fundManager) external{
    chainToFundManager[_chainId] = fundManager;
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
        if(isMainChain){
            drawDownFunds(_amount);
        }
        require(_amount <= ERC20(fundsToken).balanceOf(address(this)), "not enough funds");
        ERC20(fundsToken).transfer(msg.sender, _amount);
    }

    function returnFunds(uint256 _amount) external {
        require(msg.sender == predictionMarket, "only prediction market can return funds");
        ERC20(fundsToken).transferFrom(msg.sender, address(this),_amount);
        if(isMainChain){
            paybackLoan(_amount);
        }

    }

    function portUSDCtoOtherChain(address recipient, uint256 amount, uint256 chainId) external {
        IERC20(usdc).transferFrom(msg.sender,address(this),amount);
        IERC20(usdc).approve(address(tokenMessanger),amount);
        address recipient = chainToFundManager[chainId];
        tokenMessanger.depositForBurn(amount, AVAX_DESTINATION_DOMAIN, bytes32(uint256(uint160(recipient))), usdc);
    }

    function recieveUDCMessage(bytes calldata message, bytes calldata attestation) external {
       messageTransmitter.receiveMessage(message, attestation);
    }

}
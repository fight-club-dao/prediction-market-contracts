interface IHumaPool {
    function drawdown(uint256 borrowAmount) external virtual;
    function makePayment(address borrower, uint256 amount) external virtual returns (uint256 amountPaid, bool paidoff);
}

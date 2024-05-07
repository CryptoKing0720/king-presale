// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPreSale {
    error Unauthorized();

    error InvalidState(uint8 currentState);

    error SoftCapNotReached();

    error HardCapExceed();

    error NotClaimable();

    error NotInPurchasePeriod();

    error PurchaseBelowMinimum();

    error PurchaseLimitExceed();

    error NotRefundable();

    error LiquificationFailed();

    error InvalidInitializationParameters();

    error InvalidCapValue();

    error InvalidLimitValue();

    error InvalidLiquidityValue();

    error InvalidTimestampValue();

    event Deposit(address indexed creator, uint256 amount, uint256 timestamp);

    event Purchase(address indexed beneficiary, uint256 contribution);

    event Finalized(address indexed creator, uint256 amount, uint256 timestamp);

    event Refund(
        address indexed beneficiary,
        uint256 amount,
        uint256 timestamp
    );

    event TokenClaim(
        address indexed beneficiary,
        uint256 amount,
        uint256 timestamp
    );

    event Cancel(address indexed creator, uint256 timestamp);

    function deposit() external returns (uint256);

    function finalize() external returns (bool);

    function cancel() external returns (bool);

    function claim() external returns (uint256);

    function refund() external returns (uint256);
}

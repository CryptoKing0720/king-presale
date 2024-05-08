// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IPancakeRouter02} from "./pancake-exchange/interfaces/IPancakeRouter02.sol";
import {IPreSale} from "./interfaces/IPreSale.sol";

contract PreSale is IPreSale, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 constant SCALE = 10 ** 18;

    /**
     * @notice PreSale options
     * @param tokenDeposit Total tokens deposited for sale and liquidity.
     * @param hardCap Maximum Wei to be raised.
     * @param softCap Minimum Wei to be raised to consider the presale successful.
     * @param max Maximum Wei contribution per address.
     * @param min Minimum Wei contribution per address.
     * @param start Start timestamp of the presale.
     * @param end End timestamp of the presale.
     * @param liquidityBps Basis points of funds raised to be allocated to liquidity.
     */
    struct PreSaleOptions {
        uint256 tokenDeposit;
        uint256 hardCap;
        uint256 softCap;
        uint256 max;
        uint256 min;
        uint112 start;
        uint112 end;
        uint32 liquidityBps;
    }

    /**
     * @notice PreSale pool
     * @param token Address of the token.
     * @param pancakeRouter02
     * @param tokenBalance Token balance in this contract
     * @param tokensClaimable
     * @param tokensLiquidity
     * @param weiRaised
     * @param weth
     * @param state Current state of the presale {1: Initialized, 2: Active, 3: Canceled, 4: Finalized}.
     * @param options PreSaleOptions struct containing configuration for the presale.
     */
    struct Pool {
        IERC20 token;
        IPancakeRouter02 pancakeRouter02;
        uint256 tokenBalance;
        uint256 tokensClaimable;
        uint256 tokensLiquidity;
        uint256 weiRaised;
        address weth;
        uint8 state;
        PreSaleOptions options;
    }

    mapping(address => uint256) public contributions;

    Pool public pool;

    modifier onlyRefundable() {
        if (
            pool.state != 3 ||
            !(block.timestamp > pool.options.end &&
                pool.weiRaised < pool.options.softCap)
        ) revert NotRefundable();
        _;
    }

    constructor(
        address _weth,
        address _token,
        address pancakeRouter02,
        PreSaleOptions memory _options
    ) Ownable(msg.sender) {
        _prevalidatePool(_options);

        pool.pancakeRouter02 = IPancakeRouter02(pancakeRouter02);
        pool.token = IERC20(_token);
        pool.state = 1;
        pool.weth = _weth;
        pool.options = _options;
    }

    receive() external payable {
        _purchase(msg.sender, msg.value);
    }

    function deposit() external onlyOwner returns (uint256) {
        if (pool.state != 1) revert InvalidState(pool.state);
        pool.state = 2;

        pool.tokenBalance += pool.options.tokenDeposit;
        pool.tokensLiquidity = _tokensForLiquidity();
        pool.tokensClaimable = _tokensForPreSale();

        pool.token.approve(address(pool.pancakeRouter02), pool.tokenBalance);

        IERC20(pool.token).safeTransferFrom(
            msg.sender,
            address(this),
            pool.options.tokenDeposit
        );

        emit Deposit(msg.sender, pool.options.tokenDeposit, block.timestamp);
        return pool.options.tokenDeposit;
    }

    function finalize() external onlyOwner returns (bool) {
        if (pool.state != 2) revert InvalidState(pool.state);
        if (
            pool.weiRaised < pool.options.softCap &&
            block.timestamp < pool.options.end
        ) revert SoftCapNotReached();

        pool.state = 4;
        uint256 liquidityWei = _weiForLiquidity();
        _liquify(liquidityWei, pool.tokensLiquidity);
        pool.tokenBalance -= pool.tokensLiquidity;

        uint256 withdrawable = pool.weiRaised - liquidityWei;
        if (withdrawable > 0)
            Address.sendValue(payable(msg.sender), withdrawable);

        emit Finalized(msg.sender, pool.weiRaised, block.timestamp);

        return true;
    }

    function claim() external returns (uint256) {
        if (pool.state != 4) revert InvalidState(pool.state);
        if (contributions[msg.sender] == 0) revert NotClaimable();

        uint256 amount = userTokens(msg.sender);
        pool.tokenBalance -= amount;
        contributions[msg.sender] = 0;

        IERC20(pool.token).safeTransfer(msg.sender, amount);
        emit TokenClaim(msg.sender, amount, block.timestamp);
        return amount;
    }

    function cancel() external onlyOwner returns (bool) {
        if (pool.state > 3) revert InvalidState(pool.state);

        pool.state = 3;

        if (pool.tokenBalance > 0) {
            uint256 amount = pool.tokenBalance;
            pool.tokenBalance = 0;
            IERC20(pool.token).safeTransfer(msg.sender, amount);
        }

        emit Cancel(msg.sender, block.timestamp);
        return true;
    }

    function refund() external onlyRefundable returns (uint256) {
        if (contributions[msg.sender] == 0) revert NotRefundable();

        uint256 amount = contributions[msg.sender];

        if (address(this).balance >= amount) {
            contributions[msg.sender] = 0;
            Address.sendValue(payable(msg.sender), amount);
            emit Refund(msg.sender, amount, block.timestamp);
        }

        return amount;
    }

    function _purchase(address beneficiary, uint256 amount) private {
        _prevalidatePurchase(beneficiary, amount);
        pool.weiRaised += amount;
        contributions[beneficiary] += amount;

        emit Purchase(beneficiary, amount);
    }

    function _liquify(uint256 _weiAmount, uint256 _tokenAmount) private {
        (uint amountToken, uint amountETH, ) = pool
            .pancakeRouter02
            .addLiquidityETH{value: _weiAmount}(
            address(pool.token),
            _tokenAmount,
            _tokenAmount,
            _weiAmount,
            owner(),
            block.timestamp + 600
        );

        if (amountToken != _tokenAmount && amountETH != _weiAmount)
            revert LiquificationFailed();
    }

    function _prevalidatePurchase(
        address _beneficiary,
        uint256 _amount
    ) internal view returns (bool) {
        if (pool.state != 2) revert InvalidState(pool.state);

        if (
            block.timestamp < pool.options.start ||
            block.timestamp > pool.options.end
        ) revert NotInPurchasePeriod();

        if (pool.weiRaised + _amount > pool.options.hardCap)
            revert HardCapExceed();

        if (_amount < pool.options.min) revert PurchaseBelowMinimum();

        if (_amount + contributions[_beneficiary] > pool.options.max)
            revert PurchaseLimitExceed();

        return true;
    }

    function _prevalidatePool(
        PreSaleOptions memory _options
    ) internal view returns (bool) {
        if (_options.softCap == 0 || _options.softCap < _options.hardCap / 2)
            revert InvalidCapValue();
        if (_options.min == 0 || _options.min > _options.max)
            revert InvalidLimitValue();
        if (_options.liquidityBps < 5000 || _options.liquidityBps > 10000)
            revert InvalidLiquidityValue();
        if (_options.start > block.timestamp || _options.end < _options.start)
            revert InvalidTimestampValue();
        return true;
    }

    function userTokens(address contributor) public view returns (uint256) {
        return
            (((contributions[contributor] * SCALE) / pool.weiRaised) *
                pool.tokensClaimable) / SCALE;
    }

    function _tokensForLiquidity() internal view returns (uint256) {
        return (pool.options.tokenDeposit * pool.options.liquidityBps) / 10_000;
    }

    function _tokensForPreSale() internal view returns (uint256) {
        return pool.options.tokenDeposit - _tokensForLiquidity();
    }

    function _weiForLiquidity() internal view returns (uint256) {
        return (pool.weiRaised * pool.options.liquidityBps) / 10_000;
    }
}

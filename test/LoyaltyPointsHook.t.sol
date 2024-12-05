// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {PoolManager} from "v4-core/PoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";

import "forge-std/console.sol";

import {LoyaltyPointsHook} from "src/LoyaltyPointsHook.sol";

contract LoyaltyPointsHookTest is Test, Deployers {
    using CurrencyLibrary for Currency;

    MockERC20 token;

    // two currency
    Currency ethCurrency = Currency.wrap(address(0));
    Currency tokenCurrency;

    LoyaltyPointsHook hook;

    function setUp() public {
        // Deploy v4 core contracts
        deployFreshManagerAndRouters();

        // deploy TOKEN contract
        token = new MockERC20("Test Token", "TEST", 18);
        tokenCurrency = Currency.wrap(address(token));

        // mint some TOKEN to ourselves
        token.mint(address(this), 1000 ether);
        token.mint(address(1), 1000 * 10 ** 18);

        // deploy the hook
        uint160 flags = uint160(
            Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        address hookAddress = address(flags);
        deployCodeTo(
            "LoyaltyPointsHook",
            abi.encode(manager, "Point Token", "TEST_POINTS"),
            hookAddress
        );

        hook = LoyaltyPointsHook(hookAddress);

        token.approve(address(swapRouter), type(uint256).max);
        token.approve(address(modifyLiquidityRouter), type(uint256).max);

        // initialize the pools with tokens
        (key, ) = initPool(
            ethCurrency, // eth
            tokenCurrency, // TOKEN
            hook, // loyalty points hook
            3000, // swap fees
            SQRT_PRICE_1_1 // Initial Sqrt(P) value = 1
        );
    }

    function test_afterAddLiquidityp() public {
        uint256 pointsBalanceOriginal = hook.balanceOf(address(this));

        bytes memory hookData = abi.encode(address(this));

        uint160 sqrtPriceAtTickLower = TickMath.getSqrtPriceAtTick(-60);
        uint160 sqrtPriceAtTickupper = TickMath.getSqrtPriceAtTick(60);

        uint256 ethToAdd = 0.1 ether;

        uint128 liquidityDelta = LiquidityAmounts.getLiquidityForAmount0(
            sqrtPriceAtTickLower,
            SQRT_PRICE_1_1,
            ethToAdd
        );
        uint256 tokensToAdd = LiquidityAmounts.getAmount1ForLiquidity(
            sqrtPriceAtTickLower,
            SQRT_PRICE_1_1,
            liquidityDelta
        );

        modifyLiquidityRouter.modifyLiquidity{value: ethToAdd}(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: int256(uint256(liquidityDelta)),
                salt: bytes32(0)
            }),
            hookData
        );

        uint256 pointsBalanceAfterAddliqudity = hook.balanceOf(address(this));

        assertApproxEqAbs(
            pointsBalanceAfterAddliqudity - pointsBalanceOriginal,
            0.1 ether,
            0.001 ether // error margin
        );
    }

    function test_afterSwap() public {
        uint256 pointsBalanceOriginal = hook.balanceOf(address(this));

        bytes memory hookData = abi.encode(address(this));

        uint160 sqrtPriceAtTickLower = TickMath.getSqrtPriceAtTick(-60);
        uint160 sqrtPriceAtTickupper = TickMath.getSqrtPriceAtTick(60);

        uint256 ethToAdd = 0.1 ether;

        uint128 liquidityDelta = LiquidityAmounts.getLiquidityForAmount0(
            sqrtPriceAtTickLower,
            SQRT_PRICE_1_1,
            ethToAdd
        );
        uint256 tokensToAdd = LiquidityAmounts.getAmount1ForLiquidity(
            sqrtPriceAtTickLower,
            SQRT_PRICE_1_1,
            liquidityDelta
        );

        modifyLiquidityRouter.modifyLiquidity{value: ethToAdd}(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: int256(uint256(liquidityDelta)),
                salt: bytes32(0)
            }),
            hookData
        );

        uint256 pointsBalanceAfterAddliqudity = hook.balanceOf(address(this));

        assertApproxEqAbs(
            pointsBalanceAfterAddliqudity - pointsBalanceOriginal,
            0.1 ether,
            0.001 ether // error margin
        );

        swapRouter.swap{value: 0.1 ether}(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -0.001 ether,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            hookData
        );

        uint256 pointsBalanceAfterSwap = hook.balanceOf(address(this));

        assertEq(
            pointsBalanceAfterSwap - pointsBalanceAfterAddliqudity,
            2 * 10 ** 14
        );
    }
}

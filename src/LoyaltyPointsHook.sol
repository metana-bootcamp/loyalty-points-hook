// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";

import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

import {PoolId} from "v4-core/types/PoolId.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {PoolKey} from "v4-core/types/PoolKey.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";

import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

contract LoyaltyPointsHook is BaseHook, ERC20 {
    using CurrencyLibrary for Currency;

    constructor(
        IPoolManager _manager,
        string memory _name,
        string memory _symbol
    ) BaseHook(_manager) ERC20(_name, _symbol) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4, int128) {
        if (!key.currency0.isAddressZero()) {
            return (this.afterSwap.selector, 0);
        }

        uint256 ethSpent = uint256(int256(-delta.amount0()));
        uint256 pointsForSwap = ethSpent / 5;

        _assigningLoyaltyPoints(hookData, pointsForSwap);

        return (this.afterSwap.selector, 0);
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta delta,
        BalanceDelta,
        bytes calldata hookData
    ) external override returns (bytes4, BalanceDelta) {
        if (!key.currency0.isAddressZero()) {
            return (this.afterSwap.selector, delta);
        }

        uint256 pointsForAddingLiquidity = uint256(int256(-delta.amount0()));

        _assigningLoyaltyPoints(hookData, pointsForAddingLiquidity);

        return (this.afterAddLiquidity.selector, delta);
    }

    function _assigningLoyaltyPoints(
        bytes memory hookdata,
        uint256 points
    ) internal {
        if (hookdata.length == 0) return;

        address user = abi.decode(hookdata, (address));

        if (user == address(0)) return;

        _mint(user, points);
    }
}

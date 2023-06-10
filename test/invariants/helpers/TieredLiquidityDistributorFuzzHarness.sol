// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/console2.sol";

import { TieredLiquidityDistributor, Tier } from "src/abstract/TieredLiquidityDistributor.sol";

contract TieredLiquidityDistributorFuzzHarness is TieredLiquidityDistributor {

    uint256 public totalAdded;
    uint256 public totalConsumed;

    constructor () TieredLiquidityDistributor(10, 2, 100, 10, 10) {}

    function nextDraw(uint8 _nextNumTiers, uint96 liquidity, uint16 nextDrawId) external {
        uint8 nextNumTiers = _nextNumTiers / 16; // map to [0, 15]
        nextNumTiers = nextNumTiers < 2 ? 2 : nextNumTiers; // ensure min tiers
        totalAdded += liquidity;
        if(nextDrawId <= lastCompletedDrawId) nextDrawId = lastCompletedDrawId + 1; // ensure always moving forward
        if(nextDrawId > type(uint16).max / 2) nextDrawId = lastCompletedDrawId + 1; // ensure we don't exhaust our draw runway
        _nextDraw(nextNumTiers, liquidity, nextDrawId);
    }

    function net() external view returns (uint256) {
        return totalAdded - totalConsumed;
    }

    function accountedLiquidity() external view returns (uint256) {
        uint256 availableLiquidity;
        for (uint8 i = 0; i <= numberOfTiers; i++) {
            Tier memory tier = _getTier(i, numberOfTiers);
            uint256 tierLiquidity = _remainingTierLiquidity(tier, _computeShares(i, numberOfTiers));
            // console2.log("tier ", i);
            // console2.log("tier liquidity", tierLiquidity);
            availableLiquidity += tierLiquidity;
        }
        // console2.log("reserve ", _reserve);
        availableLiquidity += _reserve;
        // console2.log("SUM", availableLiquidity);
        return availableLiquidity;
    }

    function consumeLiquidity(uint8 _tier) external {
        uint8 tier = _tier % numberOfTiers;
        tier = tier < 2 ? 2 : tier;

        Tier memory tier_ = _getTier(tier, numberOfTiers);
        uint8 shares = _computeShares(tier, numberOfTiers);
        uint112 liq = _remainingTierLiquidity(tier_, shares);

        // console2.log("tier ", tier);
        // console2.log("remaining ", liq);

        if (_tier > 128) {
            liq += _reserve / 2;
        }

        // console2.log("liq ", liq);

        totalConsumed += liq;
        tier_ = _consumeLiquidity(tier_, tier, shares, uint104(liq));
    }

}

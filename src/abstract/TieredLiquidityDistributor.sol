// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import { console2 } from "forge-std/console2.sol";
import { console } from "forge-std/console.sol";

import { E, SD59x18, sd, toSD59x18, fromSD59x18 } from "prb-math/SD59x18.sol";
import { UD60x18, ud, toUD60x18, fromUD60x18, intoSD59x18 } from "prb-math/UD60x18.sol";
import { UD2x18, intoUD60x18 } from "prb-math/UD2x18.sol";
import { SD1x18, unwrap, UNIT } from "prb-math/SD1x18.sol";

import { UD34x4, fromUD60x18 as fromUD60x18toUD34x4, intoUD60x18 as fromUD34x4toUD60x18, toUD34x4 } from "../libraries/UD34x4.sol";
import { TierCalculationLib } from "../libraries/TierCalculationLib.sol";

/// @notice Struct that tracks tier liquidity information.
struct Tier {
  uint16 drawId;
  uint96 prizeSize;
  UD34x4 prizeTokenPerShare;
}

/// @notice Emitted when the number of tiers is less than the minimum number of tiers.
/// @param numTiers The invalid number of tiers
error NumberOfTiersLessThanMinimum(uint8 numTiers);

/// @notice Emitted when there is insufficient liquidity to consume.
/// @param requestedLiquidity The requested amount of liquidity
error InsufficientLiquidity(uint104 requestedLiquidity);

/// @title Tiered Liquidity Distributor
/// @author PoolTogether Inc.
/// @notice A contract that distributes liquidity according to PoolTogether V5 distribution rules.
contract TieredLiquidityDistributor {
  uint8 internal constant MINIMUM_NUMBER_OF_TIERS = 3;

  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_2_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_3_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_4_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_5_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_6_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_7_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_8_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_9_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_10_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_11_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_12_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_13_TIERS;
  UD60x18 internal immutable CANARY_PRIZE_COUNT_FOR_14_TIERS;

  //////////////////////// START GENERATED CONSTANTS ////////////////////////
  // The following constants are precomputed using the script/generateConstants.s.sol script.

  /// @notice The number of draws that should statistically occur between grand prizes.
  uint16 internal constant GRAND_PRIZE_PERIOD_DRAWS = 365;

  /// @notice The estimated number of prizes given X tiers.
  function e2() external pure returns (uint256) {
    return 4;
  }

  function e3() external pure returns (uint256) {
    return 16;
  }

  function e4() external pure returns (uint256) {
    return 66;
  }

  function e5() external pure returns (uint256) {
    return 270;
  }

  function e6() external pure returns (uint256) {
    return 1108;
  }

  function e7() external pure returns (uint256) {
    return 4517;
  }

  function e8() external pure returns (uint256) {
    return 18358;
  }

  function e9() external pure returns (uint256) {
    return 74435;
  }

  function e10() external pure returns (uint256) {
    return 301239;
  }

  function e11() external pure returns (uint256) {
    return 1217266;
  }

  function e12() external pure returns (uint256) {
    return 4912619;
  }

  function e13() external pure returns (uint256) {
    return 19805536;
  }

  function e14() external pure returns (uint256) {
    return 79777187;
  }

  /// @notice The odds for each tier and number of tiers pair.
  function t03() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t13() external pure returns (uint256) {
    return 52342392259021369;
  }

  function t23() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t04() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t14() external pure returns (uint256) {
    return 19579642462506911;
  }

  function t24() external pure returns (uint256) {
    return 139927275620255366;
  }

  function t34() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t05() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t15() external pure returns (uint256) {
    return 11975133168707466;
  }

  function t25() external pure returns (uint256) {
    return 52342392259021369;
  }

  function t35() external pure returns (uint256) {
    return 228784597949733865;
  }

  function t45() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t06() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t16() external pure returns (uint256) {
    return 8915910667410451;
  }

  function t26() external pure returns (uint256) {
    return 29015114005673871;
  }

  function t36() external pure returns (uint256) {
    return 94424100034951094;
  }

  function t46() external pure returns (uint256) {
    return 307285046878222004;
  }

  function t56() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t07() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t17() external pure returns (uint256) {
    return 7324128348251604;
  }

  function t27() external pure returns (uint256) {
    return 19579642462506911;
  }

  function t37() external pure returns (uint256) {
    return 52342392259021369;
  }

  function t47() external pure returns (uint256) {
    return 139927275620255366;
  }

  function t57() external pure returns (uint256) {
    return 374068544013333694;
  }

  function t67() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t08() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t18() external pure returns (uint256) {
    return 6364275529026907;
  }

  function t28() external pure returns (uint256) {
    return 14783961098420314;
  }

  function t38() external pure returns (uint256) {
    return 34342558671878193;
  }

  function t48() external pure returns (uint256) {
    return 79776409602255901;
  }

  function t58() external pure returns (uint256) {
    return 185317453770221528;
  }

  function t68() external pure returns (uint256) {
    return 430485137687959592;
  }

  function t78() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t09() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t19() external pure returns (uint256) {
    return 5727877794074876;
  }

  function t29() external pure returns (uint256) {
    return 11975133168707466;
  }

  function t39() external pure returns (uint256) {
    return 25036116265717087;
  }

  function t49() external pure returns (uint256) {
    return 52342392259021369;
  }

  function t59() external pure returns (uint256) {
    return 109430951602859902;
  }

  function t69() external pure returns (uint256) {
    return 228784597949733865;
  }

  function t79() external pure returns (uint256) {
    return 478314329651259628;
  }

  function t89() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t010() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t110() external pure returns (uint256) {
    return 5277233889074595;
  }

  function t210() external pure returns (uint256) {
    return 10164957094799045;
  }

  function t310() external pure returns (uint256) {
    return 19579642462506911;
  }

  function t410() external pure returns (uint256) {
    return 37714118749773489;
  }

  function t510() external pure returns (uint256) {
    return 72644572330454226;
  }

  function t610() external pure returns (uint256) {
    return 139927275620255366;
  }

  function t710() external pure returns (uint256) {
    return 269526570731818992;
  }

  function t810() external pure returns (uint256) {
    return 519159484871285957;
  }

  function t910() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t011() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t111() external pure returns (uint256) {
    return 4942383282734483;
  }

  function t211() external pure returns (uint256) {
    return 8915910667410451;
  }

  function t311() external pure returns (uint256) {
    return 16084034459031666;
  }

  function t411() external pure returns (uint256) {
    return 29015114005673871;
  }

  function t511() external pure returns (uint256) {
    return 52342392259021369;
  }

  function t611() external pure returns (uint256) {
    return 94424100034951094;
  }

  function t711() external pure returns (uint256) {
    return 170338234127496669;
  }

  function t811() external pure returns (uint256) {
    return 307285046878222004;
  }

  function t911() external pure returns (uint256) {
    return 554332974734700411;
  }

  function t1011() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t012() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t112() external pure returns (uint256) {
    return 4684280039134314;
  }

  function t212() external pure returns (uint256) {
    return 8009005012036743;
  }

  function t312() external pure returns (uint256) {
    return 13693494143591795;
  }

  function t412() external pure returns (uint256) {
    return 23412618868232833;
  }

  function t512() external pure returns (uint256) {
    return 40030011078337707;
  }

  function t612() external pure returns (uint256) {
    return 68441800379112721;
  }

  function t712() external pure returns (uint256) {
    return 117019204165776974;
  }

  function t812() external pure returns (uint256) {
    return 200075013628233217;
  }

  function t912() external pure returns (uint256) {
    return 342080698323914461;
  }

  function t1012() external pure returns (uint256) {
    return 584876652230121477;
  }

  function t1112() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t013() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t113() external pure returns (uint256) {
    return 4479520628784180;
  }

  function t213() external pure returns (uint256) {
    return 7324128348251604;
  }

  function t313() external pure returns (uint256) {
    return 11975133168707466;
  }

  function t413() external pure returns (uint256) {
    return 19579642462506911;
  }

  function t513() external pure returns (uint256) {
    return 32013205494981721;
  }

  function t613() external pure returns (uint256) {
    return 52342392259021369;
  }

  function t713() external pure returns (uint256) {
    return 85581121447732876;
  }

  function t813() external pure returns (uint256) {
    return 139927275620255366;
  }

  function t913() external pure returns (uint256) {
    return 228784597949733866;
  }

  function t1013() external pure returns (uint256) {
    return 374068544013333694;
  }

  function t1113() external pure returns (uint256) {
    return 611611432212751966;
  }

  function t1213() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t014() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t114() external pure returns (uint256) {
    return 4313269422986724;
  }

  function t214() external pure returns (uint256) {
    return 6790566987074365;
  }

  function t314() external pure returns (uint256) {
    return 10690683906783196;
  }

  function t414() external pure returns (uint256) {
    return 16830807002169641;
  }

  function t514() external pure returns (uint256) {
    return 26497468900426949;
  }

  function t614() external pure returns (uint256) {
    return 41716113674084931;
  }

  function t714() external pure returns (uint256) {
    return 65675485708038160;
  }

  function t814() external pure returns (uint256) {
    return 103395763485663166;
  }

  function t914() external pure returns (uint256) {
    return 162780431564813557;
  }

  function t1014() external pure returns (uint256) {
    return 256272288217119098;
  }

  function t1114() external pure returns (uint256) {
    return 403460570024895441;
  }

  function t1214() external pure returns (uint256) {
    return 635185461125249183;
  }

  function t1314() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t015() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t115() external pure returns (uint256) {
    return 4175688124417637;
  }

  function t215() external pure returns (uint256) {
    return 6364275529026907;
  }

  function t315() external pure returns (uint256) {
    return 9699958857683993;
  }

  function t415() external pure returns (uint256) {
    return 14783961098420314;
  }

  function t515() external pure returns (uint256) {
    return 22532621938542004;
  }

  function t615() external pure returns (uint256) {
    return 34342558671878193;
  }

  function t715() external pure returns (uint256) {
    return 52342392259021369;
  }

  function t815() external pure returns (uint256) {
    return 79776409602255901;
  }

  function t915() external pure returns (uint256) {
    return 121589313257458259;
  }

  function t1015() external pure returns (uint256) {
    return 185317453770221528;
  }

  function t1115() external pure returns (uint256) {
    return 282447180198804430;
  }

  function t1215() external pure returns (uint256) {
    return 430485137687959592;
  }

  function t1315() external pure returns (uint256) {
    return 656113662171395111;
  }

  function t1415() external pure returns (uint256) {
    return 1000000000000000000;
  }

  function t016() external pure returns (uint256) {
    return 2739726027397260;
  }

  function t116() external pure returns (uint256) {
    return 4060005854625059;
  }

  function t216() external pure returns (uint256) {
    return 6016531351950262;
  }

  function t316() external pure returns (uint256) {
    return 8915910667410451;
  }

  function t416() external pure returns (uint256) {
    return 13212507070785166;
  }

  function t516() external pure returns (uint256) {
    return 19579642462506911;
  }

  function t616() external pure returns (uint256) {
    return 29015114005673871;
  }

  function t716() external pure returns (uint256) {
    return 42997559448512061;
  }

  function t816() external pure returns (uint256) {
    return 63718175229875027;
  }

  function t916() external pure returns (uint256) {
    return 94424100034951094;
  }

  function t1016() external pure returns (uint256) {
    return 139927275620255366;
  }

  function t1116() external pure returns (uint256) {
    return 207358528757589475;
  }

  function t1216() external pure returns (uint256) {
    return 307285046878222004;
  }

  function t1316() external pure returns (uint256) {
    return 455366367617975795;
  }

  function t1416() external pure returns (uint256) {
    return 674808393262840052;
  }

  function t1516() external pure returns (uint256) {
    return 1000000000000000000;
  }

  //////////////////////// END GENERATED CONSTANTS ////////////////////////

  /// @notice The Tier liquidity data.
  mapping(uint8 => Tier) internal _tiers;

  /// @notice The number of shares to allocate to each prize tier.
  uint8 public immutable tierShares;

  /// @notice The number of shares to allocate to the canary tier.
  uint8 public immutable canaryShares;

  /// @notice The number of shares to allocate to the reserve.
  uint8 public immutable reserveShares;

  /// @notice The current number of prize tokens per share.
  UD34x4 public prizeTokenPerShare;

  /// @notice The number of tiers for the last closed draw. The last tier is the canary tier.
  uint8 public numberOfTiers;

  /// @notice The draw id of the last closed draw.
  uint16 internal lastClosedDrawId;

  /// @notice The amount of available reserve.
  uint104 internal _reserve;

  /**
   * @notice Constructs a new Prize Pool.
   * @param _numberOfTiers The number of tiers to start with. Must be greater than or equal to the minimum number of tiers.
   * @param _tierShares The number of shares to allocate to each tier
   * @param _canaryShares The number of shares to allocate to the canary tier.
   * @param _reserveShares The number of shares to allocate to the reserve.
   */
  constructor(uint8 _numberOfTiers, uint8 _tierShares, uint8 _canaryShares, uint8 _reserveShares) {
    numberOfTiers = _numberOfTiers;
    tierShares = _tierShares;
    canaryShares = _canaryShares;
    reserveShares = _reserveShares;

    CANARY_PRIZE_COUNT_FOR_2_TIERS = TierCalculationLib.canaryPrizeCount(
      2,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_3_TIERS = TierCalculationLib.canaryPrizeCount(
      3,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_4_TIERS = TierCalculationLib.canaryPrizeCount(
      4,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_5_TIERS = TierCalculationLib.canaryPrizeCount(
      5,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_6_TIERS = TierCalculationLib.canaryPrizeCount(
      6,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_7_TIERS = TierCalculationLib.canaryPrizeCount(
      7,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_8_TIERS = TierCalculationLib.canaryPrizeCount(
      8,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_9_TIERS = TierCalculationLib.canaryPrizeCount(
      9,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_10_TIERS = TierCalculationLib.canaryPrizeCount(
      10,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_11_TIERS = TierCalculationLib.canaryPrizeCount(
      11,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_12_TIERS = TierCalculationLib.canaryPrizeCount(
      12,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_13_TIERS = TierCalculationLib.canaryPrizeCount(
      13,
      _canaryShares,
      _reserveShares,
      _tierShares
    );
    CANARY_PRIZE_COUNT_FOR_14_TIERS = TierCalculationLib.canaryPrizeCount(
      14,
      _canaryShares,
      _reserveShares,
      _tierShares
    );

    if (_numberOfTiers < MINIMUM_NUMBER_OF_TIERS) {
      revert NumberOfTiersLessThanMinimum(_numberOfTiers);
    }
  }

  /// @notice Adjusts the number of tiers and distributes new liquidity.
  /// @param _nextNumberOfTiers The new number of tiers. Must be greater than minimum
  /// @param _prizeTokenLiquidity The amount of fresh liquidity to distribute across the tiers and reserve
  function _nextDraw(uint8 _nextNumberOfTiers, uint96 _prizeTokenLiquidity) internal {
    if (_nextNumberOfTiers < MINIMUM_NUMBER_OF_TIERS) {
      revert NumberOfTiersLessThanMinimum(_nextNumberOfTiers);
    }

    uint8 numTiers = numberOfTiers;
    UD60x18 _prizeTokenPerShare = fromUD34x4toUD60x18(prizeTokenPerShare);
    (
      uint16 closedDrawId,
      uint104 newReserve,
      UD60x18 newPrizeTokenPerShare
    ) = _computeNewDistributions(
        numTiers,
        _nextNumberOfTiers,
        _prizeTokenPerShare,
        _prizeTokenLiquidity
      );

    // need to redistribute to the canary tier and any new tiers (if expanding)
    uint8 start;
    uint8 end;
    // if we are expanding, need to reset the canary tier and all of the new tiers
    if (_nextNumberOfTiers > numTiers) {
      start = numTiers - 1;
      end = _nextNumberOfTiers;
    } else {
      // just reset the canary tier
      start = _nextNumberOfTiers - 1;
      end = _nextNumberOfTiers;
    }
    for (uint8 i = start; i < end; i++) {
      _tiers[i] = Tier({
        drawId: closedDrawId,
        prizeTokenPerShare: prizeTokenPerShare,
        prizeSize: uint96(
          _computePrizeSize(i, _nextNumberOfTiers, _prizeTokenPerShare, newPrizeTokenPerShare)
        )
      });
    }

    prizeTokenPerShare = fromUD60x18toUD34x4(newPrizeTokenPerShare);
    numberOfTiers = _nextNumberOfTiers;
    lastClosedDrawId = closedDrawId;
    _reserve += newReserve;
  }

  /// @notice Computes the liquidity that will be distributed for the next draw given the next number of tiers and prize liquidity.
  /// @param _numberOfTiers The current number of tiers
  /// @param _nextNumberOfTiers The next number of tiers to use to compute distribution
  /// @param _prizeTokenLiquidity The amount of fresh liquidity to distribute across the tiers and reserve
  /// @return closedDrawId The drawId that this is for
  /// @return newReserve The amount of liquidity that will be added to the reserve
  /// @return newPrizeTokenPerShare The new prize token per share
  function _computeNewDistributions(
    uint8 _numberOfTiers,
    uint8 _nextNumberOfTiers,
    uint256 _prizeTokenLiquidity
  ) internal view returns (uint16 closedDrawId, uint104 newReserve, UD60x18 newPrizeTokenPerShare) {
    return
      _computeNewDistributions(
        _numberOfTiers,
        _nextNumberOfTiers,
        fromUD34x4toUD60x18(prizeTokenPerShare),
        _prizeTokenLiquidity
      );
  }

  /// @notice Computes the liquidity that will be distributed for the next draw given the next number of tiers and prize liquidity.
  /// @param _numberOfTiers The current number of tiers
  /// @param _nextNumberOfTiers The next number of tiers to use to compute distribution
  /// @param _currentPrizeTokenPerShare The current prize token per share
  /// @param _prizeTokenLiquidity The amount of fresh liquidity to distribute across the tiers and reserve
  /// @return closedDrawId The drawId that this is for
  /// @return newReserve The amount of liquidity that will be added to the reserve
  /// @return newPrizeTokenPerShare The new prize token per share
  function _computeNewDistributions(
    uint8 _numberOfTiers,
    uint8 _nextNumberOfTiers,
    UD60x18 _currentPrizeTokenPerShare,
    uint _prizeTokenLiquidity
  ) internal view returns (uint16 closedDrawId, uint104 newReserve, UD60x18 newPrizeTokenPerShare) {
    closedDrawId = lastClosedDrawId + 1;
    uint256 totalShares = _getTotalShares(_nextNumberOfTiers);
    UD60x18 deltaPrizeTokensPerShare = (toUD60x18(_prizeTokenLiquidity).div(toUD60x18(totalShares)))
      .floor();

    newPrizeTokenPerShare = _currentPrizeTokenPerShare.add(deltaPrizeTokensPerShare);

    uint reclaimed = _getTierLiquidityToReclaim(
      _numberOfTiers,
      _nextNumberOfTiers,
      _currentPrizeTokenPerShare
    );
    uint computedLiquidity = fromUD60x18(deltaPrizeTokensPerShare.mul(toUD60x18(totalShares)));
    uint remainder = (_prizeTokenLiquidity - computedLiquidity);

    newReserve = uint104(
      fromUD60x18(deltaPrizeTokensPerShare.mul(toUD60x18(reserveShares))) + // reserve portion
        reclaimed + // reclaimed liquidity from tiers
        remainder // remainder
    );
  }

  /// @notice Returns the prize size for the given tier.
  /// @param _tier The tier to retrieve
  /// @return The prize size for the tier
  function getTierPrizeSize(uint8 _tier) external view returns (uint96) {
    return _getTier(_tier, numberOfTiers).prizeSize;
  }

  /// @notice Returns the estimated number of prizes for the given tier.
  /// @param _tier The tier to retrieve
  /// @return The estimated number of prizes
  function getTierPrizeCount(uint8 _tier) external view returns (uint32) {
    return _getTierPrizeCount(_tier, numberOfTiers);
  }

  /// @notice Returns the estimated number of prizes for the given tier and number of tiers.
  /// @param _tier The tier to retrieve
  /// @param _numberOfTiers The number of tiers, should match the current number of tiers
  /// @return The estimated number of prizes
  function getTierPrizeCount(uint8 _tier, uint8 _numberOfTiers) external view returns (uint32) {
    return _getTierPrizeCount(_tier, _numberOfTiers);
  }

  /// @notice Returns the number of available prizes for the given tier.
  /// @param _tier The tier to retrieve
  /// @param _numberOfTiers The number of tiers, should match the current number of tiers
  /// @return The number of available prizes
  function _getTierPrizeCount(uint8 _tier, uint8 _numberOfTiers) internal view returns (uint32) {
    return
      _isCanaryTier(_tier, _numberOfTiers)
        ? _canaryPrizeCount(_numberOfTiers)
        : uint32(TierCalculationLib.prizeCount(_tier));
  }

  /// @notice Retrieves an up-to-date Tier struct for the given tier.
  /// @param _tier The tier to retrieve
  /// @param _numberOfTiers The number of tiers, should match the current. Passed explicitly as an optimization
  /// @return An up-to-date Tier struct; if the prize is outdated then it is recomputed based on available liquidity and the draw id updated.
  function _getTier(uint8 _tier, uint8 _numberOfTiers) internal view returns (Tier memory) {
    Tier memory tier = _tiers[_tier];
    uint16 _lastClosedDrawId = lastClosedDrawId;
    if (tier.drawId != _lastClosedDrawId) {
      tier.drawId = _lastClosedDrawId;
      tier.prizeSize = uint96(
        _computePrizeSize(
          _tier,
          _numberOfTiers,
          fromUD34x4toUD60x18(tier.prizeTokenPerShare),
          fromUD34x4toUD60x18(prizeTokenPerShare)
        )
      );
    }
    return tier;
  }

  /// @notice Computes the total shares in the system. That is `(number of tiers * tier shares) + canary shares + reserve shares`.
  /// @return The total shares
  function getTotalShares() external view returns (uint256) {
    return _getTotalShares(numberOfTiers);
  }

  /// @notice Computes the total shares in the system given the number of tiers. That is `(number of tiers * tier shares) + canary shares + reserve shares`.
  /// @param _numberOfTiers The number of tiers to calculate the total shares for
  /// @return The total shares
  function _getTotalShares(uint8 _numberOfTiers) internal view returns (uint256) {
    return
      uint256(_numberOfTiers - 1) *
      uint256(tierShares) +
      uint256(canaryShares) +
      uint256(reserveShares);
  }

  /// @notice Computes the number of shares for the given tier. If the tier is the canary tier, then the canary shares are returned. Normal tier shares otherwise.
  /// @param _tier The tier to request share for
  /// @param _numTiers The number of tiers. Passed explicitly as an optimization
  /// @return The number of shares for the given tier
  function _computeShares(uint8 _tier, uint8 _numTiers) internal view returns (uint8) {
    return _isCanaryTier(_tier, _numTiers) ? canaryShares : tierShares;
  }

  /// @notice Consumes liquidity from the given tier.
  /// @param _tierStruct The tier to consume liquidity from
  /// @param _tier The tier number
  /// @param _liquidity The amount of liquidity to consume
  /// @return An updated Tier struct after consumption
  function _consumeLiquidity(
    Tier memory _tierStruct,
    uint8 _tier,
    uint104 _liquidity
  ) internal returns (Tier memory) {
    uint8 _shares = _computeShares(_tier, numberOfTiers);
    uint104 remainingLiquidity = uint104(
      fromUD60x18(
        _getTierRemainingLiquidity(
          _shares,
          fromUD34x4toUD60x18(_tierStruct.prizeTokenPerShare),
          fromUD34x4toUD60x18(prizeTokenPerShare)
        )
      )
    );
    if (_liquidity > remainingLiquidity) {
      uint104 excess = _liquidity - remainingLiquidity;
      if (excess > _reserve) {
        revert InsufficientLiquidity(_liquidity);
      }
      _reserve -= excess;
      _tierStruct.prizeTokenPerShare = prizeTokenPerShare;
    } else {
      UD34x4 delta = fromUD60x18toUD34x4(toUD60x18(_liquidity).div(toUD60x18(_shares)));
      _tierStruct.prizeTokenPerShare = UD34x4.wrap(
        UD34x4.unwrap(_tierStruct.prizeTokenPerShare) + UD34x4.unwrap(delta)
      );
    }
    _tiers[_tier] = _tierStruct;
    return _tierStruct;
  }

  /// @notice Computes the prize size of the given tier.
  /// @param _tier The tier to compute the prize size of
  /// @param _numberOfTiers The current number of tiers
  /// @param _tierPrizeTokenPerShare The prizeTokenPerShare of the Tier struct
  /// @param _prizeTokenPerShare The global prizeTokenPerShare
  /// @return The prize size
  function _computePrizeSize(
    uint8 _tier,
    uint8 _numberOfTiers,
    UD60x18 _tierPrizeTokenPerShare,
    UD60x18 _prizeTokenPerShare
  ) internal view returns (uint256) {
    assert(_tier < _numberOfTiers);
    uint256 prizeSize;
    if (_prizeTokenPerShare.gt(_tierPrizeTokenPerShare)) {
      if (_isCanaryTier(_tier, _numberOfTiers)) {
        prizeSize = _computePrizeSize(
          _tierPrizeTokenPerShare,
          _prizeTokenPerShare,
          _canaryPrizeCountFractional(_numberOfTiers),
          canaryShares
        );
      } else {
        prizeSize = _computePrizeSize(
          _tierPrizeTokenPerShare,
          _prizeTokenPerShare,
          toUD60x18(TierCalculationLib.prizeCount(_tier)),
          tierShares
        );
      }
    }
    return prizeSize;
  }

  /// @notice Computes the prize size with the given parameters.
  /// @param _tierPrizeTokenPerShare The prizeTokenPerShare of the Tier struct
  /// @param _prizeTokenPerShare The global prizeTokenPerShare
  /// @param _fractionalPrizeCount The prize count as UD60x18
  /// @param _shares The number of shares that the tier has
  /// @return The prize size
  function _computePrizeSize(
    UD60x18 _tierPrizeTokenPerShare,
    UD60x18 _prizeTokenPerShare,
    UD60x18 _fractionalPrizeCount,
    uint8 _shares
  ) internal pure returns (uint256) {
    return
      fromUD60x18(
        _prizeTokenPerShare.sub(_tierPrizeTokenPerShare).mul(toUD60x18(_shares)).div(
          _fractionalPrizeCount
        )
      );
  }

  function _isCanaryTier(uint8 _tier, uint8 _numberOfTiers) internal pure returns (bool) {
    return _tier == _numberOfTiers - 1;
  }

  /// @notice Reclaims liquidity from tiers, starting at the highest tier.
  /// @param _numberOfTiers The existing number of tiers
  /// @param _nextNumberOfTiers The next number of tiers. Must be less than _numberOfTiers
  /// @return The total reclaimed liquidity
  function _getTierLiquidityToReclaim(
    uint8 _numberOfTiers,
    uint8 _nextNumberOfTiers,
    UD60x18 _prizeTokenPerShare
  ) internal view returns (uint256) {
    UD60x18 reclaimedLiquidity;
    // need to redistribute to the canary tier and any new tiers (if expanding)
    uint8 start;
    uint8 end;
    // if we are expanding, need to reset the canary tier and all of the new tiers
    if (_nextNumberOfTiers < _numberOfTiers) {
      start = _nextNumberOfTiers - 1;
      end = _numberOfTiers;
    } else {
      // just reset the canary tier
      start = _numberOfTiers - 1;
      end = _numberOfTiers;
    }
    for (uint8 i = start; i < end; i++) {
      Tier memory tierLiquidity = _tiers[i];
      uint8 shares = _computeShares(i, _numberOfTiers);
      UD60x18 liq = _getTierRemainingLiquidity(
        shares,
        fromUD34x4toUD60x18(tierLiquidity.prizeTokenPerShare),
        _prizeTokenPerShare
      );
      reclaimedLiquidity = reclaimedLiquidity.add(liq);
    }
    return fromUD60x18(reclaimedLiquidity);
  }

  /// @notice Computes the remaining liquidity available to a tier.
  /// @param _tier The tier to compute the liquidity for
  /// @return The remaining liquidity
  function getTierRemainingLiquidity(uint8 _tier) external view returns (uint256) {
    uint8 _numTiers = numberOfTiers;
    return
      fromUD60x18(
        _getTierRemainingLiquidity(
          _computeShares(_tier, _numTiers),
          fromUD34x4toUD60x18(_getTier(_tier, _numTiers).prizeTokenPerShare),
          fromUD34x4toUD60x18(prizeTokenPerShare)
        )
      );
  }

  /// @notice Computes the remaining tier liquidity.
  /// @param _shares The number of shares that the tier has (can be tierShares or canaryShares)
  /// @param _tierPrizeTokenPerShare The prizeTokenPerShare of the Tier struct
  /// @param _prizeTokenPerShare The global prizeTokenPerShare
  /// @return The remaining available liquidity
  function _getTierRemainingLiquidity(
    uint256 _shares,
    UD60x18 _tierPrizeTokenPerShare,
    UD60x18 _prizeTokenPerShare
  ) internal pure returns (UD60x18) {
    if (_tierPrizeTokenPerShare.gte(_prizeTokenPerShare)) {
      return ud(0);
    }
    UD60x18 delta = _prizeTokenPerShare.sub(_tierPrizeTokenPerShare);
    return delta.mul(toUD60x18(_shares));
  }

  /// @notice Retrieves the id of the next draw to be closed.
  /// @return The next draw id
  function getOpenDrawId() external view returns (uint16) {
    return lastClosedDrawId + 1;
  }

  /// @notice Estimates the number of prizes that will be awarded.
  /// @return The estimated prize count
  function estimatedPrizeCount() external returns (uint32) {
    return _estimatedPrizeCount(numberOfTiers);
  }

  /// @notice Estimates the number of prizes that will be awarded given a number of tiers.
  /// @param numTiers The number of tiers
  /// @return The estimated prize count for the given number of tiers
  function estimatedPrizeCount(uint8 numTiers) external returns (uint32) {
    return _estimatedPrizeCount(numTiers);
  }

  /// @notice Returns the number of canary prizes as a fraction. This allows the canary prize size to accurately represent the number of tiers + 1.
  /// @param numTiers The number of prize tiers
  /// @return The number of canary prizes
  function canaryPrizeCountFractional(uint8 numTiers) external view returns (UD60x18) {
    return _canaryPrizeCountFractional(numTiers);
  }

  /// @notice Computes the number of canary prizes for the last closed draw.
  /// @return The number of canary prizes
  function canaryPrizeCount() external view returns (uint32) {
    return _canaryPrizeCount(numberOfTiers);
  }

  /// @notice Computes the number of canary prizes for the last closed draw
  /// @param _numberOfTiers The number of tiers
  /// @return The number of canary prizes
  function _canaryPrizeCount(uint8 _numberOfTiers) internal view returns (uint32) {
    return uint32(fromUD60x18(_canaryPrizeCountFractional(_numberOfTiers).floor()));
  }

  /// @notice Computes the number of canary prizes given the number of tiers.
  /// @param _numTiers The number of prize tiers
  /// @return The number of canary prizes
  function canaryPrizeCount(uint8 _numTiers) external view returns (uint32) {
    return _canaryPrizeCount(_numTiers);
  }

  /// @notice Returns the balance of the reserve.
  /// @return The amount of tokens that have been reserved.
  function reserve() external view returns (uint256) {
    return _reserve;
  }

  function generateEstimatedPrizeCountFunctionSignature(
    uint8 numTiers
  ) public returns (bytes memory) {
    bytes memory signature;
    if (numTiers >= 10) {
      signature = new bytes(5);
      signature[0] = bytes1(0x65); // e
      signature[1] = bytes1(uint8(1));
      signature[2] = bytes1(uint8(bytes1(uint8(bytes1(0x30)) + numTiers - 10)));
      signature[3] = bytes1(uint8(bytes1(0x28))); // (
      signature[4] = bytes1(uint8(bytes1(0x29))); // )
    } else {
      signature = new bytes(4);
      signature[0] = bytes1(0x65); // e
      signature[1] = bytes1(0x30 + numTiers);
      signature[2] = bytes1(uint8(bytes1(0x28))); // (
      signature[3] = bytes1(uint8(bytes1(0x29))); // )
    }
    console.log(string("e3()"));
    console.log(string(signature));
    console.logBytes("e3()");
    console.logBytes(signature);
    console.logBytes(abi.encodeWithSelector(bytes4(keccak256(signature))));
    console.logBytes(abi.encodeWithSignature(string(signature)));
    console.logBytes(abi.encodeWithSignature("e3()"));
    console.logBytes4(this.e3.selector);
    return abi.encodeWithSelector(bytes4(keccak256(signature)));
  }

  function generateEstimatedTierOddsFunctionSignature(
    uint8 tier,
    uint8 numTiers
  ) public pure returns (bytes memory) {
    bytes memory signature;
    // signature[1] = bytes1(uint8(bytes1(0x30)) + tier + numTiers); // ASCII code for '0' + number
    if (tier >= 10) {
      if (numTiers >= 10) {
        signature = new bytes(7);
        signature[0] = bytes1(0x74); // ASCII code for 't'
        signature[1] = bytes1(uint8(1));
        signature[2] = bytes1(uint8(bytes1(uint8(bytes1(0x30)) + tier - 10)));
        signature[3] = bytes1(uint8(1));
        signature[4] = bytes1(uint8(uint8(bytes1(0x30)) + numTiers - 10));
        signature[5] = bytes1(uint8(bytes1(0x28))); // (
        signature[6] = bytes1(uint8(bytes1(0x29))); // )
      } else {
        signature = new bytes(6);
        signature[0] = bytes1(0x74); // ASCII code for 't'
        signature[1] = bytes1(uint8(1));
        signature[2] = bytes1(uint8(bytes1(uint8(bytes1(0x30)) + tier - 10)));
        signature[3] = bytes1(uint8(uint8(bytes1(0x30)) + numTiers));
        signature[4] = bytes1(uint8(bytes1(0x28))); // (
        signature[5] = bytes1(uint8(bytes1(0x29))); // )
      }
    } else {
      if (numTiers >= 10) {
        signature = new bytes(6);
        signature[0] = bytes1(0x74); // ASCII code for 't'
        signature[1] = bytes1(uint8(tier));
        signature[2] = bytes1(uint8(1));
        signature[3] = bytes1(uint8(uint8(bytes1(0x30)) + numTiers - 10));
        signature[4] = bytes1(uint8(bytes1(0x28))); // (
        signature[5] = bytes1(uint8(bytes1(uint8(bytes1(0x30)) + numTiers - 10))); // )
      } else {
        signature = new bytes(5);
        signature[0] = bytes1(0x74); // ASCII code for 't'
        signature[1] = bytes1(uint8(tier));
        signature[2] = bytes1(uint8(uint8(bytes1(0x30)) + numTiers));
        signature[3] = bytes1(uint8(bytes1(0x28))); // (
        signature[4] = bytes1(uint8(bytes1(uint8(bytes1(0x30)) + numTiers - 10))); // )
      }
    }
    console2.log("signature: %s", abi.decode(signature, (string)));
    return abi.encodeWithSelector(bytes4(keccak256(signature)));
  }

  function callFunctionBySignature(bytes memory funcSignature) public returns (uint256) {
    (bool success, bytes memory returnData) = address(this).staticcall(funcSignature);
    require(success, "Function call failed.");
    return abi.decode(returnData, (uint256));
  }

  /// @notice Estimates the prize count for the given tier.
  /// @param numTiers The number of prize tiers
  /// @return The estimated total number of prizes
  function _estimatedPrizeCount(uint8 numTiers) internal returns (uint32) {
    return uint32(callFunctionBySignature(generateEstimatedPrizeCountFunctionSignature(numTiers)));
  }

  /// @notice Computes the canary prize count for the given number of tiers
  /// @param numTiers The number of prize tiers
  /// @return The fractional canary prize count
  function _canaryPrizeCountFractional(uint8 numTiers) internal view returns (UD60x18) {
    if (numTiers == 3) {
      return CANARY_PRIZE_COUNT_FOR_2_TIERS;
    } else if (numTiers == 4) {
      return CANARY_PRIZE_COUNT_FOR_3_TIERS;
    } else if (numTiers == 5) {
      return CANARY_PRIZE_COUNT_FOR_4_TIERS;
    } else if (numTiers == 6) {
      return CANARY_PRIZE_COUNT_FOR_5_TIERS;
    } else if (numTiers == 7) {
      return CANARY_PRIZE_COUNT_FOR_6_TIERS;
    } else if (numTiers == 8) {
      return CANARY_PRIZE_COUNT_FOR_7_TIERS;
    } else if (numTiers == 9) {
      return CANARY_PRIZE_COUNT_FOR_8_TIERS;
    } else if (numTiers == 10) {
      return CANARY_PRIZE_COUNT_FOR_9_TIERS;
    } else if (numTiers == 11) {
      return CANARY_PRIZE_COUNT_FOR_10_TIERS;
    } else if (numTiers == 12) {
      return CANARY_PRIZE_COUNT_FOR_11_TIERS;
    } else if (numTiers == 13) {
      return CANARY_PRIZE_COUNT_FOR_12_TIERS;
    } else if (numTiers == 14) {
      return CANARY_PRIZE_COUNT_FOR_13_TIERS;
    } else if (numTiers == 15) {
      return CANARY_PRIZE_COUNT_FOR_14_TIERS;
    }
    return ud(0);
  }

  /// @notice Computes the odds for a tier given the number of tiers.
  /// @param _tier The tier to compute odds for
  /// @param _numTiers The number of prize tiers
  /// @return The odds of the tier
  function getTierOdds(uint8 _tier, uint8 _numTiers) external returns (SD59x18) {
    return _tierOdds(_tier, _numTiers);
  }

  /// @notice Computes the odds for a tier given the number of tiers.
  /// @param _tier The tier to compute odds for
  /// @param _numTiers The number of prize tiers
  /// @return The odds of the tier
  function _tierOdds(uint8 _tier, uint8 _numTiers) internal returns (SD59x18) {
    return
      SD59x18.wrap(
        int256(
          callFunctionBySignature(generateEstimatedTierOddsFunctionSignature(_tier, _numTiers))
        )
      );
  }
}

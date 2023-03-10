// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "forge-std/console2.sol";

import { RingBufferLib } from "ring-buffer-lib/RingBufferLib.sol";
import { E, SD59x18, sd, unwrap, toSD59x18, fromSD59x18 } from "prb-math/SD59x18.sol";

struct Observation {
    // track the total amount available as of this Observation
    uint96 available;
    // track the total accumulated previously
    uint168 disbursed;
}

library DrawAccumulatorLib {

    uint24 internal constant MAX_CARDINALITY = 366;

    struct RingBufferInfo {
        uint16 nextIndex;
        uint16 cardinality;
    }

    struct Accumulator {
        RingBufferInfo ringBufferInfo;
        uint32[MAX_CARDINALITY] drawRingBuffer;
        mapping(uint256 => Observation) observations;
    }

    struct Pair32 {
        uint32 first;
        uint32 second;
    }

    function add(Accumulator storage accumulator, uint256 _amount, uint32 _drawId, SD59x18 _alpha) internal returns (bool) {
        RingBufferInfo memory ringBufferInfo = accumulator.ringBufferInfo;

        uint256 newestIndex = RingBufferLib.newestIndex(ringBufferInfo.nextIndex, MAX_CARDINALITY);
        uint32 newestDrawId = accumulator.drawRingBuffer[newestIndex];

        require(_drawId >= newestDrawId, "invalid draw");

        Observation memory newestObservation_ = accumulator.observations[newestDrawId];
        if (_drawId != newestDrawId) {

            uint256 relativeDraw = _drawId - newestDrawId;

            uint256 remainingAmount = integrateInf(_alpha, relativeDraw, newestObservation_.available);
            uint256 disbursedAmount = integrate(_alpha, 0, relativeDraw, newestObservation_.available);

            accumulator.drawRingBuffer[ringBufferInfo.nextIndex] = _drawId;
            accumulator.observations[_drawId] = Observation({
                available: uint96(_amount + remainingAmount),
                disbursed: uint168(newestObservation_.disbursed + disbursedAmount)
            });
            uint16 nextIndex = uint16(RingBufferLib.nextIndex(ringBufferInfo.nextIndex, MAX_CARDINALITY));
            uint16 cardinality = ringBufferInfo.cardinality;
            if (ringBufferInfo.cardinality < MAX_CARDINALITY) {
                cardinality += 1;
            }
            accumulator.ringBufferInfo = RingBufferInfo({
                nextIndex: nextIndex,
                cardinality: cardinality
            });
            return true;
        } else {
            accumulator.observations[newestDrawId] = Observation({
                available: uint96(newestObservation_.available + _amount),
                disbursed: newestObservation_.disbursed
            });
            return false;
        }
    }

    function getTotalRemaining(Accumulator storage accumulator, uint32 _endDrawId, SD59x18 _alpha) internal view returns (uint256) {
        RingBufferInfo memory ringBufferInfo = accumulator.ringBufferInfo;
        if (ringBufferInfo.cardinality == 0) {
            return 0;
        }
        uint256 newestIndex = RingBufferLib.newestIndex(ringBufferInfo.nextIndex, MAX_CARDINALITY);
        uint32 newestDrawId = accumulator.drawRingBuffer[newestIndex];
        require(_endDrawId >= newestDrawId, "invalid draw");
        Observation memory newestObservation_ = accumulator.observations[newestDrawId];
        return integrateInf(_alpha, _endDrawId - newestDrawId, newestObservation_.available);
    }

    function newestObservation(Accumulator storage accumulator) internal view returns (Observation memory) {
        return accumulator.observations[RingBufferLib.newestIndex(accumulator.ringBufferInfo.nextIndex, MAX_CARDINALITY)];
    }

    /**
     * @param _endDrawId Must be be greater than (newest draw id - 1)
     */
    function getDisbursedBetween(
        Accumulator storage _accumulator,
        uint32 _startDrawId,
        uint32 _endDrawId,
        SD59x18 _alpha
    ) internal view returns (uint256) {
        require(_startDrawId <= _endDrawId, "invalid draw range");

        RingBufferInfo memory ringBufferInfo = _accumulator.ringBufferInfo;

        if (ringBufferInfo.cardinality == 0) {
            return 0;
        }

        Pair32 memory indexes = computeIndices(ringBufferInfo);
        Pair32 memory drawIds = readDrawIds(_accumulator, indexes);

        require(_endDrawId >= drawIds.second-1, "DAL/curr-invalid");

        if (_endDrawId < drawIds.first) {
            return 0;
        }

        /*

        head: residual accrual from observation before start. (if any)
        body: if there is more than one observations between start and current, then take the past _accumulator diff
        tail: accrual between the newest observation and current.  if card > 1 there is a tail (almost always)

        let:
            - s = start draw id
            - e = end draw id
            - o = observation
            - h = "head". residual balance from the last o occurring before s.  head is the disbursed amount between (o, s)
            - t = "tail". the residual balance from the last o occuring before e.  tail is the disbursed amount between (o, e)
            - b = "body". if there are *two* observations between s and e we calculate how much was disbursed. body is (last obs disbursed - first obs disbursed)

        total = head + body + tail
        
        
        lastObservationOccurringAtOrBeforeEnd
        firstObservationOccurringAtOrAfterStart

        Like so

           s        e
        o  <h>  o  <t>  o

           s                 e
        o  <h> o   <b>  o  <t>  o

         */

        uint32 lastObservationDrawIdOccurringAtOrBeforeEnd;
        if (_endDrawId >= drawIds.second) {
            // then it must be the end
            lastObservationDrawIdOccurringAtOrBeforeEnd = drawIds.second;
        } else {
            // otherwise it must be the previous one
            lastObservationDrawIdOccurringAtOrBeforeEnd = _accumulator.drawRingBuffer[uint32(RingBufferLib.offset(indexes.second, 1, ringBufferInfo.cardinality))];
        }

        uint32 observationDrawIdBeforeOrAtStart;
        uint32 firstObservationDrawIdOccurringAtOrAfterStart;
        // if there is only one observation, or startId is after the oldest record
        if (_startDrawId >= drawIds.second) {
            // then use the last record
            observationDrawIdBeforeOrAtStart = drawIds.second;
        } else if (_startDrawId <= drawIds.first) { // if the start is before the newest record
            // then set to the oldest record.
            firstObservationDrawIdOccurringAtOrAfterStart = drawIds.first;
        } else { // The start must be between newest and oldest
            // binary search
            (, observationDrawIdBeforeOrAtStart, , firstObservationDrawIdOccurringAtOrAfterStart) = binarySearch(
                _accumulator.drawRingBuffer, indexes.first, indexes.second, ringBufferInfo.cardinality, _startDrawId
            );
        }

        // console2.log("observationDrawIdBeforeOrAtStart", observationDrawIdBeforeOrAtStart);
        // console2.log("firstObservationDrawIdOccurringAtOrAfterStart", firstObservationDrawIdOccurringAtOrAfterStart);
        // console2.log("lastObservationDrawIdOccurringAtOrBeforeEnd", lastObservationDrawIdOccurringAtOrBeforeEnd);

        uint256 total;

        // if a "head" exists
        if (observationDrawIdBeforeOrAtStart > 0 &&
            firstObservationDrawIdOccurringAtOrAfterStart > 0 &&
            observationDrawIdBeforeOrAtStart != lastObservationDrawIdOccurringAtOrBeforeEnd) {
            Observation memory beforeOrAtStart = _accumulator.observations[observationDrawIdBeforeOrAtStart];
            uint32 headStartDrawId = _startDrawId - observationDrawIdBeforeOrAtStart;
            uint32 headEndDrawId = headStartDrawId + (firstObservationDrawIdOccurringAtOrAfterStart - _startDrawId);
            // console2.log("headLog observationDrawIdBeforeOrAtStart", observationDrawIdBeforeOrAtStart);
            // console2.log("headLog range start", headStartDrawId);
            // console2.log("headLog range end", headEndDrawId);
            uint amount = integrate(_alpha, headStartDrawId, headEndDrawId, beforeOrAtStart.available);
            // console2.log("headLog amount", amount);
            total += amount;
        }

        Observation memory atOrBeforeEnd;
        // if a "body" exists
        if (firstObservationDrawIdOccurringAtOrAfterStart > 0 &&
            firstObservationDrawIdOccurringAtOrAfterStart < lastObservationDrawIdOccurringAtOrBeforeEnd) {
            Observation memory atOrAfterStart = _accumulator.observations[firstObservationDrawIdOccurringAtOrAfterStart];
            atOrBeforeEnd = _accumulator.observations[lastObservationDrawIdOccurringAtOrBeforeEnd];
            uint amount = atOrBeforeEnd.disbursed - atOrAfterStart.disbursed;
            total += amount;
            // console2.log("bodyLog firstObservationDrawIdOccurringAtOrAfterStart", firstObservationDrawIdOccurringAtOrAfterStart);
            // console2.log("bodyLog lastObservationDrawIdOccurringAtOrBeforeEnd", lastObservationDrawIdOccurringAtOrBeforeEnd);
            // console2.log("bodyLog amount", amount);
        }

        total += _computeTail(_accumulator, _startDrawId, _endDrawId, lastObservationDrawIdOccurringAtOrBeforeEnd, _alpha);

        return total;
    }

    function _computeTail(
        Accumulator storage accumulator,
        uint32 _startDrawId,
        uint32 _endDrawId,
        uint32 _lastObservationDrawIdOccurringAtOrBeforeEnd,
        SD59x18 _alpha
    ) internal view returns (uint256) {
        Observation memory lastObservation = accumulator.observations[_lastObservationDrawIdOccurringAtOrBeforeEnd];
        uint32 tailRangeStartDrawId = (_startDrawId > _lastObservationDrawIdOccurringAtOrBeforeEnd ? _startDrawId : _lastObservationDrawIdOccurringAtOrBeforeEnd) - _lastObservationDrawIdOccurringAtOrBeforeEnd;
        uint256 amount = integrate(_alpha, tailRangeStartDrawId, _endDrawId - _lastObservationDrawIdOccurringAtOrBeforeEnd + 1, lastObservation.available);
        // console2.log("tailLog _lastObservationDrawIdOccurringAtOrBeforeEnd", _lastObservationDrawIdOccurringAtOrBeforeEnd);
        // console2.log("tailLog tailRangeStartDrawId", tailRangeStartDrawId);
        // console2.log("tailLog lastObservation.available", lastObservation.available);
        // console2.log("tailLog _startDrawId", _startDrawId);
        // console2.log("tailLog _endDrawId", _endDrawId);
        // console2.log("tailLog amount", amount);
        return amount;
    }

    function computeIndices(RingBufferInfo memory ringBufferInfo) internal pure returns (Pair32 memory) {
        return Pair32({
            first: uint32(RingBufferLib.oldestIndex(ringBufferInfo.nextIndex, ringBufferInfo.cardinality, MAX_CARDINALITY)),
            second: uint32(RingBufferLib.newestIndex(ringBufferInfo.nextIndex, ringBufferInfo.cardinality))
        });
    }

    function readDrawIds(Accumulator storage accumulator, Pair32 memory indices) internal view returns (Pair32 memory) {
        return Pair32({
            first: uint32(accumulator.drawRingBuffer[indices.first]),
            second: uint32(accumulator.drawRingBuffer[indices.second])
        });
    }

    /**
     * @notice Returns the remaining prize tokens available from relative draw _x
     */
    function integrateInf(SD59x18 _alpha, uint _x, uint _k) internal pure returns (uint256) {
        return uint256(fromSD59x18(computeC(_alpha, _x, _k)));
    }

    /**
     * @notice returns the number of tokens that were given out between draw _start and draw _end
     */
    function integrate(SD59x18 _alpha, uint _start, uint _end, uint _k) internal pure returns (uint256) {
        int start = unwrap(
            computeC(_alpha, _start, _k)
        );
        // console2.log("integrate start" , start);
        int end = unwrap(
            computeC(_alpha, _end, _k)
        );
        // console2.log("integrate end" , end);
        return uint256(
            fromSD59x18(
                sd(
                    start
                    -
                    end
                )
            )
        );
    }

    function computeC(SD59x18 _alpha, uint _x, uint _k) internal pure returns (SD59x18) {
        return toSD59x18(int(_k)).mul(_alpha.pow(toSD59x18(int256(_x))));
    }

    /**
     */
    function binarySearch(
        uint32[MAX_CARDINALITY] storage _drawRingBuffer,
        uint32 _oldestIndex,
        uint32 _newestIndex,
        uint32 _cardinality,
        uint32 _targetLastCompletedDrawId
    ) internal view returns (
        uint32 beforeOrAtIndex,
        uint32 beforeOrAtDrawId,
        uint32 afterOrAtIndex,
        uint32 afterOrAtDrawId
    ) {
        uint32 leftSide = _oldestIndex;
        uint32 rightSide = _newestIndex < leftSide
            ? leftSide + _cardinality - 1
            : _newestIndex;
        uint32 currentIndex;

        while (true) {
            // We start our search in the middle of the `leftSide` and `rightSide`.
            // After each iteration, we narrow down the search to the left or the right side while still starting our search in the middle.
            currentIndex = (leftSide + rightSide) / 2;

            beforeOrAtIndex = uint32(RingBufferLib.wrap(currentIndex, _cardinality));
            beforeOrAtDrawId = _drawRingBuffer[beforeOrAtIndex];

            afterOrAtIndex = uint32(RingBufferLib.nextIndex(currentIndex, _cardinality));
            afterOrAtDrawId = _drawRingBuffer[afterOrAtIndex];

            bool targetAtOrAfter = beforeOrAtDrawId <= _targetLastCompletedDrawId;

            // Check if we've found the corresponding Observation.
            if (targetAtOrAfter && _targetLastCompletedDrawId <= afterOrAtDrawId) {
                break;
            }

            // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower. To the left of the current index.
            if (!targetAtOrAfter) {
                rightSide = currentIndex - 1;
            } else {
                // Otherwise, we keep searching higher. To the left of the current index.
                leftSide = currentIndex + 1;
            }
        }
    }
}

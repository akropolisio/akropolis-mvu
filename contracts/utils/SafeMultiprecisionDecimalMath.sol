/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SafeMultiprecisionDecimalMath.sol
version:    1.0
author:     Anton Jurisevic

date:       2018-9-3

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A fixed point decimal library that provides basic mathematical
operations, and checks for unsafe arguments, for example that
would lead to overflows. Exceptions are thrown whenever those
unsafe operations occur.

The library has no fixed precision, and all relevant operations
must be provided with the input and output precision of the
operands.

-----------------------------------------------------------------
*/


pragma solidity 0.4.24;
pragma experimental "v0.5.0";


/**
 * @title Safely manipulate unsigned fixed-point decimals at a given precision level.
 * @dev Functions accepting uints in this contract and derived contracts
 * are taken to be such fixed point decimals (including fiat, ether, and nomin quantities).
 */
contract SafeMultiprecisionDecimalMath {

    function unit(uint decimals)
        pure
        internal
        returns (uint)
    {
        // log_10(2^256) is just over 77.
        require(decimals < 78, "Unrepresentable unit.");
        return 10 ** decimals;
    }

    /**
     * @return True iff adding x and y will not overflow.
     */
    function addIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return x + y >= y;
    }

    /**
     * @return The result of adding x and y, throwing an exception in case of overflow.
     */
    function safeAdd(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(x + y >= y, "Unsafe add.");
        return x + y;
    }

    function safeAdd_mpdec(uint x, uint xDecimals, uint y, uint yDecimals, uint outDecimals)
        pure
        internal
        returns (uint)
    {
        uint highDecimals = xDecimals > yDecimals ? xDecimals : yDecimals;
        if (highDecimals == xDecimals) {
            return convertPrecision(safeAdd(x, convertPrecision(y, yDecimals, highDecimals)),
                                    highDecimals,
                                    outDecimals);
        }
        return convertPrecision(safeAdd(convertPrecision(x, xDecimals, highDecimals), y),
                                highDecimals,
                                outDecimals);
    }

    /**
     * @return True iff subtracting y from x will not overflow in the negative direction.
     */
    function subIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y <= x;
    }

    /**
     * @return The result of subtracting y from x, throwing an exception in case of overflow.
     */
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x, "Unsafe sub.");
        return x - y;
    }

    function safeSub_mpdec(uint x, uint xDecimals, uint y, uint yDecimals, uint outDecimals)
        pure
        internal
        returns (uint)
    {
        uint highDecimals = xDecimals > yDecimals ? xDecimals : yDecimals;
        if (highDecimals == xDecimals) {
            return convertPrecision(safeSub(x, convertPrecision(y, yDecimals, highDecimals)),
                                    highDecimals,
                                    outDecimals);
        }
        return convertPrecision(safeSub(convertPrecision(x, xDecimals, highDecimals), y),
                                highDecimals,
                                outDecimals);
    }

    /**
     * @return True iff multiplying x and y would not overflow.
     */
    function mulIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        if (x == 0) {
            return true;
        }
        return (x * y) / x == y;
    }

    /**
     * @return The result of multiplying x and y, throwing an exception in case of overflow.
     */
    function safeMul(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        if (x == 0) {
            return 0;
        }
        uint p = x * y;
        require(p / x == y, "Unsafe mul.");
        return p;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals. Throws an exception in case of overflow.
     * 
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256.
     * Incidentally, the internal division always rounds down: one could have rounded to the nearest integer,
     * but then one would be spending a significant fraction of a cent (of order a microether
     * at present gas prices) in order to save less than one part in 0.5 * 10^18 per operation, if the operands
     * contain small enough fractional components. It would also marginally diminish the 
     * domain this function is defined upon. 
     */
    function safeMul_mpdec(uint x, uint xDecimals, uint y, uint yDecimals, uint outDecimals)
        pure
        internal
        returns (uint)
    {
        if (xDecimals == outDecimals) {
            return safeDiv(safeMul(x, y), unit(yDecimals));
        } else if (yDecimals == outDecimals) {
            return safeDiv(safeMul(x, y), unit(xDecimals));
        }
        return convertPrecision(safeMul(x, y), xDecimals + yDecimals, outDecimals);
    }

    function safeMul_dec(uint x, uint y, uint decimals)
        pure
        internal
        returns (uint)
    {
        return safeMul_mpdec(x, decimals, y, decimals, decimals);
    }

    /**
     * @return True iff the denominator of x/y is nonzero.
     */
    function divIsSafe(uint, uint y)
        pure
        internal
        returns (bool)
    {
        return y != 0;
    }

    /**
     * @return The result of dividing x by y, throwing an exception if the divisor is zero.
     */
    function safeDiv(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        /* Although a 0 denominator already throws an exception,
         * it is equivalent to a THROW operation, which consumes all gas.
         * A require statement emits REVERT instead, which remits remaining gas. */
        require(y != 0, "Unsafe div.");
        return x / y;
    }

    /**
     * @return The result of dividing x by y, interpreting the operands as fixed point decimal numbers.
     * @dev Throws an exception in case of overflow or zero divisor; x must be less than 2^256 / UNIT.
     * Internal rounding is downward: a similar caveat holds as with safeMul_dec().
     */
    function safeDiv_mpdec(uint x, uint xDecimals, uint y, uint yDecimals, uint outputDecimals)
        pure
        internal
        returns (uint)
    {
        /* Reintroduce the yUnit factor that will be divided out by y. */
        if (xDecimals == outputDecimals) {
            return safeDiv(safeMul(x, unit(yDecimals)), y);
        }
        return convertPrecision(safeDiv(safeMul(x, unit(yDecimals)), y), xDecimals, outputDecimals);
    }

    function safeDiv_dec(uint x, uint y, uint decimals)
        pure
        internal
        returns (uint)
    {
        return safeDiv_mpdec(x, decimals, y, decimals, decimals);
    }

    function convertPrecision(uint x, uint decimalsFrom, uint decimalsTo)
        pure
        internal
        returns (uint)
    {   
        if (decimalsFrom == decimalsTo) {
            return x;
        }
        // The guard allows us to eschew safeSub();
        if (decimalsFrom > decimalsTo) {
            return safeMul(x, unit(decimalsFrom - decimalsTo));
        }
        return safeDiv(x, unit(decimalsTo - decimalsFrom));
    }

    /**
     * @dev Convert an unsigned integer to a unsigned fixed-point decimal.
     * Throw an exception if the result would be out of range.
     */
    function intToDec(uint i, uint decimals)
        pure
        internal
        returns (uint)
    {
        return safeMul(i, unit(decimals));
    }
}

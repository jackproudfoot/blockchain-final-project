//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
* @author RickGriff
* This fixed 18 decimal point math library was created by https://github.com/RickGriff/decimath
* I modified the original library by removing any extraneous functions not needed to keep only the ability to do exponentiation
*/

contract DeciMath {

  // Abbreviation: DP stands for 'Decimal Places' 

  uint constant TEN18 = 10**18;


   /******  BASIC MATH OPERATORS ******/

  // Integer math operators. Identical to Zeppelin's SafeMath
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "uint overflow from multiplication");
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "uint overflow from multiplication");
    return c;
  }

  // Basic decimal math operators. Inputs and outputs are uint representations of fixed-point decimals.

  // 18 Decimal places
  function decMul18(uint x, uint y) public pure returns (uint decProd) {
    uint prod_xy = mul(x, y);
    decProd = add(prod_xy, TEN18 / 2) / TEN18;
  }

  function decDiv18(uint x, uint y) public pure returns (uint decQuotient) {
    uint prod_xTEN18 = mul(x, TEN18);
    decQuotient = add(prod_xTEN18, y / 2) / y;
  }


  // b^x - fixed-point 18 DP base, integer exponent
  function powBySquare18(uint base, uint n) public pure returns (uint) {
    if (n == 0)
    return TEN18;

    uint y = TEN18;

    while (n > 1) {
      if (n % 2 == 0) {
        base = decMul18(base, base);
        n = n / 2;
      } else if (n % 2 != 0) {
        y = decMul18(base, y);
        base = decMul18(base, base);
        n = (n - 1)/2;
      }
    }
    return decMul18(base, y);
  }

}
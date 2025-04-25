// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DAI, MKR, USDC, WETH, UNISWAP_V2_ROUTER_02, UNISWAP_V2_FACTORY} from "../src/constants/constants.sol";
import {IWETH} from "../src/Interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/Interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../src/Interfaces/IUniswapv2Factory.sol";
import {IUniswapV2Pair} from "../src/Interfaces/IUniswapv2Pair.sol";
import {ERC20} from "../src/ERC20.sol";

contract Unitest is Test {
    IERC20 private s_dai = IERC20(DAI);
    IERC20 private s_mkr = IERC20(MKR);
    IERC20 private s_usdc = IERC20(USDC);
    IWETH private s_weth = IWETH(WETH);

    IUniswapV2Router02 private s_uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Factory private s_uniswapV2Factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
    uint256 private constant AMOUNT_IN = 20e8;
    uint256 private constant STARTING_BALANCE = 100000e18;
    uint256 private constant AMOUNT_OUT_MIN = 1; // 2000 DAI

    address private USER = makeAddr("user");

    function setUp() public {
        vm.deal(USER, STARTING_BALANCE);
        vm.startPrank(USER);
        s_weth.deposit{value: STARTING_BALANCE}();
        s_weth.approve(address(s_uniswapV2Router), type(uint256).max);
        vm.stopPrank();
    }

    function testSwapExactTokensForTokens() public {
        address[] memory _path = new address[](4);
        _path[0] = WETH;
        _path[1] = MKR;
        _path[2] = USDC;
        _path[3] = DAI;

        uint256 daiBalanceBefore = s_dai.balanceOf(USER);
        vm.startPrank(USER);

        uint256[] memory amounts = s_uniswapV2Router.swapExactTokensForTokens({
            amountIn: AMOUNT_IN,
            amountOutMin: AMOUNT_OUT_MIN,
            path: _path,
            to: USER,
            deadline: block.timestamp
        });
        vm.stopPrank();
        console2.log("DAI amount received: ", amounts[3]);
        uint256 daiBalanceAfter = s_dai.balanceOf(USER);
        assertGt(daiBalanceAfter, daiBalanceBefore);
    }

    function testSwapTokensForExactTokens() public {
        address[] memory _path = new address[](4);
        _path[0] = WETH;
        _path[1] = MKR;
        _path[2] = USDC;
        _path[3] = DAI;
        uint256 _amountInMax = 100e8;
        uint256 _amountOut = 20e8;
        vm.startPrank(USER);
        uint256[] memory amounts = s_uniswapV2Router.swapTokensForExactTokens({
            amountOut: _amountOut,
            amountInMax: _amountInMax,
            path: _path,
            to: USER,
            deadline: block.timestamp
        });
        vm.stopPrank();

        assertEq(s_dai.balanceOf(USER), _amountOut);
        assertGt(_amountInMax, amounts[0]);
    }

    function testCreatePair() public {
        ERC20 token = new ERC20("TEST", "TEST", 18);

        address pair = s_uniswapV2Factory.createPair({tokenA: WETH, tokenB: address(token)});

        address token0 = IUniswapV2Pair(pair).token0();

        address token1 = IUniswapV2Pair(pair).token1();

        if (address(token)  < WETH) {
            assertEq(token0, address(token), "token 0");
            assertEq(token1, WETH, "token 1");
        } else {
            assertEq(token0, WETH, "token 0");
            assertEq(token1, address(token), "token 1");
        }
    }
}

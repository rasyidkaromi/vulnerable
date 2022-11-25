// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/uniswap.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

contract PuppetV2Pool {
    using LowGasSafeMath for uint256;

    address private _uniswapPair;
    address private _uniswapFactory;
    IERC20 private _token;
    IERC20 private _weth;
    
    mapping(address => uint256) public deposits;
    event Borrowed(address indexed borrower, uint256 depositRequired, uint256 borrowAmount, uint256 timestamp);

    constructor (
        address wethAddress,
        address tokenAddress,
        address uniswapPairAddress,
        address uniswapFactoryAddress
    )  {
        _weth = IERC20(wethAddress);
        _token = IERC20(tokenAddress);
        _uniswapPair = uniswapPairAddress;
        _uniswapFactory = uniswapFactoryAddress;
    }

    function borrow(uint256 borrowAmount) external {
        require(_token.balanceOf(address(this)) >= borrowAmount, "Not enough token balance");
        uint256 depositOfWETHRequired = calculateDepositOfWETHRequired(borrowAmount);
        _weth.transferFrom(msg.sender, address(this), depositOfWETHRequired);
        deposits[msg.sender] += depositOfWETHRequired;
        require(_token.transfer(msg.sender, borrowAmount));
        emit Borrowed(msg.sender, depositOfWETHRequired, borrowAmount, block.timestamp);
    }

    function calculateDepositOfWETHRequired(uint256 tokenAmount) public view returns (uint256) {
        return _getOracleQuote(tokenAmount).mul(3) / (10 ** 18);
    }

    function _getOracleQuote(uint256 amount) private view returns (uint256) {
        (uint256 reservesWETH, uint256 reservesToken) = UniswapV2Library.getReserves(
            _uniswapFactory, address(_weth), address(_token)
        );
        return UniswapV2Library.quote(amount.mul(10 ** 18), reservesToken, reservesWETH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import './libraries/TransferHelper.sol';
import './HodlerERC20.sol';

contract Hodler is HodlerERC20{
  using SafeMath for uint256;

  bool public initialized;
  address public asset;
  uint256 public start_amount;
  uint256 public min_percent;
  uint256 public max_percent;
  
  bool public started;
  uint256 public start_time;
  bool public ended;
  mapping(address => uint256) public end_time;
 
  event Deposit(address indexed from, uint256 amount);
  event Withdraw(address indexed from, uint256 asset_value, uint256 token_value, bool started);

  uint256 private unlocked = 1;
  modifier lock() {
      require(unlocked == 1, 'Hodler: LOCKED');
      unlocked = 0;
      _;
      unlocked = 1;
  }

  function initialize(address _asset, uint256 _amount, uint256 _min, uint256 _max) public {
      require(initialized == false, "Hodler_initialize: already initialized");
      initialized = true;
      asset = _asset;
      start_amount = _amount;
      min_percent = _min;
      max_percent = _max;
      string memory _name = IERC20(asset).name();
      name = append("Hodler ", _name);
      string memory _symbol = IERC20(asset).symbol();
      symbol = append("hodl", _symbol);
      decimals = IERC20(asset).decimals();
  }

  function deposit(uint256 amount) public lock {
      require(amount > 0, "Hodler_Deposit: zero asset deposit"); 
      require(ended == false, "Hodler_Deposit: game ended");
      require(started == false, "Hodler_Deposit: game started");
      if (totalSupply.add(amount) >= start_amount) {
          require(totalSupply.add(amount) < start_amount.mul(2), "Hodler_Deposit: final deposit out of range");
          started = true;
          start_time = block.timestamp;
      }
      TransferHelper.safeTransferFrom(asset, msg.sender, address(this), amount); 
      _mint(msg.sender, amount);
      Deposit(msg.sender, amount);
  }

  function withdraw(uint256 token_amount) public lock {
      require(token_amount > 0, "Hodler_withdraw: zero token withdraw"); 
      require(ended == false, "Hodler_withdraw: game ended");
      uint256 asset_withdraw;
      if (started != true) {
          asset_withdraw = token_amount;
          _burn(msg.sender, token_amount);
      } else {
          asset_withdraw = calculateAssetOut(token_amount);
          if (totalWithdraw.add(token_amount) == totalSupply) {
              ended = true;
          }  
          require(asset_withdraw > 0, "Hodler_withdraw: zero asset withdraw");
          _burnCurve(msg.sender, token_amount);
          if (balanceOf[msg.sender] == 0) {end_time[msg.sender] = block.timestamp;}
      }
      TransferHelper.safeTransfer(asset, msg.sender, asset_withdraw);
      Withdraw(msg.sender, asset_withdraw, token_amount, started);
  }

  function calculateAssetOut(uint256 token_amount) public view returns (uint256) {
      uint256 rounding = totalSupply;
      /*
       1. Calc perc_assets_out_new = 40 * totalWithdraw/totalSupply + 80 
          -> At min this is 40 * 0 + 80 = 80% 
          -> At max this is 40 * 1 + 80 = 120% 
      */
      uint256 difference = max_percent.sub(min_percent);
      uint256 perc_assets_out_old = difference.mul(rounding).mul(totalWithdraw).div(totalSupply).add(min_percent.mul(rounding));
      uint256 new_totalWithdraw = totalWithdraw.add(token_amount);
      uint256 perc_assets_out_new = difference.mul(rounding).mul(new_totalWithdraw).div(totalSupply).add(min_percent.mul(rounding));
      /* 
        2. Calc mean percent difference -> perc_new - perc_old / 2 + perc_old
          -> at 120 perc_new and 100 perc_old = (120 - 100) / 2 + 100 = 110% 
          -> at 100 perc_new and 80 perc_old = (100 - 80) / 2 + 80 = 90%
      */
      uint256 mean_perc = (perc_assets_out_new.sub(perc_assets_out_old)).div(2).add(perc_assets_out_old);
      /* 
        3. Calc assets out -> token_amount * mean_perc_diff / 100
          -> at mean_perc_diff 110% = 110 * token_amount / 100
      */
      uint256 assets_out = mean_perc.mul(token_amount).div(rounding.mul(100));
      if (new_totalWithdraw == totalSupply) {
          IERC20 weth = IERC20(asset);
          assets_out = weth.balanceOf(address(this));
      }
      return assets_out;
  }

  function append(string memory a, string memory b) internal pure returns (string memory) {
      return string(abi.encodePacked(a, b));
  }
}

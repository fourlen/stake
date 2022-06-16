// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Stake is Ownable, ReentrancyGuard {

    event Deposit(address indexed staker, uint256 amount);
    event RewardCollected(address indexed staker, uint256 reward);
    event RewardPercentChanged(Levels level, uint256 percentage);

    enum Levels{ Platinum, Gold, Silver, Bronze, Iron }
    mapping(Levels => uint) public level_reward; 
    mapping(address => Staker) public stakers;

    IERC20Metadata public stakedToken;


    struct Staker {
        uint256 amount;
        Levels level;
        uint256 lastCollectTimestamp;
    }


    constructor(IERC20Metadata _stakedToken,
                uint256 IronRewardPercent,
                uint256 BronzeRewardPercent,
                uint256 SilverRewardPercent,
                uint256 GoldRewardPercent,
                uint256 PlatinumRewardPercent) {
        stakedToken = _stakedToken;
        require(IronRewardPercent != 0
                && BronzeRewardPercent != 0
                && SilverRewardPercent != 0
                && GoldRewardPercent != 0
                && PlatinumRewardPercent != 0, "Percent must be > 0");
        level_reward[Levels.Iron] = IronRewardPercent;
        level_reward[Levels.Bronze] = BronzeRewardPercent;
        level_reward[Levels.Silver] = SilverRewardPercent;
        level_reward[Levels.Gold] = GoldRewardPercent;
        level_reward[Levels.Platinum] = PlatinumRewardPercent;
    }


    function updateLevel(address staker_address) internal {
        Staker storage staker = stakers[staker_address];
        if (staker.amount > 0 && staker.amount < 100) {
            staker.level = Levels.Iron;
        } 
        else if (staker.amount >= 100 && staker.amount < 1000) {
            staker.level = Levels.Bronze;
        }
        else if (staker.amount >= 1000 && staker.amount < 10000) {
            staker.level = Levels.Silver;
        }
        else if (staker.amount >= 10000 && staker.amount < 100000) {
            staker.level = Levels.Gold;
        }
        else if (staker.amount >= 100000) {
            staker.level = Levels.Platinum;
        }
        else {
            delete stakers[staker_address];
        }
    }


    function deposit(uint256 _amount) external nonReentrant {
        //deposit
        Staker storage staker = stakers[msg.sender];
        require(_amount != 0, "Amount must be non-zero");
        bool result = stakedToken.transferFrom(msg.sender, address(this), _amount);
        require(result, "Error while token transfering");
        uint256 reward = (staker.amount * level_reward[staker.level] * (block.timestamp - staker.lastCollectTimestamp)) / (100 * 365 * 86400);
        staker.lastCollectTimestamp = block.timestamp;
        staker.amount += _amount + reward; 
        //update level
        updateLevel(msg.sender);
        emit Deposit(msg.sender, _amount);
    }


    function withdraw(uint256 _amount) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.amount >= _amount, "Not enough tokens");
        bool result = stakedToken.transfer(msg.sender, _amount);
        require(result, "Somthing goes wrong");
        staker.amount -= _amount;
        updateLevel(msg.sender);
    }


    function collectReward(bool is_redeposit) external nonReentrant{
        Staker storage staker = stakers[msg.sender];
        uint256 reward = (staker.amount * level_reward[staker.level] * (block.timestamp - staker.lastCollectTimestamp)) / (100 * 365 * 86400);
        require(reward != 0, "Reward is less than 10^-18 token");
        if (is_redeposit) {
            staker.amount += reward;
        } 
        else {
            stakedToken.transfer(msg.sender, reward);
        }
        staker.lastCollectTimestamp = block.timestamp;
        updateLevel(msg.sender);
        emit RewardCollected(msg.sender, reward);
    }


    function changeRewardPercent(Levels level, uint256 percentage) external nonReentrant onlyOwner {
        require(percentage != 0, "Percent must be > 0");
        level_reward[level] = percentage;
        emit RewardPercentChanged(level, percentage);
    }

}
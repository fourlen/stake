// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Stake is Ownable, ReentrancyGuard {
    IERC20Metadata public stakedToken;

    mapping(Levels => uint256) public levelReward;
    mapping(address => Staker) public stakers;
    mapping(Levels => uint256) public thresholds; //добавил массив порогов. С этого числа начинается уровень.

    enum Levels {
        Platinum,
        Gold,
        Silver,
        Bronze,
        Iron
    }

    struct Staker {
        uint256 amount;
        uint256 lastCollectTimestamp;
    }

    event Deposit(address indexed staker, uint256 amount);
    event RewardCollected(address indexed staker, uint256 reward);
    event RewardPercentChanged(uint256[5] rewardPercents);
    event ThresholdChanged(Levels level, uint256 threshold);

    //заменил на массив, теперь нужно передавать проценты от Platinum к Iron.
    constructor(
        IERC20Metadata _stakedToken,
        uint256[5] memory rewardPercents,
        uint256[4] memory _thresholds //4, потому что для Iron всегда 0
    ) {
        stakedToken = _stakedToken;
        thresholds[Levels(4)] = 0;
        for (uint8 i = 0; i < 5; i++) {
            require(rewardPercents[i] != 0, "Percent must be > 0");
            levelReward[Levels(i)] = rewardPercents[i];
            if (i < 4) {
                require(
                    _thresholds[i] > thresholds[Levels(i + 1)],
                    "Threshold must be greater than threashold of previous level"
                );
                thresholds[Levels(i)] = _thresholds[i];
            }
        }
    }

    function deposit(uint256 _amount) external nonReentrant {
        //deposit
        Staker storage staker = stakers[msg.sender];
        require(_amount != 0, "Amount must be non-zero");
        _collectReward(true);
        SafeERC20.safeTransferFrom(
            stakedToken,
            msg.sender, //опустил пониже, но не ниже staker.amount +=, чтобы если транзакция завалилась, стекейру amount не прибавился
            address(this), //safeTransferFrom не возвращает bool, поэтому проеврку убрал
            _amount
        );
        staker.amount += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        _collectReward(true);
        require(staker.amount >= _amount, "Not enough tokens");
        bool result = stakedToken.transfer(msg.sender, _amount);
        require(result, "Somthing goes wrong");
        staker.amount -= _amount;
        if (staker.amount == 0) {
            delete stakers[msg.sender];
        }
    }

    function collectReward(bool is_redeposit) external nonReentrant {
        uint256 reward = _collectReward(is_redeposit);
        emit RewardCollected(msg.sender, reward);
    }

    function changeRewardPercent(uint256[5] memory rewardPercents)
        external
        nonReentrant
        onlyOwner
    {
        for (uint8 i = 0; i < rewardPercents.length; i++) {
            require(rewardPercents[i] != 0, "Percent must be > 0");
            levelReward[Levels(i)] = rewardPercents[i];
        }
        emit RewardPercentChanged(rewardPercents);
    }

    function changeThresholds(uint256[4] memory _thresholds)
        external
        nonReentrant
        onlyOwner
    {
        for (uint8 i = 0; i < 4; i++) {
            require(
                _thresholds[i] > thresholds[Levels(i + 1)],
                "Threshold must be greater than threashold of previous level"
            );
            thresholds[Levels(i)] = _thresholds[i];
        }
    }

    function calculateLevel(uint256 _amount)
        internal
        view
        returns (Levels level)
    {
        if (_amount > 0 && _amount < 100) {
            return Levels.Iron;
        } else if (
            _amount >= thresholds[Levels.Bronze] &&
            _amount < thresholds[Levels.Silver]
        ) {
            return Levels.Bronze;
        } else if (
            _amount >= thresholds[Levels.Silver] &&
            _amount < thresholds[Levels.Gold]
        ) {
            return Levels.Silver;
        } else if (
            _amount >= thresholds[Levels.Gold] &&
            _amount < thresholds[Levels.Platinum]
        ) {
            return Levels.Gold;
        } else if (_amount >= thresholds[Levels.Platinum]) {
            return Levels.Platinum;
        }
    }

    function calculateReward(Staker memory staker)
        internal
        view
        returns (uint256)
    {
        return
            (staker.amount *
                levelReward[calculateLevel(staker.amount)] *
                (block.timestamp - staker.lastCollectTimestamp)) /
            (100 * 365 * 86400);
    }

    function _collectReward(bool is_redeposit) private returns (uint256) {
        Staker storage staker = stakers[msg.sender];
        if (staker.lastCollectTimestamp == 0) {
            staker.lastCollectTimestamp = block.timestamp;
            return 0;
        }
        uint256 reward = calculateReward(staker);
        if (is_redeposit) {
            staker.amount += reward;
        } else {
            stakedToken.transfer(msg.sender, reward);
        }
        staker.lastCollectTimestamp = block.timestamp;
        return reward;
    }
}

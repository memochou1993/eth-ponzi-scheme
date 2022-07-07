// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {
    address private _owner;
    uint256 constant REWARD_RATE = 2920;
    uint256 public stakeholderCount;
    mapping(address => Stakeholder) public stakeholders;

    struct Stakeholder {
        address addr;
        Stake[] stakes;
    }

    struct Stake {
        uint256 amount;
        uint256 claimed;
        uint256 createdAt;
    }

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyStakeholder() {
        require(isStakeholder(msg.sender), "Staking: caller is not the stakeholder");
        _;
    }

    function contractBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function stakesOf(address _stakeholder)
        external
        view
        onlyStakeholder
        returns (Stake[] memory)
    {
        return stakeholders[_stakeholder].stakes;
    }

    function isStakeholder(address _stakeholder)
        public
        view
        returns (bool)
    {
        return stakeholders[_stakeholder].addr != address(0);
    }

    function stake()
        public
        payable
        nonReentrant
    {
        if (!isStakeholder(msg.sender)) {
            stakeholders[msg.sender].addr = msg.sender;
            stakeholderCount++;
        }
        uint256 _fee = calculateFee(msg.value);
        uint256 _amount = msg.value - _fee;
        uint256 _createdAt = block.timestamp;
        stakeholders[msg.sender].stakes.push(Stake({
            amount: _amount,
            claimed: 0,
            createdAt: _createdAt
        }));
        payable(_owner).transfer(_fee);
    }

    function claim()
        public
        payable
        nonReentrant
        onlyStakeholder
    {
        uint256 _totalRewards;
        uint256 _totalFees;
        for (uint256 i = 0; i < stakeholders[msg.sender].stakes.length; i++) {
            uint256 _reward = calculateReward(stakeholders[msg.sender].stakes[i]);
            uint256 _fee = calculateFee(_reward);
            stakeholders[msg.sender].stakes[i].claimed += _reward - _fee;
            _totalRewards += _reward;
            _totalFees += _fee;
        }
        uint256 _amount = _totalRewards - _totalFees;
        payable(_owner).transfer(_totalFees);
        payable(msg.sender).transfer(_amount);
    }

    function calculateReward(Stake memory _stake)
        private
        view
        returns (uint256)
    {
        return (block.timestamp - _stake.createdAt) * _stake.amount * REWARD_RATE / 100 / 365 days - _stake.claimed;
    }

    function calculateFee(uint256 _amount)
        private
        pure
        returns (uint256)
    {
        return _amount * 3 / 100;
    }
}

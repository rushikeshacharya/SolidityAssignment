// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    struct Deposit {
        uint256 amount;
        uint256 time;
    }

    event AmountDeposited(address userAddress, Deposit userDetails);
    event AmountWithdrawn(address userAddress, uint256 amount);

    bool public reentrancyLock;
    mapping(address => Deposit[]) private userBalances;
    mapping(address => uint256) private totalAmount;

    function deposit() external payable {
        require(msg.value > 0, "Invalid amount");
        require(!reentrancyLock);
        userBalances[msg.sender].push(
            Deposit({amount: msg.value, time: block.timestamp})
        );
        totalAmount[msg.sender] += msg.value;
        reentrancyLock = false;
        emit AmountDeposited(
            msg.sender,
            Deposit({amount: msg.value, time: block.timestamp})
        );
    }

    function withdraw(uint256 amount) external {
        require(amount <= totalAmount[msg.sender], "Insufficient amount");
        require(amount > 0, "No ether to withdraw");
        require(!reentrancyLock);

        Deposit[] storage temp = userBalances[msg.sender];
        uint256 availableWithdrwalAmount;
        for (uint256 i = 0; i < temp.length; i++) {
            if (
                temp[i].amount >= amount &&
                block.timestamp > temp[i].time + 30 seconds
            ) {
                temp[i].amount -= amount;
                totalAmount[msg.sender] -= amount;
                availableWithdrwalAmount += amount;

                if (temp[i].amount == 0) {
                    delete temp[i];
                }
            }

            if (availableWithdrwalAmount == amount) {
                break;
            }
        }

        require(
            availableWithdrwalAmount == amount,
            "Withdrawal not allowed yet"
        );

        payable(msg.sender).transfer(amount);
        reentrancyLock = false;
        emit AmountWithdrawn(msg.sender, amount);
    }

    function getDeposits() external view returns (Deposit[] memory) {
        return userBalances[msg.sender];
    }

    receive() external payable {
        this.deposit();
    }
}

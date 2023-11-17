// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

interface IFortuneTeller {
    function seekFortune() external payable;
}

contract FortuneSeeker is AutomationCompatibleInterface {
    event InsufficientFunds(uint256 balance);
    event ReceivedFunding(uint256 amount);

    address public owner;
    // Target contract that is monitored.
    address public fortuneTeller;

    string public fortune;

    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint256 public immutable interval; // Seconds
    uint256 public lastTimeStamp; // Block timestamp

    modifier OnlyOwner() {
        require(owner == msg.sender, "Caller not owner");
        _;
    }

    constructor(address _fortuneTeller, uint256 updateInterval) {
        fortuneTeller = _fortuneTeller;
        lastTimeStamp = block.timestamp;
        interval = updateInterval;
        owner = msg.sender;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool intervalExceeded = (block.timestamp - lastTimeStamp) > interval;
        bool sufficientBalance = address(this).balance >= 1 ether;
        upkeepNeeded = intervalExceeded && sufficientBalance;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
        //We highly recommend revalidating the upkeep in the performUpkeep function
        bool intervalExceeded = (block.timestamp - lastTimeStamp) > interval;
        bool sufficientBalance = address(this).balance >= 1 ether;
        bool upkeepNeeded = intervalExceeded && sufficientBalance;

        require(upkeepNeeded, "Upkeep conditions not met");

        // Perform upkeep actions.
        lastTimeStamp = block.timestamp;
        seekFortune();
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBalance() public payable OnlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether in withdraw");
    }

    function seekFortune() public {
        if (address(this).balance < 1 ether) {
            emit InsufficientFunds(address(this).balance);
            revert("Not enough balance to call FortuneTeller");
        }

        IFortuneTeller teller = IFortuneTeller(fortuneTeller);
        teller.seekFortune{value: 0.001 ether}();
    }

    function fulfillFortune(string memory _fortune) external {
        fortune = _fortune;
    }

    receive() external payable {
        emit ReceivedFunding(msg.value);
    }
}

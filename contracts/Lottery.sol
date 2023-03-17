// Raffle

// Enter the lottery (paying some amount)
// Pick a random winner (verifiably random)
// winner to be selected every X minutes -> completly automated

// Chainlink Oracle -> Randomness, Automated Execution (Chainlink Keepers)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
error Raffle__RaffleNotOpen();
error Raffle__TransferFailed();
error Raffle__SendMoreToEnterRaffle();


/** @title A raffle Contract
 * @author David Raigoza from Patrick Collins
 * @notice This contract is for creating a untamperable decentralized 
 * @dev This implements Chainlink VRF v2 and chainlink keepers
 *  */ 
 
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* State Variables*/
    enum RaffleState{
        OPEN,
        CALCULATING
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee; 
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    RaffleState private s_raffleState;

   
   
    
   
    /*events*/
    event RestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed winner);
    
    constructor(
        address vrfCoodinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, 
        uint256 interval,
        uint256 entranceFee, 
        uint32 callbackGasLimit
       ) VRFConsumerBaseV2(vrfCoodinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoodinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;

    }

    function enterRaffle() public payable {
        //require msg.value > i_entranceFee
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /** 
     * @dev this is the function that Chainlink automation keeps
     */

    function checkUpkeep(
        bytes memory /*checkdata*/
        ) 
        public 
        view 
        override 
        returns (
            bool upkeepNeeded, 
            bytes memory /* performData*/
            )
        {
            bool isOpen = (RaffleState.OPEN == s_raffleState);
            bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
            bool hasPlayers = s_players.length > 0;
            bool hasBalance = address(this).balance > 0;
            upkeepNeeded = (timePassed && isOpen && hasPlayers && hasBalance);
            return (upkeepNeeded, "0x0");
        }

    // function pickRandomWinner(){}
    function performUpkeep(
        bytes calldata /* performData*/) 
        external
        override {
           (bool upkeepNeeded, ) = checkUpkeep(""); 
           if(!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
            address(this).balance,
            s_players.length, 
            uint256(s_raffleState));
           }
           s_raffleState = RaffleState.CALCULATING;
           uint256 requestId = 
            i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gaslane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
        ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
           s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");

        if(!success){
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View / Pure functions */

  function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

       function getNumWords() public pure returns(uint256){
        return NUM_WORDS;
    }

       function getRequestConfrimations() public pure returns(uint256){
        return REQUEST_CONFIRMATIONS;
    }

       function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

        function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

        function getLatestTimeStamp() public view returns(uint256){
        return s_lastTimeStamp;
    }

        function getInterval() public view returns(uint256) {
            return i_interval;
        }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }


    function getNumberOfPlayers() public view returns(uint256){
        return s_players.length;
    }
 
}

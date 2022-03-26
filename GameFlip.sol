// SPDX-License-Identifier: IIT BHU Varanasi
pragma solidity >=0.7.0 <0.9.0;

contract CoinFlip {

    address private owner;
    event OwnerSet(address indexed, address indexed newOwner);

    // modifier to check if the call is from the owner
    modifier isOwner {
        require(msg.sender == owner, "Invoker is not Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    //To avoid multiple mappings using a structure instead to store all the values for every user
    struct User {
        uint balance;         // Current Balance of the user
        uint betAmount;       // Betted amount in the ongoing game
        bool betStatus;       // True if betted, false otherwise
        uint betChoice;       // 0 --> Head and 1 --> Tail
        bool prevUser;         // True if it's a new user, false otherwise
    }

    event Winner(address winnerAddress, uint winAmount);

    //Creating an array to store the participants of the game
    address[] usersBetted;

    //Mapping to store structure of every user
    mapping(address => User) public users;

    //Utility function to start bet
    function placeBet(uint _betchoice, uint _betAmount) public {

        //IF its a new user then reward them with 100 points free to start the game
        if(users[msg.sender].prevUser == false)
        {
            users[msg.sender].balance = 100;
            users[msg.sender].prevUser = true;
        }

        // Betted amount must be less than or equal to the user's balance
        require(_betAmount <= users[msg.sender].balance, "Sorry! Low balance ;(");

        //If the user have an already ongoing bet, restrict them to place another one
        require(users[msg.sender].betStatus == false, "You already have an Ongoing Bet :|");

        //Set user's values
        users[msg.sender].betAmount = _betAmount;
        users[msg.sender].balance -= _betAmount;
        users[msg.sender].betStatus = true;
        users[msg.sender].betChoice = _betchoice;
        usersBetted.push(msg.sender);
    }

    function rewardBets() public isOwner { 
        // Can be rewarded only by the Owner
        uint256 winChoice = uint256(_vrf()) % 2;

        //Iterate over the array of participants and evaluate their bets
        for(uint i = 0; i < usersBetted.length; i++)
        {
            evaluateBets(usersBetted[i], winChoice);
        }
        delete usersBetted;
    }

    function evaluateBets(address _userAddress, uint _winChoice) internal {
        //If users bet turned out to be a Win
        if(users[_userAddress].betChoice == _winChoice) {
            users[_userAddress].balance += (2 * users[_userAddress].betAmount);
            emit Winner(_userAddress, (2 * users[_userAddress].betAmount));
        }

        //Set bet status of that user to false again
        users[_userAddress].betStatus = false;
    }

    //Function to generate random number (Harmony VRF)
    function _vrf() private view returns (bytes32 result) {
        uint[1] memory bn;
        bn[0] = block.number;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
                invalid()
            }
            result := mload(memPtr)
        }
    }

}
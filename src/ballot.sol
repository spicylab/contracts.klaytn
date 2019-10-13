pragma solidity >=0.4.22 <0.6.0;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Ballot is owned {

    struct Voter {
        uint weight;
        bool voted;
        uint8 vote;
        address delegate;

        // 0 is used for checking existence(voted or not)
        mapping(string => MobVoteHistory) mobVoteHistory;
        mapping(string => ItemVoteHistory) itemVoteHistory;
    }
    struct MobVoteHistory {
        uint8 strength;
        uint8 rewards;
    }
    struct ItemVoteHistory {
        uint8 strength;
    }
    struct MobVote {
        mapping(uint8 => uint256) strength;
        mapping(uint8 => uint256) rewards;
    }
    struct ItemVote {
        mapping(uint8 => uint256) strength;
    }

    address owner;
    mapping(address => Voter) voters;
    mapping(string => MobVote) mobVotes;
    mapping(string => ItemVote) itemVotes;
    
    constructor() public {
        owner = msg.sender;
    }

    function voteMob(string memory vid, uint8 strength, uint8 rewards) public {
        if (strength > 12) return;
        if (rewards > 12) return;
        
        MobVote storage q = mobVotes[vid];
        Voter storage voter = voters[msg.sender];

        // if already placed a vote
        if (voter.mobVoteHistory[vid].strength != 0) {
            q.strength[voter.mobVoteHistory[vid].strength] -= 1;
            q.rewards[voter.mobVoteHistory[vid].rewards] -= 1;
        }

        q.strength[strength + 1] += 1;
        q.rewards[rewards + 1] += 1;
    }
    function voteItem(string memory vid, uint8 strength) public {
        if (strength > 12) return;
        
        ItemVote storage q = itemVotes[vid];
        Voter storage voter = voters[msg.sender];

        // if already placed a vote
        if (voter.itemVoteHistory[vid].strength != 0) {
            q.strength[voter.itemVoteHistory[vid].strength] -= 1;
        }

        q.strength[strength + 1] += 1;
    }

    function getTotalVotesMob(string memory vid) public view returns (uint256 voteCount) {
        mapping(uint8 => uint256) storage proposals = mobVotes[vid].strength;
        uint256 sum = 0;
        
        for (uint8 prop = 1; prop < 12; prop++)
            sum += proposals[prop];
        
        return sum;
    }
    function getTotalVotesItem(string memory vid) public view returns (uint256 voteCount) {
        mapping(uint8 => uint256) storage proposals = itemVotes[vid].strength;
        uint256 sum = 0;
        
        for (uint8 prop = 1; prop < 12; prop++)
            sum += proposals[prop];
        
        return sum;
    }

    function getResultMob(string memory vid) public view returns (uint8 strength, uint8 rewards, uint256 totalVotes) {
        MobVote storage proposals = mobVotes[vid];
        
        totalVotes = getTotalVotesMob(vid);
        
        uint256 strengthWinningVoteCount = 0;
        uint256 rewardsWinningVoteCount = 0;
        for (uint8 prop = 1; prop < 12; prop++) {
            if (proposals.strength[prop] > strengthWinningVoteCount) {
                strengthWinningVoteCount = proposals.strength[prop];
                strength = prop - 1;
            }
            if (proposals.rewards[prop] > rewardsWinningVoteCount) {
                rewardsWinningVoteCount = proposals.rewards[prop];
                rewards = prop - 1;
            }
        }
    }
    function getResultItem(string memory vid) public view returns (uint8 strength, uint256 totalVotes) {
        ItemVote storage proposals = itemVotes[vid];
        
        totalVotes = getTotalVotesItem(vid);
        
        uint256 strengthWinningVoteCount = 0;
        for (uint8 prop = 1; prop < 12; prop++) {
            if (proposals.strength[prop] > strengthWinningVoteCount) {
                strengthWinningVoteCount = proposals.strength[prop];
                strength = prop - 1;
            }
        }
    }
}

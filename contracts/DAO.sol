// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IdaoContract {
        function balanceOf(address, uint256) external view returns (uint256);
}

contract DAO {
    uint public id;
    address public owner;
    uint256 nextProposal;
    address[] public members;
    // string public category;
    uint256 public memberLimit;
    uint256 public memberCount=0;
    uint256[] public validTokens;
    IdaoContract daoContract;
    
    // Events

    // -------------

    receive() external payable {}
    fallback() external payable {}

    modifier guard() {
        require(msg.sender == owner, "You are not the owner");
        require(memberLimit < (2**16), "Member Limit Exceeded");
        _;
    }

    constructor(uint _id, address _owner) payable {
        id = _id;
        owner = _owner;
        members.push(_owner);
        memberLimit ++;
        daoContract = IdaoContract('Contract address of the NFT collection');
        //-------------------------0x2953399124F0cBB46d2CbACD8A89cF0599974963
        validTokens = ['Enter valid tokens here'];
    }

    // Proposals structure

    struct proposal{
        uint256 id;
        string question;
        bool[2] options;
        address to;           //
        uint256 value;        //
        uint deadline;
        bool exists;
        bool[] answers;
        uint answerCount;
        mapping(address => bool) voteStatus;
        uint256 maxVotes;
        bool countConducted;
    }

    // Making all the proposal public

    mapping(uint256 => proposal) public Proposals;

    // Events created so that moralis can hear it and show us results and data

    event proposalCreated(
        uint256 id,
        string question,
        string[] options,
        address to,     //
        uint256 value,  //
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        address voter,
        uint256 proposalId,
        uint8 response
    );

    event proposalStatus(
        uint256 id,
        string question,
        uint[] answerCount,
        string[] answers
    );

    // Check if the address holds any NFT from the valid NFT array list

    function checkProposalEligibility(address _memberid) private view returns (bool){
        address[] memory membersTemp = members;
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_memberid, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    // Check if the address is eligible for vote

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool){
        address[] memory membersTemp = members;
        for (uint256 i = 0; i < membersTemp.length; i++) {
            if (membersTemp[i] == _voter) {
            return true;
            }
        }
        return false;
    }

    // Creating a proposal

    function createProposal(string memory _question, string[] memory _options, address _receiver, uint256 _amount, uint256 _deadline) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");
        // Creating a new instance of proposal (newProposal) struct and storing it in storage
        address[] memory membersTemp = members;

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.question = _question;
        newProposal.options[0] = true;
        newProposal.options[1] = false;
        newProposal.to = _receiver;
        newProposal.value = _amount;
        newProposal.deadline = block.number + _deadline;
        newProposal.exists = true;
        newProposal.maxVotes = membersTemp.length;
        newProposal.answerCount = 0;
        newProposal.countConducted = false;

        /*
        struct proposal{
        uint256 id;
        string question;
        bool[] options;
        address to;           //
        uint256 value;        //
        uint deadline;
        bool exists;
        uint256 maxVotes;
        bool[] answers;
        uint answerCount;
        mapping(address => bool) voteStatus;
        bool countConducted;
    }
        */

        // Emiting event
        emit proposalCreated(nextProposal, _question, _options, _receiver, _amount, membersTemp.length, msg.sender);

        nextProposal++;
    }

     // Casting response

    function responseOnProposal(uint256 _id, uint8 _response , string memory _textResponse) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(!Proposals[_id].countConducted , "The proposal has already concluded with final count" );
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");//edit

        uint voteWeight;
        voteWeight=checkProposalEligibility(msg.sender) + 1;

        proposal storage p = Proposals[_id];

        if(p.questionType == 1){
            p.answerCount=[0,0];
            p.answerCount[_response] += voteWeight;
        }

        else if(p.questionType == 2){
            p.answerCount=[0,0,0,0];
            p.answerCount[_response - 1] += voteWeight;
        }
        else{
            p.answers.push(_textResponse);
        }
        // Change vote status to true to avoid multiple votes from same address
        p.voteStatus[msg.sender] = true;

        emit newVote( msg.sender, _id, _response,_textResponse , voteWeight);

        if(p.typea == true){
                emit proposalStatus(_id,p.questionType, p.answerCount, p.answers);
        }
    }

    // Counting the counts

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(!Proposals[_id].countConducted , "The proposal has already concluded with final count" );
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");

        proposal storage p = Proposals[_id];
        emit proposalStatus(_id,p.questionType, p.answerCount, p.answers);
    }



    //
function finalVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "The proposal has already concluded with final count");    

        proposal storage p = Proposals[_id];
        p.countConducted = true;

        emit proposalStatus(_id,p.questionType, p.answerCount, p.answers);
    }
    //


    // Check if the address holds any NFT from the valid NFT array list

    function setMemberLimit(uint64 _memberLimit) public guard {
        memberLimit = _memberLimit;
    }

    function getMemberLimit() public view returns(uint) {
        return memberLimit;
    }

    function addMember(address _member) private {
        require(memberCount < memberLimit, "Member limit exceeded");
        members.push(_member);

        memberCount ++;
    }

    function getMembers() public view returns(address[] memory) {
        return members;
    }
}

contract DAOFactory {
    DAO[] public daos;

    struct MyDaos {
        address daoAddress;
    }

    mapping (address => MyDaos[]) public myDaos;

    function createDao(uint _id) external {
        DAO dao = new DAO(_id, msg.sender);

        myDaos[msg.sender].push(MyDaos(address(dao)));

        daos.push(dao);
    }

    function showMyDaos() public view returns(MyDaos[] memory) {
        return myDaos[msg.sender];
    }
    
    function numberOfMyDaos() public view returns(uint) {
        uint myDaoCount = myDaos[msg.sender].length;

        return myDaoCount;
    }

    function showAllDaos() public view returns(DAO[] memory) {
        return daos;
    }

    function numberOfAllDaos() public view returns(uint) {
        uint allDaoCount = daos.length;
        return allDaoCount;
    }
}
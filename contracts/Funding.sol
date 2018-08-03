pragma solidity ^0.4.17;

contract Funding{
    address public manager;
    string public projectName;
    uint public supportMoney;
    uint public endTime;
    uint public goalMoney;
    address[] public players;
    mapping(address=>bool) playersMap;
    Request[] public requests;

    struct Request{
        string description;
        uint money;
        address shopAddress;
        bool complete;
        uint votecount;
        mapping(address=>bool) voteMap;
    }

    function createRequest(string _description,uint _money, address _shopAddress) public onManagerCanCall{
        Request memory request=Request({
            description:_description,
            money:_money,
            shopAddress:_shopAddress,
            complete:false,
            votecount:0
            });
        requests.push(request);
    }

    function approveRequest(uint id) public {
        Request storage request=requests[id];
        require(playersMap[msg.sender]);
        require(!request.voteMap[msg.sender]);
        request.votecount ++;
        request.voteMap[msg.sender]=true;
    }

    function finalizeRequest(uint id) public onManagerCanCall{
        Request storage request=requests[id];
        require(!request.complete);
        require(request.votecount *2 >players.length);
        require(this.balance>request.money);
        request.shopAddress.transfer(request.money);
        request.complete=true;
    }

    function Funding(string _projectName, uint _supportMoney, uint _goalMoney) public{
        manager=msg.sender;
        projectName=_projectName;
        supportMoney=_supportMoney;
        goalMoney=_goalMoney;
        endTime=now + 4 weeks;
    }

    function support() public payable{
        require(msg.value==supportMoney);
        players.push(msg.sender);
        playersMap[msg.sender]=true;
    }

    function getPlayersCount() public view returns(uint){
        return players.length;
    }

    function getPlayers() public view returns(address[]){
        return players;
    }

    function getTotalBalance() public view returns(uint){
        return this.balance;
    }

    function getRemainDays() public view returns(uint){
        return (endTime - now )/60/60/24;
    }

    modifier onManagerCanCall(){
        require(msg.sender==manager);
        _;
    }
}


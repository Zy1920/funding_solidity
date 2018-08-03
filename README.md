## 一个基于以太坊智能合约的众筹项目



### 成员变量设计

| 名称         | 数据类型  | 说明                                           |
| :----------- | :-------- | :--------------------------------------------- |
| manager      | address   | 众筹发起人地址(众筹发起人)                     |
| projectName  | string    | 项目名称                                       |
| supportMoney | uint      | 众筹参与人需要付的钱                           |
| endTime      | uint      | 默认众筹结束的时间,为众筹发起后的一个月        |
| goalMoney    | uint      | 目标募集的资金(endTime后,达不到目标则众筹失败) |
| players      | address[] | 众筹参与人的数组                               |
| requests     | Request[] | 付款请求申请的数组                             |

### 函数设计

| 函数名称        | 函数说明                                     |
| :-------------- | :------------------------------------------- |
| Funding         | 构造函数                                     |
| support         | 我要支持(需要付钱)                           |
| createRequest   | 付款申请函数,由众筹发起人调用                |
| approveRequest  | 付款批准函数, 由众筹参与人调用               |
| finalizeRequest | 众筹发起人调用, 可以调用完成付款             |
| moneyBack       | 退钱函数, 由众筹发起人调用(众筹未成功时调用) |



### 代码实现

```solidity
pragma solidity ^0.4.17;

contract Funding{
    //管理员地址
    address public manager;
    //众筹项目名称
    string public projectName;
    //众筹每份支持的钱
    uint public supportMoney;
    //众筹结束的时间
    uint public endTime;
    //众筹的目标
    uint public goalMoney;
    //参与众筹的人
    address[] public players;
    //参与众筹的人的map （地址，是否有投票权利）
    mapping(address=>bool) playersMap;
    //付款请求申请的数组(由众筹发起人申请)
    Request[] public requests;

    //付款请求的结构体
    struct Request{
        string description;//付款的描述
        uint money;//付款的金额
        address shopAddress;//收款人地址
        bool complete;//付款是否完成
        uint votecount;//投票的数量
        mapping(address=>bool) voteMap;//投票的map（投票人 是否已投票）
    }

    //manager发起付款请求的方法
    function createRequest(string _description,uint _money, address _shopAddress) public onManagerCanCall{
        //付款结构体初始化
        Request memory request=Request({
            description:_description,
            money:_money,
            shopAddress:_shopAddress,
            complete:false,
            votecount:0
            });
        //将当前的付款请求添加到付款请求的数组中
        requests.push(request);
    }

    //众筹参与者审核付款请求的方法
    function approveRequest(uint id) public {
        //根据id获得当前的付款请求
        Request storage request=requests[id];
        //要求当前的sender具有审核的权限
        require(playersMap[msg.sender]);
        //要求当前的sender还未参与投票
        require(!request.voteMap[msg.sender]);
        //满足条件后，对当前请求的投票数量做自增操作
        request.votecount ++;
        //同时修改当前sender的投票状态为true
        request.voteMap[msg.sender]=true;
    }

    //众筹发起人调用，用于请求通过后的付款操作
    function finalizeRequest(uint id) public onManagerCanCall{
        Request storage request=requests[id];
        //要求当前的请求处于尚未完成的状态
        require(!request.complete);
        //要求当前的请求 赞同者超过总众筹人员的一半
        require(request.votecount *2 >players.length);
        //要求众筹余额大于当前请求所需要花费的金额
        require(this.balance>request.money);
        //转账给当前请求的收款地址
        request.shopAddress.transfer(request.money);
        //修改当前请求的完成状态为true
        request.complete=true;
    }

    //构造函数 完成项目名称 目标金额  众筹金额 当前时间 众筹发起人的初始化
    function Funding(string _projectName, uint _supportMoney, uint _goalMoney) public{
        manager=msg.sender;
        projectName=_projectName;
        supportMoney=_supportMoney;
        goalMoney=_goalMoney;
        endTime=now + 4 weeks;
    }

    //众筹参与者的支持方法
    function support() public payable{
        //要求参与者投入的金额等于所需要的单份众筹金额
        require(msg.value==supportMoney);
        //将当前参与者添加到数组中
        players.push(msg.sender);
        //修改参与者map状态为true
        playersMap[msg.sender]=true;
    }

    //获取众筹参与者的数量
    function getPlayersCount() public view returns(uint){
        return players.length;
    }

    //获取所有的众筹参与者
    function getPlayers() public view returns(address[]){
        return players;
    }

    //获取当前众筹到的金额
    function getTotalBalance() public view returns(uint){
        return this.balance;
    }

    //获取众筹剩余时间
    function getRemainDays() public view returns(uint){
        return (endTime - now )/60/60/24;
    }

    //模板 仅manager可调用
    modifier onManagerCanCall(){
        require(msg.sender==manager);
        _;
    }
}

```


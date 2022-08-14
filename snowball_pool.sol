/**
 *Submitted for verification at BscScan.com on 2022-02-16
*/

pragma solidity ^0.8.6;

import "./libs/ReentrancyGuard.sol";
import "./libs/Ownable.sol";
import "./libs/SafeMath.sol";
import "./libs/SafeERC20.sol";
import "./libs/IERC20.sol";
import "./libs/TransferHelp.sol";

import "./Snowball.sol";

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
// import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// SPDX-License-Identifier: Unlicensed

contract SNOWBPOOL is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 _snowToken;

    address public _destroyAddress;

    address[] public repayList;
    struct ReturnRec {
		uint256 returnAmount;  //偿还母币数量
		uint256 returnValue; //偿还价值
        uint256 returnTime; // 偿还时间
    }

    struct RepayOrder {
        uint256 payedOrderId;  //订单id，repayList数组索引
		uint256 payedAmount;  //投入母币数量
		uint256 payedValue; //投入的价值
        uint256 payTime; // 投入时间
        uint256 restReleaseValue; //剩余需要偿还的价值，2倍出局依赖此参数
        bool orderFinished; //订单是否结束
    }

    struct FomoPayoutRecord {
        uint256 payoutTime;  //fomo爆池支付母币时间
        uint256 payoutTotalAmount;  //fomo爆池支付母币总数量
        uint256 payoutTotalValue;   //fomo爆池支付总价值
		address[] receiveAddressList;  //接收fomo爆池分配母币地址列表
    }

    mapping(uint256=>ReturnRec[]) public returnList;   //订单的偿还列表数组
    mapping(address => RepayOrder[]) public repayOrder; //用户的投资订单数组
    uint256 public repayFront;  //偿还队列头指针
    uint256 public repayRear;   //偿还队列尾指针
    uint256 public repayListLength;  //偿还队列长度
    
    uint256 public payedTotalAmount;    //总投入母币数量
    uint256 public payedTotalValue;  //总投入价值
    uint256 public incomeTotalAmount;   //总收入母币数量
    uint256 public incomeTotalValue;    //总收入母币价值
    uint256 public repayTotalValue;  //总偿还价值
    uint256 public repayTotalAmount;    //总偿还母币数量
    
    uint256 public fomoIncomeTotalAmount;   //fomo池总收入数量
    uint256 public fomoIncomeTotalValue;    //fomo池总收入价值
    uint256 public fomoPayoutTotalAmount;   //fomo池总支付数量
    uint256 public fomoPayoutTotalValue;    //fomo池总支付价值
    FomoPayoutRecord[]  fomoPayoutList;     //fomo池支出记录列表

    uint256 lastRepayOrderTime;

    event NewRepayOrder(address indexed user,uint256 orderid, uint256 amount, uint256 value);
    event NewReturnOrder(address indexed user, uint256 orderid, uint256 amount, uint256 value);
    event NewFomoBurst(uint256 indexed orderid, bool istimeburst, uint256 amount, uint256 value, address[] receivelist);

    //操作失败事件
    //failid:   1   偿还过程中参数错误
    //          2   fomo池需要爆池的数量大于本合约里的余额

    event NewFailEvent(uint failid);

    bool inburst;

    //防止重入
    modifier lockTheBurst {
        inburst = true;
        _;
        inburst = false;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    //所有的互助订单地址列表，包括已出局的，由repayFront指针指向当前第一个订单，repayRear指向最后一个订单
    //与用户的互助订单记录组成先进先出队列，fomo池爆破时需要根据repayRear指针和repayListLength长度两个变量
    //找到最后10个订单
    function getRepayList() external view returns(address[] memory,uint256,uint256,uint256,uint256) {
        address from = _msgSender();
        
        uint256 _repayFront = repayFront;
        uint256 _repayRear = repayRear;
        uint256 _repayListLength = repayListLength;
        uint256 _myRank = 0;

        if (repayListLength>0){
            for (uint256 i = repayFront;i<=repayRear;i++){
                if (repayList[i]==from){
                    _myRank = i;
                }
            }
        }

        return (repayList,_repayFront,_repayRear,_repayListLength,_myRank);
    }

    function newReturnOrder(uint256 _amount,uint256 _value) nonReentrant public returns(bool){
        address from = _msgSender();
        bool isok;
        isok = _newReturnOrder(from, _amount, _value);
        return isok;
    }
    
    function _newReturnOrder(address from,uint256 _amount,uint256 _value) internal returns(bool){
        require(from == address(_snowToken) || from == address(this), "only invoked by sonwtoken contract");
        
        if (_amount == 0 || _value == 0){
            emit NewFailEvent(1);
            return false;
        } 

        bool isok = false;
        if (repayListLength==0){return isok;}
        
        address curReturnAddress;
        uint256 usrLastOrderIdx;
        uint256 currestValue;
        bool isfinished;
        uint256 _restvalue = _value;
        uint256 _restamount = _amount;
        uint256 _curamount;
        uint256 _curprice;
        if (_amount>=_value){
            _curprice = _amount.div(_value);
        }else{
            _curprice = _value.div(_amount);
        }

        while(repayListLength>0){
            curReturnAddress = repayList[repayFront];
            require(repayOrder[curReturnAddress].length>0,"internal error");
            usrLastOrderIdx = repayOrder[curReturnAddress].length-1;
            // RepayOrder memory curRepayOrder = repayOrder[curReturnAddress][usrLastOrderIdx];
            currestValue = repayOrder[curReturnAddress][usrLastOrderIdx].restReleaseValue;
            isfinished = repayOrder[curReturnAddress][usrLastOrderIdx].orderFinished;
            require(repayOrder[curReturnAddress][usrLastOrderIdx].payedOrderId==repayFront, "internal error");
            require(!isfinished && currestValue>0,"internal error");

            isok = true;
            if (currestValue>_restvalue){
                repayOrder[curReturnAddress][usrLastOrderIdx].restReleaseValue = currestValue.sub(_restvalue);
                ReturnRec memory newreturnrec = ReturnRec({
                    returnAmount: _restamount,
                    returnValue: _restvalue,
                    returnTime: block.timestamp
                });
                returnList[repayFront].push(newreturnrec);
                TransferHelper.safeTransfer(address(_snowToken), curReturnAddress, _restamount);
                emit NewReturnOrder(curReturnAddress, repayFront, _restamount, _restvalue);

                repayTotalAmount = repayTotalAmount.add(_restamount);
                _restvalue = 0;
                _restamount = 0;
                break;
            }else{
                _restvalue = _restvalue.sub(currestValue);
                
                if (_amount>=_value){
                    _curamount = currestValue.mul(_curprice);
                }else{
                    _curamount = currestValue.div(_curprice);
                }
                _restamount = _restamount.sub(_curamount);

                repayOrder[curReturnAddress][usrLastOrderIdx].restReleaseValue = 0;
                repayOrder[curReturnAddress][usrLastOrderIdx].orderFinished = true;

                ReturnRec memory newreturnrec = ReturnRec({
                    returnAmount: _curamount,
                    returnValue: currestValue,
                    returnTime: block.timestamp
                });
                returnList[repayFront].push(newreturnrec);
                if (repayFront<repayRear){
                    repayFront = repayFront.add(1);
                }
                
                repayListLength = repayListLength.sub(1);

                TransferHelper.safeTransfer(address(_snowToken), curReturnAddress, _curamount);
                emit NewReturnOrder(curReturnAddress, repayFront, _curamount, currestValue);

                repayTotalAmount = repayTotalAmount.add(_curamount);

                if (_restvalue==0){
                    break;
                }
            }
        }
        
        repayTotalValue = repayTotalValue.add(_value.sub(_restvalue));

        isok = true;
        return isok;
    }
    
    
    function newRepayOrder(address _account,uint256 _amount,uint256 _value) nonReentrant external returns(bool){
        address from = _msgSender();
        require(from == address(_snowToken) && _value>0, "only invoked by sonwtoken contract");
        bool isok = false;
        require(_value>=100*10**18 && _value<=1000*10**18, "throw in value error");
        bool inlist = false;
        
        if (repayListLength>0){
            for (uint256 i=repayFront;i<repayList.length;i++){
                if (repayList[i] == _account) {
                    inlist = true;
                    break;
                }
            }
            require(!inlist, "should wait for your previous order finished");
        }

        uint256 thislastorderidx = repayOrder[_account].length;
        if (thislastorderidx>0){
            thislastorderidx=thislastorderidx-1;
            //该用户之前的最后订单必须已完结
            require(repayOrder[_account][thislastorderidx].orderFinished,"interal error");
        }

        if (repayList[repayFront] == _destroyAddress){  //初始化的状态
            require(repayRear==0, "internal error");
            repayList.push(_account);
            repayFront = repayFront.add(1);
            repayRear = repayRear.add(1);
            repayListLength = 1;

            RepayOrder memory newOrder = RepayOrder({
                payedOrderId: repayRear, 
                payedAmount:  _amount,
                payedValue:  _value,
                payTime:    block.timestamp,
                restReleaseValue:   _value.mul(2), 
                orderFinished: false
            });
            repayOrder[_account].push(newOrder);    //为用户的投入订单列表加记录
            
            payedTotalAmount = payedTotalAmount.add(_amount);
            payedTotalValue = payedTotalValue.add(_value);
            emit NewRepayOrder(_account, repayRear, _amount, _value);
            
        }else{
           if (repayFront == repayRear){
                if (repayListLength==1){     //队列有一个订单没偿还完    
                    address lastaddress = repayList[repayRear];
                    repayList.push(_account);
                    repayRear = repayRear.add(1);
                    require(repayRear==(repayList.length-1), "internal error");

                    RepayOrder memory newOrder = RepayOrder({
                        payedOrderId: repayRear, 
                        payedAmount:  _amount,
                        payedValue:  _value,
                        payTime:    block.timestamp,
                        restReleaseValue:   _value.mul(2), 
                        orderFinished: false
                    });
                    repayOrder[_account].push(newOrder);    //为用户的投入订单列表加记录
                    
                    require(repayOrder[lastaddress].length>0, "internal error");
                    
                    //而他的当前排队订单应该是他自己投入订单数组的最后一个

                    payedTotalAmount = payedTotalAmount.add(_amount);
                    payedTotalValue = payedTotalValue.add(_value);
                    repayListLength = repayListLength.add(1); 
                    emit NewRepayOrder(_account, repayRear, _amount, _value);

                }else{  //都偿还完了，队列长度应该是0
                    require(repayListLength==0,"internal error");
                    repayList.push(_account);
                    repayFront = repayFront.add(1);
                    repayRear = repayRear.add(1);
                    repayListLength = 1;

                    RepayOrder memory newOrder = RepayOrder({
                        payedOrderId: repayRear, 
                        payedAmount:  _amount,
                        payedValue:  _value,
                        payTime:    block.timestamp,
                        restReleaseValue:   _value.mul(2), 
                        orderFinished: false
                    });
                    repayOrder[_account].push(newOrder);    //为用户的投入订单列表加记录
                    
                    payedTotalAmount = payedTotalAmount.add(_amount);
                    payedTotalValue = payedTotalValue.add(_value);
                    emit NewRepayOrder(_account, repayRear, _amount, _value);
                }
           }else{
                require(repayRear>repayFront, "internal error");
                address lastaddress = repayList[repayRear];
                repayList.push(_account);
                repayRear = repayRear.add(1);
                require(repayRear==(repayList.length-1),"internal error");  //确保队尾指针指向队列最后一个元素

                RepayOrder memory newOrder = RepayOrder({
                    payedOrderId: repayRear, 
                    payedAmount:  _amount,
                    payedValue:  _value,
                    payTime:    block.timestamp,
                    restReleaseValue:   _value.mul(2), 
                    orderFinished: false
                });
                
                repayOrder[_account].push(newOrder);    //为用户的投入订单列表加记录

                //上一个排队用户的订单数组长度必须大于0，既然有排队，那么必然有订单
                require(repayOrder[lastaddress].length>0, "internal error");
                //而他的当前排队订单应该是他自己投入订单数组的最后一个

                payedTotalAmount = payedTotalAmount.add(_amount);
                payedTotalValue = payedTotalValue.add(_value);
                repayListLength = repayListLength.add(1);
                emit NewRepayOrder(_account, repayRear, _amount, _value);
           }
        }

        //todo：要在母币合约中加入判断从上次投入互助池之后超过5小时没有新的投资互助池需要爆破fomo池
        
        // if (repayList[repayFront] != _account){
        //     _newReturnOrder(address(this), _amount.mul(3).div(10), _value.mul(3).div(10));
        // }
        
        lastRepayOrderTime = block.timestamp;
        isok = true;
        return isok;
    }
    
    //投入fomo池，不能阻塞
    function putinFomoPool(uint256 _amount,uint256 _value) nonReentrant external returns(bool){
        address from = _msgSender();
        require(from == address(_snowToken) && _value>0, "only invoked by sonwtoken contract");
        bool isok = false;
        
        if (_amount>0 && _value>0){
            fomoIncomeTotalAmount = fomoIncomeTotalAmount.add(_amount);
            fomoIncomeTotalValue = fomoIncomeTotalValue.add(_value);
            
            if (fomoIncomeTotalValue.sub(fomoPayoutTotalValue)>=3000*10**18){
                _burstFomoPool(address(this), false);
            }
            isok = true;
        }
        
        return isok;
    }

    //投入互助池，给母币合约调用，用来记录实际进入互助池的数量和价值，不能阻塞
    function putinRepayPool(uint256 _amount,uint256 _value) nonReentrant external returns(bool){
        address from = _msgSender();
        require(from == address(_snowToken) && _value>0, "only invoked by sonwtoken contract");
        bool isok = false;
        if (_amount>0 && _value>0){
            incomeTotalAmount = incomeTotalAmount.add(_amount);
            incomeTotalValue = incomeTotalValue.add(_value);
            isok = true;
        }
        
        return isok;
    }

    function burstFomoPool(bool _istimeburst) nonReentrant external returns(bool) {
        address from = _msgSender();
        bool isok = false;

        isok = _burstFomoPool(from, _istimeburst);

        return isok;
    }

    function _taketransfer(address token,address to,uint256 amount) lockTheBurst internal {
        TransferHelper.safeTransfer(token, to, amount);   
    }

    function _burstFomoPool(address _from,bool _istimeburst) internal returns(bool){
        if (inburst){return false;}
        require(_from == address(_snowToken) || _from == address(this), "only invoked by sonwtoken contract");
        bool isok = false;
        
        if (_istimeburst){
            //timeout burst
            if (repayList[repayRear] != _destroyAddress && repayListLength>0){
                address[] memory receivelist = new address[](1);
                uint256 burstAmount = fomoIncomeTotalAmount.sub(fomoPayoutTotalAmount);
                uint256 burstValue = fomoIncomeTotalValue.sub(fomoPayoutTotalValue);
                if (burstAmount > _snowToken.balanceOf(address(this))){
                    emit NewFailEvent(2);
                    return false;
                }
                receivelist[0] = repayList[repayRear];
                FomoPayoutRecord memory newfomopayoutrec = FomoPayoutRecord({
                    payoutTime: block.timestamp,
                    payoutTotalAmount: burstAmount,
                    payoutTotalValue: burstValue,
                    receiveAddressList: receivelist
                });

                lastRepayOrderTime = 0;
                fomoPayoutList.push(newfomopayoutrec);

                _taketransfer(address(_snowToken),repayList[repayRear],burstAmount);
                // TransferHelper.safeTransfer(address(_snowToken), repayList[repayRear], burstAmount);
                fomoPayoutTotalAmount = fomoPayoutTotalAmount.add(burstAmount);
                fomoPayoutTotalValue = fomoPayoutTotalValue.add(burstValue);

                emit NewFomoBurst(fomoPayoutList.length-1, _istimeburst, burstAmount, burstValue, receivelist);
                isok = true;
                
            }
        }else{
            //value burst
            if (repayList[repayRear] != _destroyAddress && repayListLength>0){
                uint256 payoutlistlength;
                if (repayListLength<10){
                    payoutlistlength = repayListLength;
                }else{
                    payoutlistlength = 10;
                }

                address[] memory receivelist = new address[](payoutlistlength);
                uint256 burstAmount = (fomoIncomeTotalAmount.sub(fomoPayoutTotalAmount)).div(2);
                uint256 burstValue = (fomoIncomeTotalValue.sub(fomoPayoutTotalValue)).div(2);
                
                if (burstAmount > _snowToken.balanceOf(address(this))){
                    emit NewFailEvent(2);
                    return false;
                }
                
                for (uint256 i=0;i<payoutlistlength-1;i++){
                    receivelist[i] = repayList[repayRear-i];
                    _taketransfer(address(_snowToken),repayList[repayRear-i],burstAmount.div(payoutlistlength));
                    // TransferHelper.safeTransfer(address(_snowToken), repayList[repayRear-i], burstAmount.div(payoutlistlength));
                }
                
                FomoPayoutRecord memory newfomopayoutrec = FomoPayoutRecord({
                    payoutTime: block.timestamp,
                    payoutTotalAmount: burstAmount,
                    payoutTotalValue: burstValue,
                    receiveAddressList: receivelist
                });

                fomoPayoutList.push(newfomopayoutrec);
                fomoPayoutTotalAmount = fomoPayoutTotalAmount.add(burstAmount);
                fomoPayoutTotalValue = fomoPayoutTotalValue.add(burstValue);
                
                emit NewFomoBurst(fomoPayoutList.length-1, _istimeburst, burstAmount, burstValue, receivelist);
                isok = true;
            }
        }
        return isok;
    }

    function setSnowToken(IERC20 _snowtoken) onlyOwner external {
        require(address(_snowtoken) != address(0) && isContract(address(_snowtoken)), "Error SnowToken address");
        _snowToken = _snowtoken;
    }
    
    //获取当前排队第一的地址
    function getRepayFrontAddress() external view returns(address) {
        if (repayListLength>0){
            return repayList[repayFront];
        }else{
            return _destroyAddress;
        }
    }
    
    //获取当前互助池实际数量和价值
    function getRepayPoolAmountValue() external view returns(uint256 amount,uint256 value) {
        amount = payedTotalAmount.mul(63).div(100);
        value  = payedTotalValue.mul(63).div(100);
        amount = amount.add(incomeTotalAmount);
        value = value.add(incomeTotalValue);
        return (amount,value);
    }

    //获取当前fomo池实际数量和价值
    function getFomoPoolAmountValue()  external view returns(uint256 amount,uint256 value) {
        amount = fomoIncomeTotalAmount.sub(fomoPayoutTotalAmount);
        value = fomoIncomeTotalValue.sub(fomoPayoutTotalValue);

        return (amount,value);
    }

    //获取fomo池爆破记录列表
    function getFomoPayoutRecList() external view returns(FomoPayoutRecord[] memory) {
        FomoPayoutRecord[] memory b = fomoPayoutList;

        return b;
    }

    //获取最后一次投入订单时间，用来判断是否超过5小时没投入订单要爆fomo池
    function getLastRepayOrderTime() external view returns(uint256) {
        return lastRepayOrderTime;
    }

    //获取用户投资互助池订单
    function getMyRepayOrder() external view returns(RepayOrder[] memory) {
        address from = _msgSender();
        RepayOrder[] memory b = repayOrder[from];

        return b;
    }

    //获取某个订单id的偿还记录列表
    function getReturnRec(uint256 orderid) external view returns(ReturnRec[] memory) {
        ReturnRec[] memory b = returnList[orderid];

        return b;
    }

    //合约owner取走合约中的bnb币
    function claimTokens() public onlyOwner {
        // (bool sent,bytes memory data) = _owner.call{value:address(this).balance}("");
        // require(sent,"Failed to send");
        payable(_owner).transfer(address(this).balance);
    }

    //从合约地址上取走其他代币
    function claimOtherTokens(address token,address to, uint256 amount) public onlyOwner returns(bool sent){
        require(to != address(this) && to != address(0), "Error target address");
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        if (token == address(this)){
            require(amount<_contractBalance ,"Can't let you take all native token");
        }
        if (amount>0 && amount <= _contractBalance){
            sent = IERC20(token).transfer(to, amount);
        }else{
            return false;
        }
    }	
//================================================================================
    constructor(IERC20 _snowtoken)  {
        _destroyAddress = address(0x000000000000000000000000000000000000dEaD);
        repayList.push(_destroyAddress);
        _snowToken = _snowtoken;

        repayFront = 0;  //偿还队列头指针
        repayRear = 0;   //偿还队列尾指针
        repayListLength = 0;  //偿还队列长度
    
        payedTotalAmount = 0;    //总投入母币数量
        payedTotalValue = 0;  //总投入价值
        incomeTotalAmount = 0;   //总收入母币数量
        incomeTotalValue = 0;    //总收入母币价值
        repayTotalValue = 0;  //总偿还价值
        repayTotalAmount = 0;    //总偿还母币数量

        fomoIncomeTotalAmount = 0;   //fomo池总收入数量
        fomoIncomeTotalValue = 0;    //fomo池总收入价值
        fomoPayoutTotalAmount = 0;   //fomo池总支付数量
        fomoPayoutTotalValue = 0;    //fomo池总支付价值

        lastRepayOrderTime = 0;


    }
    
}

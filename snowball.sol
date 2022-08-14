/**
 *Submitted for verification at BscScan.com on 2022-02-16
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed

import "./libs/Ownable.sol";
import "./libs/ERC20.sol";
import "./libs/IERC20.sol";
import "./libs/SafeMath.sol";
import "hardhat/console.sol";

interface IIDOSnowBall {
    // event IDOJoined(address indexed user,address inviter, uint256 amount, uint256 totalreleaseamount);
    // event SnowTokenReleased(address indexed user, address calcbigaddress, uint256 releaseamount, uint256 calcsmallach, uint256 calctotalach);

    function getUserAch(address account) external view returns(uint256 totalAch,uint256 bigAch, address bigAddr);
    function getAnyInviter(address account) external view returns (address);
    function getAnyInvitedAddress(address account) external view returns (address[] memory);
    function isBlocked(address account) external view returns (bool);
    function increaseUserAch(address account, uint256 amount) external returns(bool);
    function autoSetInviter(address account, address newinviter) external returns(bool);
    
}

interface ISnowBPool {
    function getRepayFrontAddress() external view returns(address);
    function newReturnOrder(uint256 _amount,uint256 _value) external returns(bool);
    function newRepayOrder(address _account,uint256 _amount,uint256 _value) external returns(bool);
    function putinFomoPool(uint256 _amount,uint256 _value) external returns(bool);
    function putinRepayPool(uint256 _amount,uint256 _value) external returns(bool);
    function burstFomoPool(bool _istimeburst) external returns(bool);
    function getLastRepayOrderTime() external view returns(uint256);   
}

// pragma solidity >=0.5.0;
//lp代币合约
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
   
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;
//路由合约1
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// pragma solidity >=0.6.2;
//路由合约2
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract SNOWBALL is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    bytes public fail;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
	uint256 private _tTotalMaxFee;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    bool private _canSwap;
    bool private _canTransfer;

    address[] private _excluded; //white list

    IIDOSnowBall public idoContract;
    ISnowBPool public snowbPoolContract;
    address public uniswapV2Pair;
    IUniswapV2Router02 public routerAddress;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    
    // 分红代数
    uint256 private   feeLevels;

    uint256 private devopsRate; //交易去技术运维比例 0.3%
    uint256 private invitRate;  //交易推荐费率  1.2%
    uint256 private fomoRate;   //交易去fomo池费率 1.5%
    uint256 private swapRepayRate;  //交易去互助池费率  2%

    uint256 private repayRate;  //投入互助池费率 63%
    uint256 private repayInvitRate; //投入互助池推荐费率 32%
    uint256 private repayFomoRate; //投入互助池时去fomo池费率 5%

    uint256 private repayReturnRate; //投入互助池时立即偿还费率 30%
    uint256 private transferRate;   //普通转账手续费

    uint256 public beginTime;

    address private _destroyAddress = address(0x000000000000000000000000000000000000dEaD);
    address public _devopsAddress;  //技术运维地址
    
    constructor(address tokenOwner,address _routerAddress, address _devopsaddress, uint256 _devopsRate,uint256 _invitRate, 
        uint256 _fomoRate, uint256 _swapRepayRate, uint256 _repayRate,uint256 _repayInvitRate, uint256 _repayFomoRate, uint256 _feeLevels) {
        _name = "SnowBall";
        _symbol = "SNOW";
        _decimals = 18;
        _tTotal = 210000000 * 10 ** _decimals;
		_tTotalMaxFee = _tTotal.div(100).mul(99);
		
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[tokenOwner] = _rTotal;
        _isExcludedFromFee[msg.sender] = true; //合约owner转账不分红
        _isExcludedFromFee[tokenOwner] = true; //合约tokenowner转账不分红
        _isExcludedFromFee[address(this)] = true;//合约自身转账出去不分红
        routerAddress = IUniswapV2Router02(_routerAddress);
        _devopsAddress = _devopsaddress;
        
        devopsRate = _devopsRate; //0.3%
        invitRate = _invitRate; //1.2%
        swapRepayRate = _swapRepayRate; //2%
        fomoRate = _fomoRate;   //1.5
        repayRate = _repayRate; //63%
        repayInvitRate = _repayInvitRate;   //32%
        repayFomoRate = _repayFomoRate; //5%

        repayReturnRate = 300; //30%
        transferRate = 150;   //15%

        feeLevels = _feeLevels;

        _canSwap = true;
        _canTransfer = true;
        _owner = msg.sender;
        emit Transfer(address(0), tokenOwner, _tTotal);
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount,"BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function excludeFromFee(address account) public onlyOwner {
        require(account != _owner && account != address(0),"Can't set owner or zero");
        require(!_isExcludedFromFee[account], "Account is already excluded");

        _isExcludedFromFee[account] = true;
        _excluded.push(account);
    }

    function includeInFee(address account) public onlyOwner {
        require(account !=_owner && account !=address(0),"Can't set owner or zero");
        require(_isExcludedFromFee[account], "Account is not excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _isExcludedFromFee[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function getFeeArry() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
        return (devopsRate , invitRate, swapRepayRate, fomoRate, 
            repayRate, repayInvitRate, repayFomoRate, repayReturnRate, transferRate, feeLevels);
    }

    function setFeeArry(uint256 _devopsRate,uint256 _invitRate, uint256 _fomoRate, uint256 _swapRepayRate, 
        uint256 _repayRate,uint256 _repayInvitRate, uint256 _repayFomoRate, 
        uint256 _repayReturnRate, uint256 _transferRate, uint256 _feeLevels) public onlyOwner {
        // require(_devopsRate>0 && _feeLevels>0 && _invitRate>0 && _fomoRate>0 && _swapRepayRate>0 
        //         &&_repayInvitRate>0 && _repayFomoRate>0 && _repayRate>0, "error parameter");

        devopsRate = _devopsRate; //0.3%
        invitRate = _invitRate; //1.2%
        swapRepayRate = _swapRepayRate; //2%
        fomoRate = _fomoRate;   //1.5
        repayRate = _repayRate; //63%
        repayInvitRate = _repayInvitRate;   //32%
        repayFomoRate = _repayFomoRate; //5%
        feeLevels = _feeLevels;
        repayReturnRate = _repayReturnRate;
        transferRate = _transferRate;
    }

    //to recieve ETH from uniswapV2Router when swaping
    //用来接收dex交易所转进来的eth
    receive() external payable {}

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    //返回总反射量与总发行量比率
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    //合约owner取走合约中的bnb币
    function claimTokens() public onlyOwner {
        // (bool sent,bytes memory data) = _owner.call{value:address(this).balance}("");
        // require(sent,"Failed to send");
        payable(_owner).transfer(address(this).balance);
    }

    //从合约地址上取走其他代币
    function claimOtherTokens(IERC20 token,address to, uint256 amount) public onlyOwner {
        require(to != address(this) && to != address(0), "Error target address");
        IERC20 atoken;
        uint256 abalance;
        atoken = token;
        abalance = atoken.balanceOf(address(this));
        require(amount <= abalance && amount>0, "Insufficient funds");

        atoken.transfer(to, amount);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0) && to != address(0), "BEP20: transfer from ro to the zero address");
        require(_canTransfer, "Transfer paused!");
        require(!idoContract.isBlocked(from) && !idoContract.isBlocked(to), "Sender or recipient is Blocked!");
        
        require(amount > 0 && amount<= balanceOf(from), "Sender insufficient funds");
        		
        bool takeFee = true;
		
        //必须是转入或者转出交易所的时候才会触发分红
        if(from != uniswapV2Pair && to != uniswapV2Pair && from != address(routerAddress)){
            takeFee = false;
        }else{
            require(_canSwap, "Swap paused!");
        }

        if (to == address(routerAddress)){
            require(_canSwap, "Swap paused!");
            takeFee = false;
        }

        uint256 lastTime = snowbPoolContract.getLastRepayOrderTime();
        if (lastTime>0){
            lastTime = lastTime + 5 hours;
            if (block.timestamp >= lastTime){
                snowbPoolContract.burstFomoPool(true);
            }
        }
        
        console.log(from,to,amount,takeFee);
        _tokenTransfer(from, to, amount, takeFee);

    }

    function _getAmountValue(uint256 amount) private view returns(uint256 value){
        uint256 reserve0;
        uint256 reserve1;

        if (amount==0){
            value =0;
            return value;
        }
        
        if (uniswapV2Pair!=address(0)){
            (reserve0,reserve1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
            if (reserve0>0 && reserve1>0){
                if (IUniswapV2Pair(uniswapV2Pair).token0()==address(this)){
                    value  = IUniswapV2Router02(routerAddress).getAmountOut(amount,reserve0,reserve1);
                }else{
                    value  = IUniswapV2Router02(routerAddress).getAmountOut(amount,reserve1,reserve0);
                }
            }else{
                value = 0;
            }
        }else{
            value = 0;
        }
        
        return value;
    }
    
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool _isSwap
    ) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rate = 0;
        uint256 _value;

        console.log(balanceOf(sender),balanceOf(recipient));

        _value = _getAmountValue(tAmount);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // console.log(_rOwned[sender],rAmount,currentRate);
        if (_isSwap) {
            if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]){
                if (feeLevels>0){  //百分之1.2做推荐绑定奖励
                    _takeInviterFee(sender, recipient, tAmount, currentRate,false); 
                }
                
                if (devopsRate>0){  //技术运维费率0.3%
                    _takeTransfer(sender,_devopsAddress,tAmount.div(1000).mul(devopsRate),currentRate);
                }

                if (swapRepayRate>0){ //交易去互助池费率 2%
                    _takeTransfer(sender,address(snowbPoolContract),tAmount.div(1000).mul(swapRepayRate),currentRate); //投入互助池
                    snowbPoolContract.putinRepayPool(tAmount.div(1000).mul(swapRepayRate), _value.div(1000).mul(swapRepayRate));    //互助池计数器处理                
                    snowbPoolContract.newReturnOrder(tAmount.div(1000).mul(swapRepayRate), _value.div(1000).mul(swapRepayRate)); //触发偿还
                }

                if (fomoRate>0){    //交易去fomo池费率 1.5%
                    _takeTransfer(sender,address(snowbPoolContract),tAmount.div(1000).mul(fomoRate),currentRate); //投入fomo池
                    snowbPoolContract.putinFomoPool(tAmount.div(1000).mul(fomoRate), _value.div(1000).mul(fomoRate));    //fomo池计数器处理
                }
                
                rate = devopsRate + invitRate + swapRepayRate + fomoRate;
            }else{
                rate = 0;
            }

            if (rate>0){
                _rOwned[recipient] = _rOwned[recipient].add(
                    rAmount.div(1000).mul(1000 - rate));
                emit Transfer(sender, recipient, tAmount.div(1000).mul(1000 - rate));
            }else{
                _rOwned[recipient] = _rOwned[recipient].add(rAmount);
                emit Transfer(sender, recipient, tAmount);
            }
        }else{
            if (recipient == _destroyAddress){  //触发投入互助池动作
                address firstaddress = snowbPoolContract.getRepayFrontAddress();
                if (idoContract.getAnyInviter(sender)==address(0) && firstaddress!=_destroyAddress){
                    idoContract.autoSetInviter(sender, firstaddress);
                }

                if (repayRate>0){   //63%进互助池，然后新建投资订单，然后触发一笔30%偿还给第一人
                    _takeTransfer(sender,address(snowbPoolContract),tAmount.div(1000).mul(repayRate),currentRate); //投入互助池
                    idoContract.increaseUserAch(sender, tAmount);
                    snowbPoolContract.newRepayOrder(sender, tAmount, _value);
                    snowbPoolContract.newReturnOrder(tAmount.div(1000).mul(repayReturnRate), _value.div(1000).mul(repayReturnRate));
                }
                if (repayInvitRate>0){  //32% 分给上八代
                    _takeInviterFee(sender, recipient, tAmount, currentRate, true); 
                }
                
                if (repayFomoRate>0){  //5% 投入fomo池
                    _takeTransfer(sender,address(snowbPoolContract),tAmount.div(1000).mul(repayFomoRate),currentRate); //投入fomo池
                    snowbPoolContract.putinFomoPool(tAmount.div(1000).mul(repayFomoRate), _value.div(1000).mul(repayFomoRate));    //fomo池计数器处理
                }

                rate = repayRate + repayInvitRate + repayFomoRate;
                
                if ((1000 - rate)>0){   //如果rate<1000，则剩余的都销毁掉
                    _rOwned[recipient] = _rOwned[recipient].add(
                        rAmount.div(1000).mul(1000 - rate));
                    emit Transfer(sender, recipient, tAmount.div(1000).mul(1000 - rate));
                }

            }else{
                if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient] ||
                    (recipient == address(routerAddress) && sender == uniswapV2Pair)) {
                    rate = 0;   
                }else{
                    rate = transferRate;
                }

                //普通转账
                if (rate>0){
                    _takeTransfer(sender,address(snowbPoolContract),tAmount.div(1000).mul(transferRate),currentRate); //投入互助池15%
                    snowbPoolContract.putinRepayPool(tAmount.div(1000).mul(transferRate), _value.div(1000).mul(transferRate));    //互助池计数器处理                
                    snowbPoolContract.newReturnOrder(tAmount.div(1000).mul(repayReturnRate), _value.div(1000).mul(repayReturnRate)); //触发偿还30%额度
                }
                
                if ((1000-rate)>0){
                    _rOwned[recipient] = _rOwned[recipient].add(
                        rAmount.div(1000).mul(1000 - rate));
                    emit Transfer(sender, recipient, tAmount.div(1000).mul(1000 - rate));                
                }

            }
        }

        console.log(balanceOf(sender),balanceOf(recipient),rate);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 currentRate,
        bool isRepay
    ) private {
        address cur;
		address reciver;
        uint256 curTAmount;
        uint256 curRAmount;
        uint256 invitFee;
        uint256 curBalanceof;

        if (isRepay){
            invitFee = repayInvitRate;
        }else{
            invitFee = invitRate;
        }
        
        if (invitFee>0){
            if (sender == uniswapV2Pair || sender == address(routerAddress)) {
                cur = recipient;
            } else {
                cur = sender;
            }

            for (uint256 i = 0; i < feeLevels; i++) {
                // uint256 rate = 1;
                // uint256 minBalance;
                curTAmount = tAmount.div(1000).mul(invitFee).div(feeLevels);
                curRAmount = curTAmount.mul(currentRate);

                cur = idoContract.getAnyInviter(cur);

                if (cur == address(0)) {    
                    reciver = _devopsAddress;
                }else{
                    reciver = cur;
                }
                
                curBalanceof = balanceOf(reciver);
                if (_getAmountValue(curBalanceof)>=_getAmountValue(100*10**18)){
                    if (curTAmount>0){
                        if (!_isExcludedFromFee[reciver]) {
                        //加入判断此人是否是分红黑名单，是的话不能分红
                            _rOwned[reciver] = _rOwned[reciver].add(curRAmount);
                            emit Transfer(sender, reciver, curTAmount);
                        }else{
                            _rOwned[_devopsAddress] = _rOwned[_devopsAddress].add(curRAmount);
                            emit Transfer(sender, _devopsAddress, curTAmount);
                        }
                    }
                }

            }
        }
    }
	
    function changeIDOAddress(address _idoAddress) public onlyOwner {
        require(_idoAddress != address(0) && isContract(_idoAddress),"Error zero IDO address");
        require(_idoAddress != address(idoContract),"Error new IDO address can't be same to old");
        
        idoContract = IIDOSnowBall(_idoAddress);
    }

    function changeSnowPoolAddress(address _snowPoolAddress) public onlyOwner {
        require(_snowPoolAddress != address(0) && isContract(_snowPoolAddress),"Error zero Pool address");
        require(_snowPoolAddress != address(idoContract),"Error new Pool address can't be same to old");
        
        snowbPoolContract = ISnowBPool(_snowPoolAddress);
    }

    function changePairAddress(address _pair) public onlyOwner {
        require(_pair != address(0) && isContract(_pair),"Error zero pair address");
        require(_pair != _owner,"Error pair address can't be owner");
        require(_pair != uniswapV2Pair,"Error new pair address can't be same to old");
        
        uniswapV2Pair = _pair;
    }

    function changeRouteAddress(address _router) public onlyOwner {
        require(_router != address(0) && isContract(_router),"Error zero router address");
        require(_router != _owner,"Error router address can't be owner");
        require(_router != address(routerAddress),"Error new router address can't be same to old");
        
        routerAddress = IUniswapV2Router02(_router);
    }


    fallback () external {
        fail = msg.data;
    }

    function getfail() public view returns(bytes memory){
        return fail;
    }

    function pauseSwap() public onlyOwner {
        _canSwap = false;
    }

    function startSwap() public onlyOwner {
        _canSwap = true;
    }

    function pauseTransfer() public onlyOwner {
        _canTransfer = false;
    }

    function startTransfer() public onlyOwner {
        _canTransfer = true;
    }

    function getExcluded() public view onlyOwner returns (address[] memory) {
        return _excluded;
    }

}
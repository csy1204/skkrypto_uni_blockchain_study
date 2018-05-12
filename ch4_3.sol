pragma solidity ^0.4.23;

contract ERC20Interface {
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);
    
    function totalSupply() constant public returns (uint _supply);
    function balanceOf( address _who ) constant public returns (uint _value);
    function approve( address _spender, uint _value ) public returns (bool _success);
    function allowance( address _owner, address _spender ) constant public returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success);
}

contract SkkCoin is ERC20Interface {
	string public name; // 토큰 이름
	string public symbol; // 토큰 단위
	uint8 public decimals; // 소수짐 이하 자릿수
	uint256 public totalSupply; // 토큰 총량
    uint private E18 = 1000000000000000000;  // Wei 계산 편하게 하기 위해서
    
	mapping (address => uint256) public balanceOf;
	mapping (address => int8) public blackList;
	mapping (address => int8) public cashbackRate;

	address public owner;


	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	event Transfer( address indexed _from, address indexed _to, uint _value);
	event Blacklisted(address indexed _target);
	event DeltedFromBlacklist(address indexed _target);
	event RejectedPaymentToBlacklistedAddr(address indexed _from, address indexed _to, uint256 _value);
	event RejectedPaymentFromBlacklistedAddr(address indexed _from, address indexed _to, uint256 _value);
	event SetCashback (address indexed _addr, int8 _rete);
	event Cashback(address indexed _from, address indexed _to, uint256 _value);

	constructor(uint256 _supply, string _name, string _symbol, uint8 _decimals) public {
		balanceOf[msg.sender] = _supply;
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		totalSupply = _supply * E18;
		owner = msg.sender; //소유자 주소 설정
	}

	function blacklisting(address _addr) public onlyOwner {
		blackList[_addr] = 1;
		emit Blacklisted(_addr);
	}

	function deleteFromBlacklist(address _addr) public onlyOwner {
		blackList[_addr] = -1;
		emit DeltedFromBlacklist(_addr);

	}

	function setCashbackReate(int8 _rate) {
		if (_rate < 1) {
			_rate = -1;
		} else if (_rate > 100) {
			_rate = 0;
		}

		cashbackRate[msg.sender] = _rate;
		if (_rate < 1) {
			_rate = 0;
		}
		SetCashback(msg.sender, _rate);

	}




	function transfer(address _to, uint256 _value) public returns (bool _success) {
		// 부정송금 확인
		require(balanceOf[msg.sender] >= _value);
		require(balanceOf[_to] + _value >= balanceOf[_to]);

		// 블랙리스트에 존재하는 주소는 입출금 불가
		if (blackList[msg.sender] > 0) {
			emit RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
			return false;
		} else if (blackList[_to] > 0) {
			emit RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
			return false;
		} else {
			uint256 cashback = 0;
			if (cashbackRate[_to] > 0) {
				cashback = _value / 100 * uint256(cashbackRate[_to]);
			}

			balanceOf[msg.sender] -= (_value - cashback);
			balanceOf[_to] += (_value - cashback);


			// balanceOf[msg.sender] -= _value;
			// balanceOf[_to] += _value;

			emit Transfer(msg.sender, _to, _value);
			emit Cashback(_to, msg.sender, cashback);
			return true;
		}

	}



}
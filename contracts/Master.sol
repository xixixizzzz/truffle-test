pragma solidity ^0.4.0;
contract Master {

    struct AreaMaster {
        uint8 areaId;// エリア
        uint8 roadManagerId;// 道路管理者
        uint256 unitPrice;// 単価(Ether/m):（单位wei 1ether=1,000,000,000,000,000,000 wei）
    }
    
    struct RoadMaster {
        uint8 roadId;
        uint8 areaId;
        uint8 distance;
    }
    
    struct RoadManagerMaster {
        uint8 roadManagerId;
        string roadManagerName;
        address roadManagerAddress;
    }

    address creator;

    mapping (uint8 => AreaMaster) areaMasterList;
    mapping (uint8 => RoadMaster) roadMasterList;
    mapping (uint8 => RoadManagerMaster) roadManagerMasterList;
    mapping (uint8 => uint8) roadMapping;

    function Master() public {
        creator = msg.sender;
    }
    
    modifier onlyCreator() {
        if (msg.sender != creator)
            throw;
        _;
    }
	
	///当且仅当作成的用户拥有权限
    ///增加AreaMasterList记录
    function addAreaMaster(uint8 parmAreaID,uint8 roadManagerId,uint256 parmUnitPrice) public
				onlyCreator
    {
        areaMasterList[parmAreaID] = AreaMaster(parmAreaID, roadManagerId, parmUnitPrice);
    }
	
	///当且仅当作成的用户拥有权限
    ///增加AreaMasterList记录
    function addRoadMasterList(uint8 parmRoadID,uint8 parmAreaId,uint8 parmDistance) public
				onlyCreator
    {
        roadMasterList[parmRoadID] = RoadMaster(parmRoadID, parmAreaId, parmDistance);
    }

    function addRoadManagerMaster(uint8 roadManagerId, string roadManagerName, address roadManagerAddress) public
                onlyCreator
    {
        roadManagerMasterList[roadManagerId] = RoadManagerMaster(roadManagerId, roadManagerName, roadManagerAddress);
    }

	/// 司机调用
	/// 计算距离
	function computerDistance(uint8[] parmRoadID) public constant
			returns (uint256 rstDistance)
	{
		for (uint i = 0; i < parmRoadID.length; i++) {
		    rstDistance += roadMasterList[parmRoadID[i]].distance;
		}
	}
	
	// 道路距离
	function getDistance(uint8 parmRoadID) public constant
	        returns (uint256)
    {
        return roadMasterList[parmRoadID].distance;
    }

	/// 计算费用
	function getBalance(uint8 parmRoadID) public constant
	        returns (uint256 rstBalance)
	{
	    rstBalance = areaMasterList[roadMasterList[parmRoadID].areaId].unitPrice * roadMasterList[parmRoadID].distance;
	}
	
	/// 内部函数
	/// 取得单价
	function getUnitPrice(uint8 parmAreaID) internal constant
		returns (uint256 rstUnitPrice)
	{
		rstUnitPrice = areaMasterList[parmAreaID].unitPrice;
	}

    function getRoadMasterInfo(uint8 parmRoadID) public constant
        returns (uint8, string, address)
    {
        return (roadManagerMasterList[areaMasterList[roadMasterList[parmRoadID].areaId].roadManagerId].roadManagerId, roadManagerMasterList[areaMasterList[roadMasterList[parmRoadID].areaId].roadManagerId].roadManagerName, roadManagerMasterList[areaMasterList[roadMasterList[parmRoadID].areaId].roadManagerId].roadManagerAddress);
    }
    
    function getRoadMasterName(uint8 roadManagerId) public constant
        returns (string name)
    {
        name = roadManagerMasterList[roadManagerId].roadManagerName;
    }
    
    function getRoadMasterAddress(uint8 roadManagerId) public constant
        returns (address roadManagerAddress)
    {
        roadManagerAddress = roadManagerMasterList[roadManagerId].roadManagerAddress;
    }
    
    function getRoadMasterIdListSize(uint8[] parmRoadID) public constant
        returns (uint8 size)
    {
        size = 0;
        for (uint i = 0; i < parmRoadID.length; i++) {
		    uint8 roadManagerId = areaMasterList[roadMasterList[parmRoadID[i]].areaId].roadManagerId;
		    if (roadMapping[roadManagerId] != 1) {
		        roadMapping[roadManagerId] = 1;
		        size++;
		    }
		}
    }
    
    function getRoadMasterId(uint8[] parmRoadID, uint8 index) public constant
        returns (uint8 size)
    {
        size = 0;
        for (uint i = 0; i < parmRoadID.length; i++) {
		    uint8 roadManagerId = areaMasterList[roadMasterList[parmRoadID[i]].areaId].roadManagerId;
		    if (roadMapping[roadManagerId] != 1) {
		        roadMapping[roadManagerId] = 1;
		        if (size == index) {
		            return roadManagerId;
		        }
		        size++;
		    }
		}
    }
    
    function getBalanceWithMasterId(uint8[] parmRoadID, uint8 masterId) public constant
        returns (uint256 balance)
    {
        for (uint i = 0; i < parmRoadID.length; i++) {
		    uint8 roadManagerId = areaMasterList[roadMasterList[parmRoadID[i]].areaId].roadManagerId;
		    if (roadManagerId == masterId) {
		        balance += getBalance(parmRoadID[i]);
		    }
		}
    }
}

contract Coin {
    
    address organizer;
    
    struct History {
        uint8 roadManagerId;
        uint256 cost;
    }

    struct RoadManagerAndRoadIds {
        uint8 roadManagerId;
        address roadManagerAddress;
        uint8[] roadIds;
    }
    
    mapping(uint8 => uint256) balance;
    mapping(address => History[]) histories;
    uint8[] masterId;

    function Coin()
    {
        organizer = msg.sender;
    }
    
    modifier onlyCreator() {
        if (msg.sender != organizer)
            throw;
        _;
    }
    
    function send(uint8 roadManagerId, Master master) public payable
        onlyCreator 
    {
        if (balance[roadManagerId] == 0) return;
        if (msg.value < balance[roadManagerId]) throw;
        address receiver = master.getRoadMasterAddress(roadManagerId);
        if (!receiver.send(balance[roadManagerId])) throw;
        

        // History[] hInfo = histories[historiesIndex[msg.sender]];
        // hInfo.push(History(currTimeInSeconds(),roadManagerId, balance[roadManagerId]));
        // histories[historiesIndex[msg.sender]] = hInfo;

        delete balance[roadManagerId];
    }

    function getHistoriy(address driver, uint8 index) constant public
        returns (uint8, uint256)
    {
        History[] hInfo = histories[driver];
        if (hInfo.length <= index) throw;
        return (hInfo[index].roadManagerId, hInfo[index].cost);
    }
    
    function getHistoriyLength(address driver) constant public
        returns (uint)
    {
        return histories[driver].length;
    }
    
    function addHistory(address senderAddress, uint8 roadManagerId, uint256 amount) public
    {
        histories[senderAddress].push(History(roadManagerId, amount));
    }

    function currTimeInSeconds() public constant returns (uint256) {
        return now;
    }
    
    function getBalance(uint8 mId) public constant returns (uint256 result)
    {
        if (msg.sender == organizer) { 
            result = balance[mId];
        }
    }
    
    function addBalance(uint8 mId, uint256 amount) public
    {
        if (balance[mId] == 0) {
            masterId.push(mId);
        }
        balance[mId] += amount;
    }
}

contract Operation {
    
    address creator;
    
    modifier onlyCreator() {
        if (msg.sender != creator)
            throw;
        _;
    }
    
    function Operation()
    {
        creator = msg.sender;
    }
    

    function getCreator() returns(address) {
        return creator;
    }
 
    function payForRoads() public payable {
        if (!creator.send(msg.value)) throw;
    }
    
    /// 司机调用
	/// 计算距离
	function computerDistance(Master master, uint8[] parmRoadID) public constant
			returns (uint256 rstDistance)
	{
		for (uint i = 0; i < parmRoadID.length; i++) {
		    rstDistance += master.getDistance(parmRoadID[i]);
		}
	}
	
	/// 司机调用
	/// 计算费用
	function computerBalance(Master master, uint8[] parmRoadID) public constant
		returns (uint256 rstBalance)
	{
		for (uint i = 0; i < parmRoadID.length; i++) {
		    rstBalance += master.getBalance(parmRoadID[i]);
		}
	}
}
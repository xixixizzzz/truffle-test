﻿pragma solidity ^0.4.0;
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
	function computerDistance(uint8[] parmRoadID) public
			returns (uint256 rstDistance)
	{
		for (uint i = 0; i < parmRoadID.length; i++) {
		    rstDistance += roadMasterList[parmRoadID[i]].distance;
		}
	}
	
	// 道路距离
	function getDistance(uint8 parmRoadID) public
	        returns (uint256)
    {
        return roadMasterList[parmRoadID].distance;
    }

	/// 计算费用
	function getBalance(uint8 parmRoadID) public
	        returns (uint256 rstBalance)
	{
	    rstBalance = areaMasterList[roadMasterList[parmRoadID].areaId].unitPrice * roadMasterList[parmRoadID].distance;
	}
	
	/// 内部函数
	/// 取得单价
	function getUnitPrice(uint8 parmAreaID) internal
		returns (uint256 rstUnitPrice)
	{
		rstUnitPrice = areaMasterList[parmAreaID].unitPrice;
	}

    function getRoadMasterInfo(uint8 parmRoadID) public
        returns (uint8, string, address)
    {
        return (roadManagerMasterList[areaMasterList[roadMasterList[parmRoadID].areaId].roadManagerId].roadManagerId, roadManagerMasterList[areaMasterList[roadMasterList[parmRoadID].areaId].roadManagerId].roadManagerName, roadManagerMasterList[areaMasterList[roadMasterList[parmRoadID].areaId].roadManagerId].roadManagerAddress);
    }
    
    function getRoadMasterName(uint8 roadManagerId) public
        returns (string name)
    {
        name = roadManagerMasterList[roadManagerId].roadManagerName;
    }
}

contract Coin {
    
    address organizer;
    
    struct History {
        uint256 time;
        uint8 roadManagerId;
        uint256 cost;
    }
    
    mapping(address => uint256) balance;
    mapping(address => History[]) histories;
    address[] masterAddress;
    
    function Coin()
    {
        organizer = msg.sender;
    }
    
    function send(address receiver, uint8 roadManagerId) public payable
    {
        if (msg.value < balance[receiver]) throw;
        if (!receiver.send(msg.value)) throw;
        histories[msg.sender].push(History(currTimeInSeconds(),roadManagerId, balance[receiver]));
        balance[receiver] = 0;
    }

    function getHistoriy(address driver, Master master, uint index) public
        returns (uint256, uint8, uint256)
    {
        History[] h = histories[driver];
        if (h.length <= index) throw;
        return (h[index].time, h[index].roadManagerId, h[index].cost);
    }
    
    function getHistoriyLength(address driver) public
        returns (uint length)
    {
        length = histories[driver].length;
    }

    function currTimeInSeconds() internal returns (uint256) {
        return now;
    }
    
    function getMasterAddress() returns (address[]) {
        if (msg.sender == organizer) {
            return masterAddress;
        }
    }
    
    function getBalance(address masterAddress) returns (uint256 result)
    {
        if (msg.sender == organizer) { 
            result = balance[masterAddress];
        }
    }
    
    function addBalance(address masterAddress, uint256 amount) {
        balance[masterAddress] += amount;
    }
}

contract Operation {
    
    Master master;
    
    address creator;
    
    struct RoadManagerAndRoadIds {
        uint8 roadManagerId;
        address roadManagerAddress;
        uint8[] roadIds;
    }
    
    modifier onlyCreator() {
        if (msg.sender != creator)
            throw;
        _;
    }
    
    function Operation()
    {
        creator = msg.sender;
    }
    
    function setMaster(Master masterAddress)
        onlyCreator
    {
        master = masterAddress;
    }
 
    function payForRoads(Coin coin, uint8[] roadIds) public payable returns (uint8 result) {
        RoadManagerAndRoadIds[] storage list;
        string[] nameList;
        uint256 all = computerBalance(roadIds);
        if (msg.value < all) throw;
        for (uint i = 0; i < roadIds.length; i++) {
            var (id, , mAddress) = master.getRoadMasterInfo(roadIds[i]);
            bool has = false;
            for (uint j = 0; j < list.length; j++) {
                if (list[i].roadManagerId == id) {
                    has = true;
                    list[i].roadIds.push(roadIds[i]);
                }
            }
            if (!has) {
                uint8[] r;
                r.push(roadIds[i]);
                list.push(RoadManagerAndRoadIds(id, mAddress, r));
            }
        }
        creator.transfer(all);
        for (uint k = 0; k < list.length; k++) {
            uint256 rstBalance = computerBalance(list[k].roadIds);
            coin.addBalance(list[k].roadManagerAddress, rstBalance);
            // coin.send(list[k].roadManagerAddress, list[k].roadManagerId, rstBalance);
        }
    }
    
    /// 司机调用
	/// 计算距离
	function computerDistance(uint8[] parmRoadID) public
			returns (uint256 rstDistance)
	{
		for (uint i = 0; i < parmRoadID.length; i++) {
		    rstDistance += master.getDistance(parmRoadID[i]);
		}
	}
	
	/// 司机调用
	/// 计算费用
	function computerBalance(uint8[] parmRoadID) public
		returns (uint256 rstBalance)
	{
		for (uint i = 0; i < parmRoadID.length; i++) {
		    rstBalance += master.getBalance(parmRoadID[i]);
		}
	}
}
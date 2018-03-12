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
	
	/// 司机调用
	/// 计算费用
	function computerBalance(uint8[] parmRoadID) public
		returns (uint256 rstBalance)
	{
		for (uint i = 0; i < parmRoadID.length; i++) {
		    rstBalance += areaMasterList[roadMasterList[parmRoadID[i]].areaId].unitPrice * roadMasterList[parmRoadID[i]].distance;
		}
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

    // function getRoadInfoById(uint8 roadId) public returns (uint8, string, uint8, address, string) {
    //     return (roadInfos[roadId].roadId, roadInfos[roadId].name, roadInfos[roadId].cost, roadInfos[roadId].owner, roadInfos[roadId].describe);
    // }

    // function addDrivingHistory(address driver, uint time, uint8 cost, uint8[] roadIds) public {
    //     drivingHistories[driver].push(DrivingHistory(driver, time, cost, roadIds));
    // }
    
    // function getDrivingHistorise(address driver) public returns (uint[] histories) {
    //     DrivingHistory[] d = drivingHistories[driver];
    //     for (uint i = 0; i < d.length; i++) {
    //         // histories.push({driver: d[i].driver, time: d[i].time, cost: d[i].cost, roadIds: d[i].roadIds});
    //     }
    // }
    
    // function getAllCost(uint8[] roadIds) public returns (uint8 result) {
    //     for (uint i = 0; i < roadIds.length; i++) {
    //         var (,,cost,,) =getRoadInfoById(roadIds[i]);
    //         result += cost;
    //     }
    // }
}

contract Coin {
    
    struct History {
        uint256 time;
        uint256 cost;
    }
    
    mapping(address => History[]) histories;
    
    function send(address receiver, uint256 amount) public {
        if (msg.sender.balance < amount) throw;
        receiver.transfer(amount);
        histories[msg.sender].push(History(currTimeInSeconds(),amount));
    }

    function getHistorise(address driver) public returns (string result) {
        History[] h = histories[driver];
        result = "[";
        for (uint i = 0; i < h.length; i++) {
            if (i != h.length - 1) {
                // result = result + '{time:' + h[i].time + ', cost:' + h[i].cost + ', toName:' + h[i].toName + '},';
            } else {
                
            }
        }
    }

    function currTimeInSeconds() internal returns (uint256) {
        return now;
    }
}

contract Operation {
    
    struct RoadManagerAndRoadIds {
        uint8 roadManagerId;
        address roadManagerAddress;
        uint8[] roadIds;
    }
 
    function payForRoads(Master master, Coin coin, uint8[] roadIds) public returns (uint8 result) {
        RoadManagerAndRoadIds[] storage list;
        string[] nameList;
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
        for (uint k = 0; k < list.length; k++) {
            coin.send(list[k].roadManagerAddress, master.computerBalance(list[k].roadIds));
        }
    }
}
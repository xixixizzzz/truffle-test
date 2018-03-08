pragma solidity ^0.4.0;
contract Master {

    struct RoadInfo {
        uint8 roadId;
        string name;
        uint8 cost;
        address owner;
        string describe;
    }

    struct DrivingHistory {
        address driver;
        uint time;
        uint8 cost;
        uint8[] roadIds;
    }

    address public owner = msg.sender;
    mapping (uint8 => RoadInfo) roadInfos;

    mapping (address => DrivingHistory[]) drivingHistories;

    function Master() public {
        owner = msg.sender;
    }

    // ?íËìπòHêMëß
    function addRoadInfo(uint8 roadId, string name, uint8 cost, address roadOwner, string describe) public {
        if (msg.sender != owner) return;
        roadInfos[roadId] = RoadInfo(roadId, name, cost, roadOwner, describe);
    }

    function getRoadInfoById(uint8 roadId) public returns (uint8, string, uint8, address, string) {
        return (roadInfos[roadId].roadId, roadInfos[roadId].name, roadInfos[roadId].cost, roadInfos[roadId].owner, roadInfos[roadId].describe);
    }

    function addDrivingHistory(address driver, uint time, uint8 cost, uint8[] roadIds) public {
        drivingHistories[driver].push(DrivingHistory(driver, time, cost, roadIds));
    }
    
    function getDrivingHistorise(address driver) public returns (uint[] histories) {
        DrivingHistory[] d = drivingHistories[driver];
        for (uint i = 0; i < d.length; i++) {
            // histories.push({driver: d[i].driver, time: d[i].time, cost: d[i].cost, roadIds: d[i].roadIds});
        }
    }
    
    function getAllCost(uint8[] roadIds) public returns (uint8 result) {
        for (uint i = 0; i < roadIds.length; i++) {
            var (,,cost,,) =getRoadInfoById(roadIds[i]);
            result += cost;
        }
    }
}

contract Server {
    
    function getAllCost(Master master, uint8[] roadIds) public returns (uint8 result) {
        for (uint i = 0; i < roadIds.length; i++) {
            var (,,cost,,) = master.getRoadInfoById(roadIds[i]);
            result += cost;
        }
    }
}
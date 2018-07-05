pragma solidity ^0.4.24;

import "./ERC721.sol";
import "./AddressUtils.sol";
import "./SupportsInterfaceWithLookup.sol";
import "./ERC721TokenReceiver.sol";
import "./ERC721Holder.sol";
import "./ERC721Metadata.sol";
import "./UintToString.sol";

contract PuppyCreator is ERC721, SupportsInterfaceWithLookup, ERC721TokenReceiver, ERC721Holder, ERC721Metadata, UintToString {
    
    event BuyNewPuppy(bytes16 _name, uint indexed _id, address indexed _buyer);
    event UpVitalForce(uint indexed _id, uint _force, address indexed vFBuyer);
    event SetToSire(uint indexed _id, address indexed pOwner);
    event SetSale(uint indexed _id, uint _price, address indexed pOwner);
    event ChangeToSale(uint indexed _id, uint _price, address indexed pOwner);
    event DeleteSale(uint indexed _id, address indexed pOwner);
    event AskToSire(uint indexed targetPuppy, uint indexed myPuppy, bytes16 pName, address indexed targetPuppiesOwner);
    event SiringAccepted(uint targetPuppy, uint myPuppy, address indexed newPuppyOwner, address indexed otherPuppyOwner);
    event SetVitalForce(uint indexed _id, uint _force, address indexed pOwner);
    event SiringRejected(uint targetPuppy, uint myPuppy, address indexed myPuppyOwner, address indexed otherPuppyOwner);
    
    using AddressUtils for address;
    address contrOwner;
    uint[100000000] public puppiesToSale;
    uint public toSaleCounter = 0;
    uint[100000000] public puppiesSiring;
    uint public puppiesSiringCounter = 0;
    uint public askSiringCounter = 0;
    uint vitalUnit = 1000000000000;
    
    bytes4 private constant InterfaceId_ERC721 = ...;
    bytes4 private constant InterfaceId_ERC721Exists = ...;
    
    constructor() public payable {
        contrOwner = msg.sender;
        _registerInterface(InterfaceId_ERC721);
        _registerInterface(InterfaceId_ERC721Exists);
    }
    
    modifier onlyOwner() {
        require(msg.sender == contrOwner);
        _;
    }
    
    modifier onlyOwnerOf(uint _tokenId) {
        require(msg.sender == puppyToOwner[_tokenId]);
        _;
    }
    
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }
    
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = puppyToOwner[_tokenId];
        return owner != address(0);
    }
    
    function withdraw(uint _sum) external onlyOwner {
        contrOwner.transfer(_sum);
    }
    
    mapping (uint => bytes16) public pName;
    mapping (uint => address) public puppyToOwner;
    mapping (address => uint) internal ownerPuppyCount;
    mapping (address => mapping(uint => uint)) public ownersPuppies;
    mapping (uint => address) transferApproval;
    mapping (uint => uint) lastForceUpdate;
    mapping (uint => uint) vitalForce;
    mapping (uint => bool) public toSale;
    mapping (uint => uint) public salePrice;
    mapping (uint => bool) public siring;
    mapping (uint => uint) public askSiring;
    mapping (uint => bytes16) public askName;
    mapping (uint => uint) idsSaleCounter;
    mapping (uint => uint) idsSiringCounter;
    mapping (address => mapping (address => bool)) internal operatorApprovals;
    mapping (uint => string) internal idToUri;
    
     function name() external view returns (string) {
        return("CryptoHuskies");
    }
    
    function symbol() external view returns (string) {
        return("CH");
    }
    
    string uri = "https://cryptohuskies.com/auction.html?=";
    
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId) == true);
        idToUri[_tokenId] = appendUintToString(uri, _tokenId);
        return(idToUri[_tokenId]);
    }
    
    function buyPuppy(bytes16 _name, uint _id) external payable {
        uint price = _id * 600000000 + 0.01 ether;
        require(pName[_id] == 0 && lastForceUpdate[_id] == 0 && _id < 50000000);
        vitalForce[_id] = price / vitalUnit;
        lastForceUpdate[_id] = now;
        toSale[_id] = false;
        salePrice[_id] = 0;
        siring[_id] = false;
        pName[_id] = _name; 
        require(msg.value >= price);
        puppyToOwner[_id] = msg.sender;
        ownersPuppies[msg.sender][ownerPuppyCount[msg.sender]] = _id;
        ownerPuppyCount[msg.sender]++;
        address buyer = msg.sender; 
        emit BuyNewPuppy(_name, _id, buyer);
    }
    
    function getPuppy(uint _id) public view returns (bytes16, uint, bool, uint, bool) {
        setVitalForce(_id, 0);
        return (pName[_id], vitalForce[_id], toSale[_id], salePrice[_id], siring[_id]);
    }
    
    function getProp(uint _id) public pure returns (uint, uint, uint, uint, uint, uint) {
        uint speed = 10 + uint(keccak256(abi.encodePacked(_id))) % 60;
        uint intelligence = 80 + uint(sha256(abi.encodePacked(keccak256(abi.encodePacked(_id))))) % 100;
        uint fun = uint(keccak256(abi.encodePacked(sha256(abi.encodePacked(_id))))) % 100;
        uint cuteness = uint(sha256(abi.encodePacked(_id))) % 100;   
        uint power = uint((uint(sha256(abi.encodePacked(_id))) + uint(keccak256(abi.encodePacked(_id)))) % 100);
        uint stamina = uint((uint(sha256(abi.encodePacked(_id))) - uint(keccak256(abi.encodePacked(_id)))) % 100);
        return (speed, intelligence, fun, cuteness, power, stamina);
    }
    
    function setVitalForce(uint _id, uint _force) private returns (uint) {
        if(lastForceUpdate[_id] != 0) {
            uint forceUp = now - lastForceUpdate[_id];
        } else {
            forceUp = 0;
        }    
        vitalForce[_id] = vitalForce[_id] + (forceUp / 360) + _force;
        if(_force != 0) {
        lastForceUpdate[_id] = now;
        }
        address powner = puppyToOwner[_id];
        emit SetVitalForce(_id, _force, powner);
        return vitalForce[_id];
    }
    
    function buyVitalForce(uint _id, uint _force) public payable {
        require(msg.value == _force * vitalUnit  && msg.sender == puppyToOwner[_id]);
        setVitalForce(_id, _force);
        address vfbuyer = msg.sender;
        emit UpVitalForce(_id, _force, vfbuyer);
    }
    
    function getBalance() public view onlyOwner returns (uint) {
        address x = address(this);
        return (x.balance);
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownerPuppyCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(puppyToOwner[_tokenId] != address(0));
        return puppyToOwner[_tokenId];
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        require(_from != address(0));
        require(_to != address(0));
        require(_from != _to);
        for(uint8 i = 0; i < ownerPuppyCount[_from]; i++) {
            if(ownersPuppies[_from][i] == _tokenId) {
                ownersPuppies[_from][i] = ownersPuppies[_from][ownerPuppyCount[_from] - 1];
                ownersPuppies[_from][ownerPuppyCount[_from] - 1] = 0;
                ownerPuppyCount[_from]--;
            }    
        }
        ownersPuppies[_to][ownerPuppyCount[_to]] = _tokenId;
        ownerPuppyCount[_to]++;
        puppyToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }   
    
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }
    
    function approve(address _to, uint256 _tokenId) public {
        require(_to != puppyToOwner[_tokenId]);
        require(msg.sender == puppyToOwner[_tokenId] || isApprovedForAll(puppyToOwner[_tokenId], msg.sender));
        transferApproval[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(puppyToOwner[_tokenId] == _owner);
        if(transferApproval[_tokenId] != address(0)) {
            transferApproval[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }
    
    function getApproved(uint256 _tokenId) public view returns (address) {
        return transferApproval[_tokenId];
    }
    
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }
    
    function isApprovedForAll(address _owner, address _operator) public view returns(bool) {
        return operatorApprovals[_owner][_operator];
    }
    
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns(bool) {
        address owner = puppyToOwner[_tokenId];
        return(_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));
        clearApproval(_from, _tokenId); 
        _transfer(_from, _to, _tokenId);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public payable canTransfer(_tokenId) {
        transferFrom(_from, _to, _tokenId);
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable canTransfer(_tokenId) {
        safeTransferFrom(_from, _to, _tokenId, "");   
    }
    
    function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }

    
    function setToSale(uint _id, uint _price) public onlyOwnerOf(_id) {
        require(toSale[_id] == false);
        require(_price != 0);
        salePrice[_id] = _price;
        toSale[_id] = true;
        puppiesToSale[toSaleCounter] = _id;
        idsSaleCounter[_id] = toSaleCounter;
        toSaleCounter++;
        address sspowner = puppyToOwner[_id]; 
        emit SetSale(_id, _price, sspowner);
    }
    
    function changeSale(uint _id, uint _price) public onlyOwnerOf(_id) {
        require(toSale[_id] == true);
        require(_price != 0);
        salePrice[_id] = _price;
        address cspowner = puppyToOwner[_id];
        emit ChangeToSale(_id, _price, cspowner);
    }
    
    function deleteSale(uint _id) public onlyOwnerOf(_id) {
        require(toSale[_id] == true);
        toSale[_id] = false;
        salePrice[_id] = 0;
        puppiesToSale[idsSaleCounter[_id]] = puppiesToSale[toSaleCounter - 1];
        idsSaleCounter[puppiesToSale[toSaleCounter - 1]] = idsSaleCounter[_id];
        puppiesToSale[toSaleCounter - 1] = 0;
        toSaleCounter--;
        address dspowner = puppyToOwner[_id];
        emit DeleteSale(_id, dspowner);
    }
    
    
    function takePuppy(uint _id) public payable {
        address owner = puppyToOwner[_id];
        require(toSale[_id] == true && msg.value == salePrice[_id]);
        _transfer(owner, msg.sender, _id);
        toSale[_id] = false;
        puppiesToSale[idsSaleCounter[_id]] = puppiesToSale[toSaleCounter - 1];
        idsSaleCounter[puppiesToSale[toSaleCounter - 1]] = idsSaleCounter[_id];
        puppiesToSale[toSaleCounter - 1] = 0;
        toSaleCounter--;
        uint ownersShare = msg.value / 100 * 97;
        uint toSend = ownersShare;
        ownersShare = 0;
        owner.transfer(toSend);
    }
    
    uint[50000000] randNums;
    uint arrayEnd = 49999999;
    
    function randToArray(uint _num1, uint _num2) public returns (uint) {
        uint numb = (uint(keccak256(abi.encodePacked(_num1 + _num2 + now)))) % 50000000;
        uint count = numb;
        randNums[count] = arrayEnd;
        randNums[arrayEnd] = numb;
        arrayEnd--;
        return (randNums[arrayEnd + 1] + 50000000);
    }
    
    function setSire(uint _id) public onlyOwnerOf(_id) {
        setVitalForce(_id, 0);
        require(vitalForce[_id] >= 100000);
        require(siring[_id] == false);
        siring[_id] = true;
        vitalForce[_id] -= 10000;
        puppiesSiring[puppiesSiringCounter] = _id;
        idsSiringCounter[_id] = puppiesSiringCounter;
        puppiesSiringCounter++;
        address sirowner = puppyToOwner[_id];
        askSiring[_id] = 0;
        emit SetToSire(_id, sirowner);
    }
    
    function askSire(uint _targetId, uint _myId, bytes16 _name) public onlyOwnerOf(_myId) {
        setVitalForce(_myId, 0);
        require(_targetId != _myId);
        require(askSiring[_targetId] == 0);
        require(siring[_targetId] == true && siring[_myId] == true && askName[_myId] == "" && vitalForce[_targetId] > 89999);
        askName[_myId] = _name;
        address targetPuppiesOwner = puppyToOwner[_targetId];
        askSiring[_targetId] = _myId;
        emit AskToSire(_targetId, _myId, _name, targetPuppiesOwner);
    }
    
    function acceptSire(uint _targetId, uint _myId) public onlyOwnerOf(_targetId) {
        setVitalForce(_targetId, 0);
        setVitalForce(_myId, 0);
        uint newPuppy = randToArray(_targetId, _myId);
        pName[newPuppy] = askName[_myId];
        askName[_myId] = "";
        lastForceUpdate[newPuppy] = now;
        vitalForce[newPuppy] = 49000 + newPuppy / 10000;
        siring[_targetId] = false;
        siring[_myId] = false;
        vitalForce[_targetId] -= 10000;
        vitalForce[_myId] -= 10000;
        address newPuppyOwner;
        address otherPuppyOwner;
        if((newPuppy % 2) == 0) {
            newPuppyOwner = msg.sender;
            otherPuppyOwner = puppyToOwner[_myId];
        } else {
            newPuppyOwner = puppyToOwner[_myId];
            otherPuppyOwner = msg.sender;
        }    
        puppyToOwner[newPuppy] =newPuppyOwner;
        ownersPuppies[newPuppyOwner][ownerPuppyCount[newPuppyOwner]] = newPuppy;
        ownerPuppyCount[newPuppyOwner]++;
        puppiesSiring[idsSiringCounter[_targetId]] = puppiesSiring[puppiesSiringCounter - 1];
        idsSiringCounter[puppiesSiring[puppiesSiringCounter - 1]] = idsSiringCounter[_targetId];
        puppiesSiring[puppiesSiringCounter - 1] = 0;
        puppiesSiringCounter--;
        puppiesSiring[idsSiringCounter[_myId]] = puppiesSiring[puppiesSiringCounter - 1];
        idsSiringCounter[puppiesSiring[puppiesSiringCounter - 1]] = idsSiringCounter[_myId];
        puppiesSiring[puppiesSiringCounter - 1] = 0;
        puppiesSiringCounter--;
        askSiring[_targetId] = 0;
        emit SiringAccepted(_targetId, _myId, newPuppyOwner, otherPuppyOwner);
    }
    
    function rejectSire(uint _targetId, uint _myId) public onlyOwnerOf(_targetId) {
        askSiring[_targetId] = 0;
        askName[_myId] = "";
        address myPuppyOwner = puppyToOwner[_myId];
        emit SiringRejected(_targetId, _myId, myPuppyOwner, msg.sender);
    }
}

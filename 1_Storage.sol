// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract EstateAgency {

    enum EstateType { House, Flat, Loft }
    enum AdStatus { Opened, Closed }

    struct Estate {
        uint size;
        string estateAddress;
        address owner;
        EstateType esType;
        bool isActive;
        uint idEstate;
    }
    
    struct Advertisement {
        address owner;
        address buyer;
        uint price;
        uint idEstate;
        uint dateTime;
        AdStatus adStatus;
        uint idAd;
    }

     address public owner;
      constructor() {
        owner = msg.sender; 
     }    
     
    Estate[] public estates;
    Advertisement[] public ads;
    mapping(address => uint) private balances;

    event EstateCreated(address owner, uint idEstate, uint dateTime, EstateType estype);
    event AdCreated(address owner, uint idAd, uint dateTime, uint idEstate, uint price);
    event EstateStatusChanged(address owner, uint dateTime, uint idEstate, bool isActive);
    event AdStatusChanged(address owner, uint dateTime, uint idAd, uint idEstate, AdStatus adStatus);
    event FundsBack(address to, uint amount, uint dateTime);
    event EstatePurchased(address adOwner, address buyer, uint idAd, uint idEstate, AdStatus adStatus, uint dateTime, uint price);



    modifier enoughValue(uint value, uint price) {
        require(value >= price, unicode"У вас недостаточно средств");
        _;
    }

    modifier onlyEstateOwner(uint idEstate) {
        require(estates[idEstate].owner == msg.sender, unicode"Вы не владелец данной недвижимости");
        _;
    }

    modifier idActiveEstate(uint idEstate) {
        require(estates[idEstate].isActive, unicode"Данная недвижимость недоступна");
        _;
    }

    modifier isClosedAd(uint idAd) {
        require(ads[idAd].adStatus == AdStatus.Opened, unicode"Данное объявление закрыто");
        _;
    }



    function createEstate(uint size, string memory _estateAddress, EstateType esType) public {
        require(msg.sender == owner, unicode"Только владелец контракта может создавать недвижимость");
        require(size > 1, unicode"Площадь должна быть больше единицы");
        estates.push(Estate(size, _estateAddress, msg.sender, esType, true, estates.length + 1));
        emit EstateCreated(msg.sender, estates.length, block.timestamp, esType);
    }


    function createAd(uint idEstate, uint price) public onlyEstateOwner(idEstate) idActiveEstate(idEstate) {
        ads.push(Advertisement(msg.sender, address(0), price, idEstate, block.timestamp, AdStatus.Opened, ads.length));
        emit AdCreated(msg.sender, ads.length, block.timestamp, idEstate, price);
    }


    function updateEstateStatus(uint idEstate, bool isActive) public onlyEstateOwner(idEstate) {
        estates[idEstate].isActive = isActive;

        if (!isActive) {
            for (uint i = 0; i < ads.length; i++) {
                if (ads[i].idEstate == idEstate && ads[i].adStatus == AdStatus.Opened) {
                    ads[i].adStatus = AdStatus.Closed;
                    emit AdStatusChanged(msg.sender, block.timestamp, i, idEstate, AdStatus.Closed);
                }
            }
        }

        emit EstateStatusChanged(msg.sender, block.timestamp, idEstate, isActive);
    }

    function updateAdStatus(uint idAd, AdStatus newStatus) public {
    require(msg.sender == ads[idAd].owner, unicode"Вы не владелец этого объявления");
    ads[idAd].adStatus = newStatus;
    emit AdStatusChanged(msg.sender, block.timestamp, idAd, ads[idAd].idEstate, newStatus);
    }

    function withdraw(uint amount) public {
        require(amount <= balances[msg.sender], unicode"Недопустимая сумма");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

   function buyEstate(uint idEstate) public payable {
    require(estates[idEstate].isActive, unicode"Данная недвижимость НЕ в статусе active");
    require(msg.value <= ads[idEstate].price, unicode"Недостаточно средств для приобретения");
    require(address(this).balance >= msg.value, unicode"Недостаточно средств на контракте");
    require(estates[idEstate].owner != msg.sender, unicode"Вы не можете купить свою собственную недвижимость");

    payable(estates[idEstate].owner).transfer(msg.value);

    ads[idEstate].adStatus = AdStatus.Closed;
    estates[idEstate].isActive = false;
    
    balances[msg.sender] -= ads[idEstate].price;
    emit FundsBack(address(this), msg.value, block.timestamp);
    emit EstatePurchased(estates[idEstate].owner, msg.sender, ads.length - 1, idEstate, AdStatus.Closed, block.timestamp,msg.value);
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function getAds() public view returns (Advertisement[] memory) {
        return ads;
    }

    function getEstates() public view returns (Estate[] memory) {
        return estates;
    }

    event paid(address _to, uint256 _amount); 
    
    function toPay(address user) public payable {
        require(msg.value > 0, unicode"Итоговая сумма должна быть больше нуля");
        balances[user] += msg.value;
        emit paid(user, msg.value);
    }
}
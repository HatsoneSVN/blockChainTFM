// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// Informacion del Smart Contract
// Nombre: smart para la traza de creacion y distribucion de automoviles
// Logica: Implementa un sistema de compraventa de coches
// Declaracion del Smart Contract - Auction
contract CarTracker{ 
    // ----------- Variables (datos) -----------
    address public contractOwner;
    bool public isActive;
    string public msgTransaction;
    bool public isPayable;
    struct Car{
        string carId;
        string brand;
        string tuition;
        uint year;
        string color;
        bool sold;
        string typeCar; 
    }
    enum statusTransaction{
        onTheWay,
        processing,   
        comingOut
    }
    struct location{
        string locationId;
        string locationName;
        string locationType;
    }
    struct TransactionCar{
        string transactionId;
        string localtionId;
        address Owner;
        address supplier;
        uint oldPrice;
        uint newPrice;
        string description;
    }
    uint256[] public timestamp ;
    string[] public idTransactions;
    string[] public idCars;
    string[] public idLocation;
    mapping(string => TransactionCar) private transactions;
    mapping(string => Car) private carsRegister;
    mapping(string => location) private locationRegister;
    mapping(address => mapping(string => bool)) private wallet;
    mapping(string => mapping(uint256 => statusTransaction)) private status;
    event eventNewTransaction
    (
        string msgTransaction,
        string description,
        address contractOwner,
        uint startPrice,
        uint finalPrice
    );
    event eventTransactionEnd(
        string msgTransaction,
        string description,
        address contractOwner,
        uint startPrice,
        uint finalPrice
    );
    event createCarEvent(
        string msgTransaction,
        string carId,
        string brand,
        string tuition,
        uint year,
        string color,
        bool sold,
        string typeCar
    );
    event createLocationEvent(
        string msgLocationCreate,
        string idLocation,
        string locationName,
        string locationType
    );
   event fail(
       string msgFail
   );
   modifier autoExistsAndIsFirstTransaction(string memory carId){
       require(carsRegister[carId].year == 0 , "El coche ya existe");
       require(idTransactions.length > 0 , "Solo se pueden introducir coches en la primera transaccion");
       _;
   }
   modifier contractActive(){
       require(isActive, "Contrato finalizado");
       _;
   }
    constructor(){
        contractOwner = msg.sender;
        isActive = true;
    }
    function createAndAddCar( string memory carId,
        string memory brand,
        string memory tuition,
        uint year,
        string memory color,
        bool sold,
        string memory typeCar ) public autoExistsAndIsFirstTransaction(carId){
        require(msg.sender == contractOwner);
        carsRegister[carId] = Car(carId , brand , tuition , year  , color , sold , typeCar);
        idCars.push(carId);
    }
    function createLocation(string memory locationId , string memory locationName , string memory locationType) public{
        require(msg.sender == contractOwner);
        locationRegister[locationId] = location(locationId , locationName ,locationType);
        idLocation.push(locationId);
        emit createLocationEvent("Nueva situacion registrada con exito " , locationId , locationName , locationType );
    }
    function transactionStart(
        string memory transactionId  , 
        string memory localtionId , 
        address Owner , 
        address supplier , 
        uint oldPrice ,
        uint newPrice, 
        string memory description,
        string memory carId,
        string memory brand,
        string memory tuition,
        uint year,
        string memory color,
        bool sold,
        string memory typeCar ) public contractActive(){
        require(msg.sender == contractOwner);
        if(idTransactions.length == 0){
            createAndAddCar(carId,brand,tuition,year,color,sold,typeCar);
        }
        timestamp.push(block.timestamp);
        transactions[transactionId] = TransactionCar(transactionId ,  localtionId , Owner , supplier , oldPrice , newPrice , description);
        status[transactionId][block.timestamp] = statusTransaction.onTheWay;
        idTransactions.push(transactionId);
        emit eventNewTransaction("Nuevo inicio de transaccion" , description , contractOwner , oldPrice , newPrice);
    }
    function transactionProcessing(
        string memory transactionId , 
        string memory localtionId , 
        address Owner , 
        address supplier , 
        uint oldPrice ,
        uint newPrice, 
        string memory description,
        string memory locationId , 
        string memory locationName , 
        string memory locationType ) public contractActive(){
        require(msg.sender == contractOwner);
        createLocation(locationId , locationName ,locationType);
        timestamp.push(block.timestamp);
        transactions[transactionId] = TransactionCar(transactionId  , localtionId , Owner , supplier , oldPrice , newPrice , description);
        status[transactionId][block.timestamp] = statusTransaction.processing;
        idTransactions.push(transactionId);
        emit eventNewTransaction("Nueva transaccion ejecutada con exito" , description , contractOwner , oldPrice , newPrice);
    }
    function transactionEnding(string memory transactionId ,  string memory localtionId , address Owner , address supplier , uint oldPrice ,uint newPrice, string memory description ) public contractActive(){
        require(!isActive , "La ultima gestion ya fue efectuada con exito");
        require(msg.sender == contractOwner);
        timestamp.push(block.timestamp);
        transactions[transactionId] = TransactionCar(transactionId , localtionId , Owner , supplier , oldPrice , newPrice , description);
        status[transactionId][block.timestamp] = statusTransaction.comingOut;
        idTransactions.push(transactionId);
        emit eventNewTransaction("Transaccion finalizada" , description , contractOwner , oldPrice , newPrice);
    }
    function getTransactionsData() public view returns (string[] memory){
        string[] memory transactionData;
        string memory transactionRegisterKey;
        for(uint i = 0; i < idTransactions.length; i++){
            transactionRegisterKey = idTransactions[i];
            transactionData[i] = string.concat("Id Transaccion : ", transactions[transactionRegisterKey].transactionId ," || Matricula : " ,carsRegister[transactionRegisterKey].tuition ," || Marca : " ,carsRegister[transactionRegisterKey].brand);
        }
        return transactionData;
    }
    function getAllCars() public view returns (string[] memory){
        string[] memory carsData;
        string memory carsRegisterKey;
        for(uint i = 0; i < idCars.length; i++){
            carsRegisterKey = idCars[i];
            carsData[i] = string.concat("Id Automovil : ", carsRegister[carsRegisterKey].carId ," || Matricula : " ,carsRegister[carsRegisterKey].tuition ," || Marca : " ,carsRegister[carsRegisterKey].brand);
        }
        return carsData;
    }
    function getOneTransaction(string memory transactionId ) public view returns (TransactionCar memory){
        return transactions[transactionId];
    }
    /*
    function addNewPayTransaction() public payable {
        if(activeTransaction == true){
            checkIfAuctionEnded();
        } else {
            if (msg.value > highestPrice && msg.value > basePrice){
                
                highestBidder.transfer(highestPrice);
                
                // Actualiza el nombre y precio al NUEVO maximo postor
                highestBidder = payable(msg.sender);
                highestPrice = msg.value;
                
                // Se emite un evento
                emit Status("Nueva puja mas alta, el ultimo postor tiene su dinero de vuelta");
            } else {
                // Se emite un evento
                emit Status("La puja no es posible, no es lo suficientemente alta");
                revert("La puja no es posible, no es lo suficientemente alta");
            }
        }
    }
    function checkIfAuctionEnded() public{
        if (block.timestamp > (createdTime + secondsToEnd)){
            // Finaliza la subasta
            activeContract = false;
            
            // Transfiere el dinero (maxima puja) al propietario original de la subasta
            newOwner = highestBidder;
            originalOwner.transfer(highestPrice);
            
            // Se emiten varios eventos
            emit Status("La subasta ha finalizado");
            emit Result("El ganador de la subasta ha sido:", highestBidder);
        } else {
            revert("La subasta esta activa");
        }
    }
    */
    
} 
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/drafts/Counters.sol";

contract CryptoFax is ERC721Full {
    
    constructor() ERC721Full('CryptoFax', 'CARS') public {}
    
    using Counters for Counters.Counter; 
    Counters.Counter token_IDs;
    
    struct Car {
        string VIN;
        uint accidents;
    }
    
    mapping(uint => Car) public cars;
    
    event Accident(uint token_id, string report_uri);
    
    function registerVehicle(
        address owner,
        string memory vin,
        string memory token_uri)
        public returns(uint) {
            token_IDs.increment();
        //incrmeent function is allowed because we're using Counters.Counters
        uint token_ID =  token_IDs.current();
        
        _mint(owner, token_ID);
        
        _setTokenURI(token_ID, token_uri);
        return token_ID;
    }
    
    function reportAccident(uint token_ID,
                            string memory report_uri) public returns(uint) {
                                cars[token_ID].accidents += 1;
                                emit Accident(
                                    token_ID, report_uri);
                                
                                return cars[token_ID].accidents;
    }
}
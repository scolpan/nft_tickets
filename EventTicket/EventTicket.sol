pragma solidity ^0.5.5;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/drafts/Counters.sol";

//IPFS to use ipfs://bafybeibqus6sbwtiqz2ymjxwmr6f2jevpu22zijt6qsipmgjpxtq3ragnm

contract EventTicket is ERC721Full, Ownable {
    
    constructor () ERC721Full('EventTicket', 'ETCKT') public { }
    
    using Counters for Counters.Counter;
    
    Counters.Counter token_ids;
    
    struct Ticket {
        address owner;
        //uint serial;
        uint timesSold;
    }
    
    mapping(uint => Ticket) public tickets;
    
    
    event Sale(uint token_id 
               //string report_uri  --we can store an addition report uri where we can put ticket sale transaction info in pinata
               );
    
    
    //Ticket can be registered by the owner of the contract.
    function ticketRegister(string memory token_uri) public onlyOwner returns (uint) {
        
    
        token_ids.increment();
        uint token_id = token_ids.current();
        
        _mint(owner(), token_id);
        
        _setTokenURI(token_id, token_uri);
        
        tickets[token_id] = Ticket(owner(), 0);
        
        return token_id;
        
    }
    
    //Initial ticket sale needs to be executed by the owner of the contract.
    function initialTicketSale(uint token_id, address to) public onlyOwner returns (uint) {
        
        tickets[token_id].timesSold += 1;
        
        emit Sale(token_id);
        
        safeTransferFrom(owner(), to, token_id);
        
        //Set the new owner and pass on the timesSold var.
        tickets[token_id] = Ticket(to, tickets[token_id].timesSold);
        
        return tickets[token_id].timesSold;
        
    }
    
    //Resale can be done by the current owner of the ticket
    function ticketResale(uint token_id, address to) public returns (uint) {
        
        tickets[token_id].timesSold += 1;

        emit Sale(token_id);
        
        safeTransferFrom(msg.sender, to, token_id);
        
        //Set the new owner and pass on the timesSold var.
        tickets[token_id] = Ticket(to, tickets[token_id].timesSold);

        return tickets[token_id].timesSold;
        

    }
    
    

    
}
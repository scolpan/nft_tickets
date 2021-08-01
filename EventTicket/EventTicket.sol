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
        string owner_name;
        string owner_email;
        address owner;
        uint timesSold;
    }
    
    mapping(uint => Ticket) public tickets;
    
    //mapping(uint => TicketHolder) public holders;
    
    
    event Sale(uint token_id 
               //string report_uri  --we can store an addition report uri where we can put ticket sale transaction info in pinata
               );
    
    
    //Ticket can be registered by the owner of the contract.
    function ticketRegister(string memory token_uri) public onlyOwner returns (uint) {
        
        token_ids.increment();
        uint token_id = token_ids.current();
        
        _mint(owner(), token_id);
        
        _setTokenURI(token_id, token_uri);
        
        tickets[token_id] = Ticket("", "", owner(), 0);
        
        return token_id;
        
    }
    
    
    function ticketPurchase(string memory name, string memory email) public payable returns (uint) {
        
        uint returnChange;
        uint token_id;
        address payable owner_address;
        
        token_id = getAvailableToken();
        
        require(token_id != 0, 'There are no available tickets for this event.');
        require(msg.value >= 20 finney, 'The amount you sent is insufficient. Ticket price is 20 finney.');
        
        //Cast owner address as payable
        owner_address = address(uint160(owner()));
        
        //Calculate change
        returnChange = msg.value - 20 finney;
        
        //Transfer the Ticket
        initialTicketSale(token_id, msg.sender);
        
        tickets[token_id].timesSold += 1;
        
        //Store name and address of the new owner and pass on the timesSold var.
        tickets[token_id] = Ticket(name, email, msg.sender, tickets[token_id].timesSold);
        
        //Give back change
        msg.sender.transfer(returnChange);
        
        //Pay the owner
        owner_address.transfer(20 finney);
        
    }
    
    
    function getAvailableToken() internal view returns (uint) {
        
        uint token_id = 0;
        
        //Loops through all the tokens and returns an available one, if unavailable, returns 0.
        for (uint i=1; i <= token_ids.current(); i++) {
            if (tickets[i].timesSold == 0) {
                token_id = i;
                break;
            }
        }
    
        return token_id;
    }
    
    
    function initialTicketSale(uint token_id, address to) private {
        
        //Perform the transfer
        _transferFrom(owner(), to, token_id);
        
        emit Sale(token_id);
        
    }
    
    //Resale can be done by the current owner of the ticket
    function ticketResale(uint token_id, address to) public returns (uint) {
        
        tickets[token_id].timesSold += 1;

        emit Sale(token_id);
        
        safeTransferFrom(msg.sender, to, token_id);
        
        //Set the new owner and pass on the timesSold var.
        //tickets[token_id] = Ticket(to, tickets[token_id].timesSold);

        return tickets[token_id].timesSold;
        

    }
    
    

    
}
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
    
    struct Offer {
        string offer_name;
        string offer_email;
        address payable offer_address;
        uint offer_amount;
        bool offer_closed;
    }
    
    mapping(uint => Ticket) public tickets;
    
    //mapping(uint => Offer[]) public offers;
    mapping(uint => Offer) public offers;
    
    event PurchaseOffer(uint token_id, uint amount);
    
    
    event Sale(uint token_id 
               //string report_uri  --we can store an addition report uri where we can put ticket sale transaction info in pinata
               );
    
    
    event Reject(uint token_id);
    
    //Ticket can be registered by the owner of the contract.
    //function ticketRegister(string memory token_uri) public onlyOwner returns (uint) {
    function ticketRegister() public onlyOwner returns (uint) {
        
        token_ids.increment();
        uint token_id = token_ids.current();
        
        _mint(owner(), token_id);
        
        //_setTokenURI(token_id, token_uri);
        
        tickets[token_id] = Ticket("", "", owner(), 0);
        
        return token_id;
        
    }
    
    //Purchase option available to the general public
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
    
    
    function offerPurchase(uint token_id, string memory name, string memory email) public payable returns (uint) {
        
        require(msg.value > 0 finney && msg.value <= 40 finney, "Offer must be greater than 0 and less than or equal to 40 finney!");
        require(tickets[token_id].timesSold > 0, 'Ticket is not available for an offer!');
        require(offers[token_id].offer_amount == 0, 'There is already an offer pending for this ticket!');
        
        //Add as an offer
        //offers[token_id].push(Offer(name, email, msg.sender, msg.value, false));
        offers[token_id] = Offer(name, email, msg.sender, msg.value, false);
        
        emit PurchaseOffer(token_id, msg.value);
        
    }
    
    
    function acceptOffer(uint token_id) public {
        
        //Ensure the accepting party is the owner
        require(ownerOf(token_id) == msg.sender, 'You are not the owner of this ticket!');
        //Ensure an open offer exists for this ticket.
        require(offers[token_id].offer_amount > 0 && !offers[token_id].offer_closed, 'This ticket does not have any offers!');
        
        
        //Increase the timesSold counter.
        tickets[token_id].timesSold += 1;
        
        //Transfer ownership (data)
        tickets[token_id] = Ticket(offers[token_id].offer_name, offers[token_id].offer_email, offers[token_id].offer_address, tickets[token_id].timesSold);
        
        //Close the offer
        offers[token_id].offer_closed = true;
        
        //Transfer the token to the offering party
        _transferFrom(msg.sender, offers[token_id].offer_address, token_id);
        
        //Transfer the offered funds to the accepting party.
        msg.sender.transfer(offers[token_id].offer_amount);
        
        emit Sale(token_id);
        
    }
    
    
    function rejectOffer(uint token_id) public {
        
        //Ensure the accepting party is the owner
        require(ownerOf(token_id) == msg.sender, 'You are not the owner of this ticket!');
        //Ensure an open offer exists this ticket.
        require(offers[token_id].offer_amount > 0 && !offers[token_id].offer_closed, 'This ticket does not have any offers!');
        
        //Close the offer
        offers[token_id].offer_closed = true;
        
        //Refund the offering party
        offers[token_id].offer_address.transfer(offers[token_id].offer_amount);
        
        emit Reject(token_id);
        
    }
    
    
    
    //Gets the next unsold ticket (token_id)
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
    
    
    

    
}
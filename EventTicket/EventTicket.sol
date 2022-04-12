pragma solidity ^0.5.5;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/drafts/Counters.sol";


//IPFS to use ipfs://bafybeibqus6sbwtiqz2ymjxwmr6f2jevpu22zijt6qsipmgjpxtq3ragnm

contract EventTicket is ERC721Full, Ownable {
    
    constructor () ERC721Full('EventTicket', 'ETCKT') public { }
    
    using Counters for Counters.Counter;
    
    Counters.Counter event_ids;
    Counters.Counter token_ids;
    
    
    struct Ticket {
        uint event_id;
        string owner_name;
        string owner_email;
        address owner;
        uint timesSold;
    }

    struct Event {
        //uint event_id;
        string event_name;
        uint event_time;
        uint event_expiry;
        string event_host;
    }
    
    struct Offer {
        uint offer_time;
        uint offer_expiry;
        string offer_name;
        string offer_email;
        address payable offer_address;
        uint offer_amount;
        bool offer_closed;
        string status;
    }
    
    struct Redeem {
        uint redeem_time;
        uint redeem_expiry;
        uint event_id;
    }

    struct Token {
        uint token_id;
    }

    mapping(address => Token[]) public tokens;

    //mapping(address => uint) public tokenAmountPerAddress;

    mapping(uint => Ticket) public tickets;

    mapping(uint => Event) public events;
    
    //mapping(uint => Offer[]) public offers;
    mapping(uint => Offer) public offers;

    mapping(uint => Redeem) public redeemOffers; //an offer can be made to a token

    event EventRegistration(uint event_id, string name);

    event RedeemTicket(address ticket_holder, uint event_id);

    event PurchaseOffer(uint token_id, uint amount);
    
    event Sale(uint token_id,
               string name
               //string report_uri  --we can store an addition report uri where we can put ticket sale transaction info in pinata
               );
    
    event Reject(uint token_id);


    //Register an event before minting any ticket tokens
    //Ticket can be registered by the owner of the contract.
    //function ticketRegister(string memory token_uri) public onlyOwner returns (uint) {

    function eventRegister(string memory eventName, string memory eventHost, uint number) public onlyOwner {

        uint event_id;
        uint token_id;
        uint numberToMint;        

        event_ids.increment();
        event_id = event_ids.current();

        //A single ticket will need two minted tokens, one will be used to redeem (transferred back to issuing contract during the time of redeem)
        //The other one will always remain inside the wallet of the purchaser. E.g. We will only redeem the odd numbered tokens.
        numberToMint = number * 2;

        events[event_id] = Event(eventName, now, now + 24 hours, eventHost);

        for (uint i=1; i<=numberToMint; i++) {
        
            token_ids.increment();
            token_id = token_ids.current();
            
            _mint(owner(), token_id);
            
            //_setTokenURI(token_id, token_uri);
            
            tickets[token_id] = Ticket(event_id, "", "", owner(), 0);
        
        }        

        emit EventRegistration(event_id, eventName);

    }
    

    
    //Purchase option available to the general public
    function ticketPurchase(uint event_id, string memory name, string memory email) public payable returns (uint) {
        
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
        //Transfer the other copy.
        initialTicketSale(token_id - 1, msg.sender);

        tickets[token_id].timesSold += 1;
        
        //Store name and address of the new owner and pass on the timesSold var.
        tickets[token_id] = Ticket(event_id, name, email, msg.sender, tickets[token_id].timesSold);

        //Associate token with the purchaser address 
        tokens[msg.sender].push(Token(token_id));
        
        //Give back change
        msg.sender.transfer(returnChange);
        
        //Pay the owner
        owner_address.transfer(20 finney);
        
        emit Sale(token_id, name);
        
    }
    
    
    function offerPurchase(uint token_id, string memory name, string memory email) public payable returns (uint) {
        
        //Only allow even numbered (main tokenid), reject odd numbered (redeemable tokenid) tokenids

        require(msg.value > 0 finney && msg.value <= 40 finney, "Offer must be greater than 0 and less than or equal to 40 finney!");
        require(tickets[token_id].timesSold > 0, 'Ticket is not available for an offer!');
        //Ensure that either the previous offer is closed or the token has never received an offer yet (amount = 0).
        require(offers[token_id].offer_amount == 0 || offers[token_id].offer_closed, 'There is already an offer pending for this ticket!');
        
        //Add as an offer
        //offers[token_id].push(Offer(name, email, msg.sender, msg.value, false));
        offers[token_id] = Offer(now, now + 5 minutes, name, email, msg.sender, msg.value, false, 'active');
        
        emit PurchaseOffer(token_id, msg.value);
        
    }
    
    
    function acceptOffer(uint token_id) public {
        
        //Ensure the accepting party is the owner
        require(ownerOf(token_id) == msg.sender, 'You are not the owner of this ticket!');
        //Ensure an open offer exists for this ticket.
        require(offers[token_id].offer_amount > 0 && !offers[token_id].offer_closed, 'This ticket does not have any offers!');
                
        uint sellerTokenAmt;  

        //Increase the timesSold counter.
        tickets[token_id].timesSold += 1;
        
        //Transfer ownership (data)
        tickets[token_id] = Ticket(tickets[token_id].event_id, offers[token_id].offer_name, offers[token_id].offer_email, offers[token_id].offer_address, tickets[token_id].timesSold);
        
        //Close the offer
        offers[token_id].status = 'accepted';
        offers[token_id].offer_closed = true;
        
        //Transfer the token pair to the offering party
        _transferFrom(msg.sender, offers[token_id].offer_address, token_id);
        _transferFrom(msg.sender, offers[token_id].offer_address, token_id - 1);

        //Associate token with the purchaser address
        tokens[offers[token_id].offer_address].push(Token(token_id));

        sellerTokenAmt = tokens[msg.sender].length;

        //Disassociate token with the seller address 
        for (uint i=0; i < sellerTokenAmt; i++) {
            if (tokens[msg.sender][i].token_id == token_id) {
                //Remove association. We do this by copying the last array value over the value we want to remove and then 
                //removing the last array (.pop).
                tokens[msg.sender][i] = tokens[msg.sender][sellerTokenAmt - 1];
                tokens[msg.sender].pop;
            }
        }

        //Transfer the offered funds to the accepting party.
        msg.sender.transfer(offers[token_id].offer_amount);
        
        emit Sale(token_id, offers[token_id].offer_name);
        
    }
    
    
    function rejectOffer(uint token_id) public {
        
        //Ensure the accepting party is the owner
        require(ownerOf(token_id) == msg.sender, 'You are not the owner of this ticket!');
        //Ensure an open offer exists this ticket.
        require(offers[token_id].offer_amount > 0 && !offers[token_id].offer_closed, 'This ticket does not have any offers!');
        
        //Close the offer
        offers[token_id].status = 'rejected';
        offers[token_id].offer_closed = true;
        
        //Refund the offering party
        offers[token_id].offer_address.transfer(offers[token_id].offer_amount);
        
        emit Reject(token_id);
        
    }
    
    
    function collectRefund(uint token_id) public {
        
        require(offers[token_id].offer_address == msg.sender, 'This offer was not made by you!');
        require(now >= offers[token_id].offer_expiry, 'The offer has not expired yet!');
        require(!offers[token_id].offer_closed, 'This offer is no longer active!');
        
        //Close the offer
        offers[token_id].status = 'refunded';
        offers[token_id].offer_closed = true;
        
        msg.sender.transfer(offers[token_id].offer_amount);
        
    }


    function offerRedeem(address token_holder, uint event_id) public onlyOwner {

        //This function will be invoked when the ticket holder will display his/her ticket (wallet address as a barcode)
        //in which the ticket holder will get a notification to accept or reject.
        //Create an event variable to see if the wallet being scanned has a ticket for the event or not        



    }

    function acceptRedeem(uint token_id) public {
    


    }
    

    //Gets the next unsold ticket (token_id)
    function getAvailableToken() internal view returns (uint) {
        
        uint token_id = 0;
        
        //Loops through all the tokens and returns an available one, if unavailable, returns 0.
        //for (uint i=1; i <= token_ids.current(); i++) {
        //Loops in increments of two and returns an available token.
        for (uint i=2; i <= token_ids.current(); i+=2) {
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
        
        
    }
    
}
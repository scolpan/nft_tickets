import requests
import json 
import os
from dotenv import load_dotenv
from pathlib import Path
#from web3.auto import w3
from web3 import Web3
from datetime import datetime

load_dotenv()

#Get private key for wallet
private_key = os.getenv("ACCT_PRIV_KEY")

#Connect to Rinkeby through infura
w3 = Web3(Web3.HTTPProvider('https://rinkeby.infura.io/v3/9dd4592201cc40b395d2e08cd2ee89a4'))

#Compatibility with POA
from web3.middleware import geth_poa_middleware
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

#Set account from private key
account = w3.eth.account.from_key(private_key)

#Initiate contract
def initContract():
    with open(Path("EventTicket.json")) as json_file:
        abi = json.load(json_file)
    return w3.eth.contract(address=os.getenv("EVENTTICKET_ADDRESS"), abi=abi)

ticket = initContract()

#Set the tickets variable
tickets = ticket.functions.tickets
offers = ticket.functions.offers

def transactionBuilder(tx, amount):
    build_tx = tx.buildTransaction(
        {"from": account.address,
        "value": Web3.toWei(amount, 'finney'),
        "nonce": w3.eth.getTransactionCount(account.address)}
    )

    sign_tx = w3.eth.account.signTransaction(build_tx, private_key)

    tx_hash = w3.eth.sendRawTransaction(sign_tx.rawTransaction)

    return tx_hash


def ticketPurchase(name, email, amount):
    
    tx = ticket.functions.ticketPurchase(name, email)
    tx_hash = transactionBuilder(tx, amount)

    receipt = w3.eth.waitForTransactionReceipt(tx_hash)

    return receipt


def ticketRegister(numberOfTickets):
    
    tx = ticket.functions.ticketRegister(numberOfTickets)
    tx_hash = transactionBuilder(tx, 0)

    receipt = w3.eth.waitForTransactionReceipt(tx_hash)

    return receipt


def getAllSales():
    ticket_filter = ticket.events.Sale.createFilter(
        fromBlock="0x0"
        #,argument_filters={"token_id": 2}
    )
    return ticket_filter.get_all_entries()


def getAllPurchases():
    #All purchases
    numberSold = len(getAllSales())

    for tokenId in range(numberSold):    
        purchased = tickets(tokenId + 1).call()
        # Times sold > 0
        if purchased[3] > 0:

            print ('Token: ' + str(tokenId + 1)  + ', Owner: ' + str(purchased[0]) + ', Email: ' + str(purchased[1]) + 
                   ', Wallet: ' + str(purchased[2]) + ', times sold: ' + str(purchased[3]))


def getLastPurchase():
    #Last purchase
    purchased_token_id = getAllSales()[-1]['args']['token_id']
    purchased = tickets(purchased_token_id).call()

    print ('Owner name: ' + str(purchased[0]) + ', Email: ' + str(purchased[1]) + 
        ', Wallet: ' + str(purchased[2]) + ', No of times sold: ' + str(purchased[3]))    


#All offers
def getAllOffers():

    numberSold = len(getAllSales())

    for tokenId in range(numberSold):    
        offer = offers(tokenId + 1).call()
        #Open offers (amount > 0 and offer still open)
        if int(offer[5]) > 0: #and offer[6] == False:
            
            print('Token: ' + str(tokenId + 1) + ', Offer time: ' + str(datetime.fromtimestamp(offer[0]).isoformat()) + ', Offer expiry: ' + str(datetime.fromtimestamp(offer[1]).isoformat()) + ', Offer name: ' + offer[2] + ', Offer email: ' + offer[3] + ', Offer address: ' + offer[4] + ', Offer amount: ' + str(int(offer[5]) / 1000000000000000) + ' finney, Offer closed: ' + str(offer[6]) + ', Offer status: ' + offer[7])
    


def getOffersMadeToMe():

    numberSold = len(getAllSales())
    for tokenId in range(numberSold):    
        offer = offers(tokenId + 1).call()        
        #Open offers
        if int(offer[5]) > 0:
            #Offers made to me
            if ticket.functions.ownerOf(tokenId + 1).call() == account.address:
                print('Token: ' + str(tokenId + 1) + ', Offer time: ' + str(datetime.fromtimestamp(offer[0]).isoformat()) + ', Offer expiry: ' + str(datetime.fromtimestamp(offer[1]).isoformat()) + ', Offer name: ' + offer[2] + ', Offer email: ' + offer[3] + ', Offer address: ' + offer[4] + ', Offer amount: ' + str(int(offer[5]) / 1000000000000000) + ' finney, Offer closed: ' + str(offer[6]) + ', Offer status: ' + offer[7])



#Make an offer to purchase
def offerPurchase(tokenId, name, email, amount):
    
    tx = ticket.functions.offerPurchase(tokenId, name, email)
    tx_hash = transactionBuilder(tx, amount)

    receipt = w3.eth.waitForTransactionReceipt(tx_hash)

    return receipt


def acceptOffer(tokenId):
    
    tx = ticket.functions.acceptOffer(tokenId)
    tx_hash = transactionBuilder(tx, 0)

    receipt = w3.eth.waitForTransactionReceipt(tx_hash)

    return receipt    


def rejectOffer(tokenId):

    tx = ticket.functions.rejectOffer(tokenId)
    tx_hash = transactionBuilder(tx, 0)

    receipt = w3.eth.waitForTransactionReceipt(tx_hash)

    return receipt        


def collectRefund(tokenId):

    tx = ticket.functions.collectRefund(tokenId)
    tx_hash = transactionBuilder(tx, 0)

    receipt = w3.eth.waitForTransactionReceipt(tx_hash)

    return receipt        
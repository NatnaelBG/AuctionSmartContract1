The following script can be used to auction NFTs. Digital as well as real world
assets can be turned to NFTs which can then be auctioned using the following
smart contract.

Functionalities:
    - The contract has "start", "bid", "withdraw", "end_auction" and "terminate_auction" functions. 

Things to note:
    - Once started, an auction CANNOT be stopped by seller. It can only be terminated by 
    the contract owner. This is a compromise done to avoid bad sellers from manipulating
    the auction. Meanwhile, this gives more power to the contract owner which can
    be seen as undesirable since the contract owner can be a bad actor as well.

    - The auction operates as traditional auction and starts from 0 ETH. 
        It then proceeds to go up depending on bid amounts from bidders.
    
    - The contract utilises "transfer" and "transferFrom" functions to transfer the NFT
        from seller to contract and contract to highest bidder or back to seller depending
        on the outcome of the bid. If there's a bid, the NFT will go to highest bidder, else
        it will be returned back to seller. The functions mentioned above are imported from
        the IERC721 interface.

    - The contract will set the address that deploys the contract as the seller account. 
        However, this can be changed so that whoever calls the "start" function becomes the seller.

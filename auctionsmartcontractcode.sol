//SPDX-License-Identifier: UNLICENSED

/*
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
*/
pragma solidity ^0.8;

interface IERC721 {
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
}

contract Auction2 {
    event AuctionStarted(address seller);
    event Bid(address indexed _sender, uint256 indexed _amount);
    event Withdraw(address indexed _bidder, uint256 _amount);
    event AuctionClosed(address highest_bidder, uint256 highest_bid);
    event AuctionTerminated(IERC721 nft, uint nftId);

    //custom data structure
    mapping(address => uint256) public bids;
    //built-in data structures
    bool public inProgress;
    bool public auction_ended;
    bool public auction_terminated;
    uint256 public end_time;
    uint256 public highest_bid;
    address public highest_bidder;
    address payable public owner;

    //Interface 
    IERC721 public nft;
    uint public nftId;

    /*The constructor doesn't take any inputs but once the contract is deployed, 
    it'll make the contract deployer the seller. 
    The owner account is hard coded into the contract which has it's pros and cons.
    The owner account can be the wallet address of the auction platform.
    Pro - ensures the contract has an overseer that can step in when needed.
    Con - it give the owner account higher privilege which will be seen in the 
    end_auction and terminate_auction functions below.
    */

    constructor() {
        owner = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        seller = payable(msg.sender);
    }

    address public seller = payable(msg.sender);

    //modifiers
    //onlyOwner modifier gives execution previleges only to the owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //onlyOwner modifier gives execution previleges only to the owner of the contract
    modifier onlySeller() {
        require(msg.sender == seller);
        _;
    }


    /*For the start function below, the account that calls this function becomes the seller. 
    Calling this function will transfer the NFT form seller to the contract. 
    The seller must also input the number of the days they want the auction to run for.*/

    function start(IERC721 _nft, uint _nftId, uint _auction_duration_in_days) external onlySeller{
        require(_auction_duration_in_days <= 30); //the auction date is set to not be more than 30 days. This can be changed.
        nft = _nft;
        nftId = _nftId;
        nft.transferFrom(seller, address(this), _nftId);
        require(!inProgress, "auction in progress");
        require(msg.sender == seller, "you didn't start the auction");
        inProgress = true;
        end_time = block.timestamp + _auction_duration_in_days * 1 days;
        emit AuctionStarted(seller);
    }


    /*bid - any interested parties can bid on an NFT. However, the function prevents
        contract owner and sellers from bidding on their own auction*/

    function bid() external payable {
        require(inProgress, "Auction is no longer in progress");
        require(block.timestamp < end_time, "Auction no longer in progress");
        require(msg.value > highest_bid, "Please increase your bid");
        require(msg.sender != seller && msg.sender != address(0) && msg.sender != owner, "sender can't bid on their own auction");

        highest_bid = msg.value;
        highest_bidder = msg.sender;

        if (highest_bidder != address(0)) {
            bids[highest_bidder] = highest_bid;
        }

        emit Bid(highest_bidder, highest_bid);
    }

    /*The withdraw function allows bidders to withdraw their money if they're outbid.
        However, highest bidders cannot withdraw their bid. They can withdraw
        if only they're outbid by a new higher bid.*/

    function withdraw() external payable {
        uint256 bid_amount = bids[msg.sender];
        bids[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: bid_amount}("");
        require(success, "withdrawal failed");
        emit Withdraw(msg.sender, bid_amount);
    }

    /*The end_auction function can only be called by the seller or the owner.
        if there are bid on the NFT, it will transfer the NFT to the highest bidder.
        If not, it will transfer it back to the seller after which the seller can 
        relist the NFT for auction.

        The function has different levels of privilege for contract owner and seller.
        The seller can end the auction only after the auction date has passed (auction date
        is entered by seller when they start the auction. However, for security reasons, 
        the contract owner has a higher previlege and can end the auction at any time.*/

    function end_auction() public {
        require (msg.sender == seller || msg.sender == owner, "invalid account");
        if (msg.sender == seller) {
            require(inProgress, "auction hasn't started");
            require(block.timestamp >= end_time, "Auction in progress");
            require(!auction_ended, "Auction already closed");
        }
        auction_ended = true;
        inProgress = false;
        if (highest_bidder != address(0)) {
            // nft.transfer(highest_bidder, nftId); //changes
            (bool success, ) = seller.call{value: highest_bid}("");
            require(success, "Unable to transfer funds to seller");
        }
        else {
            nft.transfer(seller, nftId);
        }
        emit AuctionClosed(highest_bidder, highest_bid);
    }

    /*The terminate auction function below is a special function that can only be executed
    by the contract owner. In case the seller is engaging in fraud or any wrongdoings happen
    during the auction process, the contract owner can immediately stop the auction. */

    function terminate_auction() public onlyOwner {
        end_auction();
        emit AuctionTerminated(nft, nftId);
    }

}

pragma solidity ^0.5.0;

contract PictureAuction {
    address contractOwner;
    string contractName;
    constructor (string memory _name) public {
        contractOwner = msg.sender;
        contractName=_name;
    }

    //상품
    struct Item {
        string name;
        uint time;
    }

    Item[] public items;
 
    uint topBid;                 //최고 입찰가
    address payable topBidder;   //최고 입찰자
    address payable seller;      //입찰금액 지급 주소(to 상품 판매자)

    mapping (uint => address) productToOwner;   //상품의 주인 
    mapping (address => uint) bidCooltime;      //입찰 쿨 타임, 고의적인 반복입찰 방지

    //상품 등록
    function listUp(string memory _name) public {
        uint id = items.push(Item(_name, now + 1 minutes))-1;
        productToOwner[id] = msg.sender;
        seller = address(uint160(msg.sender));
        topBid = 0;
    }

    // @title 입찰, 입찰에는 다음과 같은 규칙이 있다.
    // * 입찰금이 본인의 계좌의 잔액 이하일 것
    // * 한 번 입찰가를 등록하면 30초동안 입찰할 수 없다.
    function bidOn(uint _id) public payable {
        require(items[_id].time <= now);
        require(msg.sender.balance >= msg.value);
        require(bidCooltime[msg.sender] < now);
       if(topBid < msg.value){
            //입찰가가 갱신되면, 전의 top Bidder에게 돈을 돌려주고,
            //갱신가를 top bid로, 갱신자를 top bidder로 설정
            topBidder.transfer(topBid);
            topBid = msg.value;
            topBidder =address(uint160(msg.sender));
        } 
        bidCooltime[msg.sender] = now + 30 seconds;
    }

    //경매 종료
    function closeAuc(uint _id) public {
        require(items[_id].time <= now);
        _reward(_id);
    }

    //경매 보상
    function _reward(uint _id) private {
        seller.transfer(topBid);            //돈 주고
        productToOwner[_id] = topBidder;    //상품 주인 바꿔주고
    }

    //경매 결과 확인(경매가 간보기)
    function ganjebi(uint _id) public view returns (string memory name, uint time, uint) {
        return (items[_id].name, items[_id].time, topBid);
    }
}
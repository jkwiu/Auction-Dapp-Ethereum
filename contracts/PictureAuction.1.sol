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
 
    uint topBid;                             //최고 입찰자
    address payable private seller;          //상품 판매자(등록자) 주소
    address topBidder;                       //최고 입찰자 주소, 마지막에 이 주소를 사용
    address payable private refundToBidder;  //더 높은 입찰자가 나타나면 전 입찰자에게 환불해줄 주소

    mapping (uint => address) productToOwner;            //상품의 소유자, 최고 입찰자가 나타나면 그 사람으로 변경
    mapping (address => uint) bidCooltime;               //입찰 쿨 타임, 고의적인 반복입찰 방지
    mapping (address => uint) bidMoney;                  //환불해줄 금액        

    //상품 등록
    function listUp(string memory _name) public {
        require(seller == address(0));
        uint id = items.push(Item(_name, now + 2 minutes))-1;
        productToOwner[id] = msg.sender;
        seller = msg.sender;
        topBid = 0;
    }

    // @title 입찰, 입찰에는 다음과 같은 규칙이 있다.
    // * 입찰금이 본인의 계좌의 잔액 이하일 것
    // * 한 번 입찰가를 등록하면 30초동안 입찰할 수 없다.
    function bidOn(uint _id) public payable {
        require(msg.value != 0);
        require(items[_id].time >= now);
        require(msg.sender.balance >= msg.value);
        require(bidCooltime[msg.sender] < now);
       if(topBid < msg.value){
            if(topBidder == address(0)){
                //첫 입찰자의 경우
                topBid = msg.value;
                topBidder = msg.sender;
                bidMoney[msg.sender]=topBid;
            }
            //전 입찰자에게 환불 후
            refundToBidder = address(uint160(topBidder));
            refundToBidder.transfer(topBid);
            //최고 입찰자 갱신
            topBid = msg.value;
            topBidder = msg.sender;
            bidMoney[msg.sender]=topBid;
        } else {
            //현재 최고 입찰가보다 낮으면 금액을 환불해 준다.
            refundToBidder = address(uint160(msg.sender));
            refundToBidder.transfer(msg.value);
        }
        bidCooltime[msg.sender] = now + 30 seconds;
    }

    //경매 종료
    function closeAuc(uint _id) public {
        require(items[_id].time < now);
        _reward(_id);
    }

    //경매 보상
    function _reward(uint _id) private {
        seller.transfer(topBid);            //돈 주고  ****이 방식은 후에, 낙찰자가 상품을 받은 후, 승인하여 돈을 판매자에게 줄 수 있도록 변경하자!!***
        productToOwner[_id] = topBidder;    //상품 주인 바꿔주고
    }

    //경매 결과 확인(경매가 간보기)
    function ganjebi(uint _id) public view returns (string memory name, uint time, uint) {
        return (items[_id].name, items[_id].time, topBid);
    }
}
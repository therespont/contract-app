// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract Main is ERC2771Recipient {
    struct MessageStruct {
        address FromAddress;
        address ToAddress;
        bytes MessageText;
        bytes MediaLink;
        uint256 MessageTimestamp;
        uint256 BlockHeight;
        address KeyLocation;
    }

    struct OpponentStruct {
        address Opponent;
        MessageStruct Messages;
    }

    struct ProfileStruct {
        string Picture;
        address[] Opponents;
        address[] BlockList;
    }

    event ProfileCreated(address indexed _Owner);
    event PictureChanged(address indexed _Address, string indexed _MediaLink);
    event Sent(address indexed _Sender, address indexed _Receiver);
    event BlockListAdded(
        address indexed _Owner,
        address indexed _BlockedAddress
    );
    event BlockListRemoved(
        address indexed _Owner,
        address indexed _BlockedAddress
    );

    address private contractOwner;
    mapping(address => mapping(address => MessageStruct[])) private Messages;
    mapping(address => ProfileStruct) private Profile;
    mapping(address => bool) private Profiles;
    mapping(address => mapping(address => bool)) private BlockList;

    constructor(address _trustedForwarder) {
        contractOwner = msg.sender;
        _setTrustedForwarder(_trustedForwarder);
    }

    function getTrustedForwarder() override public view returns (address){
        require(msg.sender == contractOwner);

        return super.getTrustedForwarder();
    }

    function setTrustedForwarder(address _trustedForwarder) public {
        require(msg.sender == contractOwner);

        _setTrustedForwarder(_trustedForwarder);
    }

    function CreateProfile(address _Owner) private {
        require(!Profiles[_Owner], "Address already has profile");

        Profile[_Owner] = ProfileStruct(
            "",
            Profile[_Owner].Opponents,
            Profile[_Owner].BlockList
        );

        Profiles[_Owner] = true;
    }

    function ChangePicture(string memory _MediaLink) public {
        require(Profiles[_msgSender()], "You never interact with the contract");

        Profile[_msgSender()].Picture = _MediaLink;

        emit PictureChanged(_msgSender(), _MediaLink);
    }

    function GetPicture(address _Opponent) public view returns (string memory) {
        return Profile[_Opponent].Picture;
    }

    function GetBlockList() public view returns (address[] memory) {
        return Profile[msg.sender].BlockList;
    }

    function AddBlockList(address _Opponent) public {
        require(_msgSender() != _Opponent, "Can not block own address");
        require(Profiles[_msgSender()], "You never interact with the contract");
        require(!BlockList[_msgSender()][_Opponent], "Address already blocked");

        BlockList[_msgSender()][_Opponent] = true;
        Profile[_msgSender()].BlockList.push(_Opponent);

        emit BlockListAdded(_msgSender(), _Opponent);
    }

    function ReBlockList(address _Opponent)
        private
        view
        returns (address[] memory)
    {
        require(Profiles[msg.sender], "You never interact with the contract");
        require(!BlockList[msg.sender][_Opponent], "Address is not blocked");

        address[] memory Blocked = new address[](
            Profile[msg.sender].BlockList.length - 1
        );
        uint256 BlockedIncrement = 0;
        for (uint256 i = 0; i < Profile[msg.sender].BlockList.length; i++) {
            if (Profile[msg.sender].BlockList[i] != _Opponent) {
                Blocked[BlockedIncrement] = Profile[msg.sender].BlockList[i];
                BlockedIncrement += 1;
            }
        }

        return Blocked;
    }

    function RemoveBlockList(address _Opponent) public {
        require(Profiles[_msgSender()], "You never interact with the contract");
        require(BlockList[_msgSender()][_Opponent], "Address is not blocked");

        BlockList[_msgSender()][_Opponent] = false;
        Profile[_msgSender()].BlockList = ReBlockList(_Opponent);

        emit BlockListRemoved(_msgSender(), _Opponent);
    }

    function Opponents(uint256 _BeforeHeight, uint256 _Limit)
        public
        view
        returns (OpponentStruct[] memory)
    {
        OpponentStruct[] memory OpponentList = new OpponentStruct[](_Limit);
        uint256 OpponentListLength = 0;

        if (Profile[msg.sender].Opponents.length > 0)
            for (
                uint256 i = Profile[msg.sender].Opponents.length - 1;
                i >= 0;
                i--
            ) {
                if (
                    _BeforeHeight > 0 &&
                    Messages[msg.sender][Profile[msg.sender].Opponents[i]][
                        Messages[msg.sender][
                            Profile[msg.sender].Opponents[i]
                        ].length - 1
                    ].BlockHeight <=
                    _BeforeHeight
                ) {
                    OpponentList[OpponentListLength] = OpponentStruct(
                        Profile[msg.sender].Opponents[i],
                        Messages[msg.sender][
                            Profile[msg.sender].Opponents[i]
                        ][
                            Messages[msg.sender][
                                Profile[msg.sender].Opponents[i]
                            ].length - 1
                        ]
                    );

                    OpponentListLength += 1;
                } else if (_BeforeHeight == 0 && OpponentListLength < _Limit) {
                    OpponentList[OpponentListLength] = OpponentStruct(
                        Profile[msg.sender].Opponents[i],
                        Messages[msg.sender][
                            Profile[msg.sender].Opponents[i]
                        ][
                            Messages[msg.sender][
                                Profile[msg.sender].Opponents[i]
                            ].length - 1
                        ]
                    );

                    OpponentListLength += 1;
                }

                if (i == 0) break;
            }

        return OpponentList;
    }

    function AMessage(address _Opponent)
        public
        view
        returns (MessageStruct memory)
    {
        require(msg.sender != _Opponent, "Can not get own message");

        return
            Messages[msg.sender][_Opponent][
                Messages[msg.sender][_Opponent].length - 1
            ];
    }

    function Message(
        address _Opponent,
        uint256 _BeforeHeight,
        uint256 _Limit
    ) public view returns (MessageStruct[] memory) {
        require(msg.sender != _Opponent, "Can not get own message");

        MessageStruct[] memory MessageList = new MessageStruct[](_Limit);
        uint256 MessageListLength = 0;

        if (Messages[msg.sender][_Opponent].length > 0)
            for (
                uint256 i = Messages[msg.sender][_Opponent].length - 1;
                i >= 0;
                i--
            ) {
                if (
                    _BeforeHeight > 0 &&
                    Messages[msg.sender][_Opponent][i].BlockHeight <=
                    _BeforeHeight &&
                    MessageListLength < _Limit
                ) {
                    MessageList[MessageListLength] = Messages[msg.sender][
                        _Opponent
                    ][i];

                    MessageListLength += 1;
                } else if (_BeforeHeight == 0 && MessageListLength < _Limit) {
                    MessageList[MessageListLength] = Messages[msg.sender][
                        _Opponent
                    ][i];

                    MessageListLength += 1;
                }

                if (i == 0) break;
            }

        return MessageList;
    }

    function SendMessage(
        address _ToAddress,
        bytes memory _MessageText,
        bytes memory _MediaLink,
        address _KeyLocation
    ) public {
        require(_msgSender() != _ToAddress, "Can not send message to yourself");

        require(bytes(_MessageText).length > 0, "Invalid message!");

        if (!Profiles[_msgSender()]) CreateProfile(_msgSender());

        if (Messages[_msgSender()][_ToAddress].length <= 0)
            Profile[_msgSender()].Opponents.push(_ToAddress);

        Messages[_msgSender()][_ToAddress].push(
            MessageStruct(
                _msgSender(),
                _ToAddress,
                _MessageText,
                _MediaLink,
                block.timestamp,
                block.number,
                _KeyLocation
            )
        );

        if (!BlockList[_ToAddress][_msgSender()]) {
            if (!Profiles[_ToAddress]) CreateProfile(_ToAddress);

            if (Messages[_ToAddress][_msgSender()].length <= 0)
                Profile[_ToAddress].Opponents.push(_msgSender());

            Messages[_ToAddress][_msgSender()].push(
                MessageStruct(
                    _msgSender(),
                    _ToAddress,
                    _MessageText,
                    _MediaLink,
                    block.timestamp,
                    block.number,
                    _KeyLocation
                )
            );
        }

        emit Sent(_msgSender(), _ToAddress);
    }
}

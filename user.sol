// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import {Cryptography} from "./crypto.sol";

contract User {
    struct Contract {
        bytes32 Signature;
        address Creator;
    }

    Contract private ContractInfo;

    struct MessageStruct {
        address FromAddress;
        address ToAddress;
        string MessageText;
        string[] MediaLink;
        uint256 MessageTimestamp;
        uint256 BlockHeight;
    }

    struct OpponentStruct {
        address Opponent;
        MessageStruct Messages;
    }

    struct ProfileStruct {
        bytes32 Signature;
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

    mapping(address => mapping(address => MessageStruct[])) private Messages;
    mapping(address => ProfileStruct) private Profile;
    mapping(address => mapping(address => bool)) private BlockList;

    constructor() {
        ContractInfo.Signature = GenerateSignature(true);
        ContractInfo.Creator = msg.sender;
    }

    function RegenerateSignature() public {
        require(msg.sender == ContractInfo.Creator);

        ContractInfo.Signature = GenerateSignature(true);
    }

    //Generate the signature

    function CreateProfile(address _Owner) public {
        require(
            Profile[_Owner].Signature == bytes32(0),
            "Address already has profile"
        );

        Profile[_Owner] = ProfileStruct(
            GenerateSignature(false),
            "",
            Profile[_Owner].Opponents,
            Profile[_Owner].BlockList
        );
    }

    function ChangePicture(string memory _MediaLink) public {
        require(
            Profile[msg.sender].Signature != bytes32(0),
            "You never interact with the contract"
        );

        Profile[msg.sender].Picture = _MediaLink;

        emit PictureChanged(msg.sender, _MediaLink);
    }

    function GetPicture(address _Opponent) public view returns (string memory) {
        return Profile[_Opponent].Picture;
    }

    function GetSignature() private view returns (bytes32) {
        bytes32 Signature = ContractInfo.Signature;

        if (Profile[msg.sender].Signature != bytes32(0))
            Signature = Profile[msg.sender].Signature;

        return Signature;
    }

    function GenerateText(string memory _Text)
        public
        view
        returns (bytes memory)
    {
        return Cryptography.encrypt(_Text, GetSignature());
    }

    function GetBlockList() public view returns (address[] memory) {
        return Profile[msg.sender].BlockList;
    }

    function AddBlockList(address _Opponent) public {
        require(msg.sender != _Opponent, "Can not block own address");
        require(
            Profile[msg.sender].Signature != bytes32(0),
            "You never interact with the contract"
        );
        require(!BlockList[msg.sender][_Opponent], "Address already blocked");

        BlockList[msg.sender][_Opponent] = true;
        Profile[msg.sender].BlockList.push(_Opponent);

        emit BlockListAdded(msg.sender, _Opponent);
    }

    function ReBlockList(address _Opponent)
        private
        view
        returns (address[] memory)
    {
        require(
            Profile[msg.sender].Signature != bytes32(0),
            "You never interact with the contract"
        );
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
        require(
            Profile[msg.sender].Signature != bytes32(0),
            "You never interact with the contract"
        );
        require(BlockList[msg.sender][_Opponent], "Address is not blocked");

        BlockList[msg.sender][_Opponent] = false;
        Profile[msg.sender].BlockList = ReBlockList(_Opponent);

        emit BlockListRemoved(msg.sender, _Opponent);
    }

    function Opponents() public view returns (OpponentStruct[] memory) {
        OpponentStruct[] memory OpponentList = new OpponentStruct[](
            Profile[msg.sender].Opponents.length
        );

        for (uint256 i = 0; i < Profile[msg.sender].Opponents.length; i++) {
            uint256 MessageLength = Messages[msg.sender][
                Profile[msg.sender].Opponents[i]
            ].length;
            OpponentList[i] = OpponentStruct(
                Profile[msg.sender].Opponents[i],
                Messages[msg.sender][Profile[msg.sender].Opponents[i]][
                    MessageLength - 1
                ]
            );
        }

        return OpponentList;
    }

    function Message(address _Opponent)
        public
        view
        returns (MessageStruct[] memory)
    {
        require(msg.sender != _Opponent, "Can not get own message");

        return Messages[msg.sender][_Opponent];
    }

    function SendMessage(
        address _ToAddress,
        bytes memory _MessageText,
        string[] memory _MediaLink
    ) public {
        require(msg.sender != _ToAddress, "Can not send message to yourself");
        require(
            !BlockList[msg.sender][_ToAddress],
            "Opponent address is blocked by you"
        );

        string memory MessageText = Decrypt(_MessageText, GetSignature());

        if (Profile[msg.sender].Signature == bytes32(0))
            CreateProfile(msg.sender);

        if (Messages[msg.sender][_ToAddress].length <= 0)
            Profile[msg.sender].Opponents.push(_ToAddress);

        Messages[msg.sender][_ToAddress].push(
            MessageStruct(
                msg.sender,
                _ToAddress,
                MessageText,
                _MediaLink,
                block.timestamp,
                block.number
            )
        );

        Profile[msg.sender].Signature = GenerateSignature(false);

        if (!BlockList[_ToAddress][msg.sender]) {
            if (Profile[_ToAddress].Signature == bytes32(0))
                CreateProfile(_ToAddress);

            if (Messages[_ToAddress][msg.sender].length <= 0)
                Profile[_ToAddress].Opponents.push(msg.sender);

            Messages[_ToAddress][msg.sender].push(
                MessageStruct(
                    msg.sender,
                    _ToAddress,
                    MessageText,
                    _MediaLink,
                    block.timestamp,
                    block.number
                )
            );

            Profile[_ToAddress].Signature = GenerateSignature(false);
        }

        emit Sent(msg.sender, _ToAddress);
    }

    // Decrypt function
}

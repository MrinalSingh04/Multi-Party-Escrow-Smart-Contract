// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title MultiParty Escrow (2-of-3approval)
/// @notice Funds locked until any 2 of {buyer, seller, mediator} approve release to seller.
///         If deadline passes without 2 approvals, buyer can refund.
/// @dev Single-escrow instance per contract. Use a factory for many escrows.
contract MultiPartyEscrow is ReentrancyGuard {
    enum State {
        AWAITING_DEPOSIT,
        AWAITING_APPROVALS,
        RELEASED,
        REFUNDED
    }

    address public buyer;
    address public seller;
    address public mediator;
    uint256 public deadline; // unix timestamp
    State public state;

    uint256 public amount; // amount deposited (in wei)

    mapping(address => bool) public approved;
    uint8 public approvalsCount;

    event Deposited(address indexed from, uint256 amount);
    event Approved(address indexed who, uint8 approvalsCount);
    event Released(address indexed to, uint256 amount);
    event Refunded(address indexed to, uint256 amount);

    modifier onlyParty() {
        require(
            msg.sender == buyer ||
                msg.sender == seller ||
                msg.sender == mediator,
            "Not an authorized party"
        );
        _;
    }

    modifier inState(State s) {
        require(state == s, "Invalid state for this action");
        _;
    }

    constructor(
        address _buyer,
        address _seller,
        address _mediator,
        uint256 _deadline
    ) {
        require(
            _buyer != address(0) &&
                _seller != address(0) &&
                _mediator != address(0),
            "Zero address"
        );
        require(_deadline > block.timestamp, "Deadline must be in the future");

        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
        deadline = _deadline;
        state = State.AWAITING_DEPOSIT;
    }

    /// @notice Buyer deposits funds into escrow. Single deposit only.
    function deposit()
        external
        payable
        nonReentrant
        inState(State.AWAITING_DEPOSIT)
    {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(msg.value > 0, "Must deposit > 0");

        amount = msg.value;
        state = State.AWAITING_APPROVALS;

        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Parties (buyer/seller/mediator) call to approve release to seller.
    function approveRelease()
        external
        onlyParty
        inState(State.AWAITING_APPROVALS)
    {
        require(!approved[msg.sender], "Already approved");

        approved[msg.sender] = true;
        approvalsCount += 1;

        emit Approved(msg.sender, approvalsCount);

        if (approvalsCount >= 2) {
            _releaseToSeller();
        }
    }

    /// @notice If deadline passed and consensus not reached, buyer can claim refund.
    function refundIfDeadlinePassed()
        external
        nonReentrant
        inState(State.AWAITING_APPROVALS)
    {
        require(block.timestamp > deadline, "Deadline not passed");
        require(msg.sender == buyer, "Only buyer can call refund");
        _refundToBuyer();
    }

    /// @dev Internal release logic
    function _releaseToSeller() internal {
        require(state == State.AWAITING_APPROVALS, "Not awaiting approvals");
        state = State.RELEASED;

        uint256 toSend = amount;
        amount = 0;

        (bool ok, ) = seller.call{value: toSend}("");
        require(ok, "Transfer to seller failed");

        emit Released(seller, toSend);
    }

    /// @dev Internal refund logic
    function _refundToBuyer() internal {
        state = State.REFUNDED;
        uint256 toSend = amount;
        amount = 0;

        (bool ok, ) = buyer.call{value: toSend}("");
        require(ok, "Refund transfer failed");

        emit Refunded(buyer, toSend);
    }

    /// @notice View helper: returns how many more approvals needed
    function approvalsNeeded() external view returns (uint8) {
        if (approvalsCount >= 2) return 0;
        return 2 - approvalsCount;
    }

    /// @notice Emergency getter in case funds are stuck (only after final state and by parties)
    function getState() external view returns (State) {
        return state;
    }
}

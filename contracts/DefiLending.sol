// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NftContract.sol";

error NON_EXISTENT_TOKEN(uint256 tokenId);
error UNAUTHORIZED(uint256 tokenId);
error NO_TOKEN_OWNED();
error INSUFFICIENT_LIQUIDITY(uint256 amount);
error EMPTY_DEPOSIT();
error INSUFFICIENT_BALANCE(uint256 amount);
error NO_LOAN();
error INSUFFICIENT_REPAYMENT_AMOUNT();
error COLLATERAL_COLLECTED();

contract DeFiLending {
    NftContract public nftContract;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public loans;
    mapping(address => uint256) public collateralTokenId;
    mapping(address => bool) public whiteListed; // reward for depositing; to be whitelisted for a future airdrop etc.

    uint256 public totalDeposits;
    uint256 public totalLoans;
    uint256 public interestRate; // Annual interest rate in basis points (1% = 100 basis points)

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Loan(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);

    constructor(address _nftContract, uint256 _interestRate) {
        nftContract = NftContract(_nftContract);
        interestRate = _interestRate;
    }

    modifier nftExists(uint256 _tokenId) {
        if (_tokenId > nftContract.tokenIdCounter()) {
            revert NON_EXISTENT_TOKEN(_tokenId);
        }
        _;
    }

    modifier tokenOwner(uint256 _tokenId) {
        if (nftContract.ownerOf(_tokenId) != msg.sender) {
            revert UNAUTHORIZED(_tokenId);
        }
        _;
    }

    modifier hasToken() {
        if (nftContract.balanceOf(msg.sender) == 0) {
            revert NO_TOKEN_OWNED();
        }
        _;
    }

    modifier hasEnoughLiquidity(uint256 _amount) {
        if (totalDeposits < totalLoans + _amount) {
            revert INSUFFICIENT_LIQUIDITY(_amount);
        }
        _;
    }

    modifier nonZeroDeposit() {
        if (msg.value == 0) {
            revert EMPTY_DEPOSIT();
        }
        _;
    }

    modifier sufficientBalance(uint256 _amount) {
        if (deposits[msg.sender] < _amount) {
            revert INSUFFICIENT_BALANCE(_amount);
        }
        _;
    }

    modifier hasLoan() {
        if (loans[msg.sender] == 0) {
            revert NO_LOAN();
        }
        _;
    }

    modifier collateralNotInPossession() {
        if (collateralTokenId[msg.sender] != 0) {
            revert COLLATERAL_COLLECTED();
        }
        _;
    }

    modifier sufficientRepayment() {
        uint256 interest = (loans[msg.sender] * interestRate) / 10000;
        uint256 totalRepayment = loans[msg.sender] + interest;
        require(msg.value >= totalRepayment, "Insufficient repayment amount");

        if (msg.value < totalRepayment) {
            revert INSUFFICIENT_REPAYMENT_AMOUNT();
        }

        loans[msg.sender] = 0;
        totalLoans -= msg.value - interest;
        _;
    }

    function deposit() external payable nonZeroDeposit {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);

        if(!whiteListed[msg.sender]) {
            whiteListed[msg.sender] = true;
        }
    }

    function withdraw(uint256 _amount) external sufficientBalance(_amount) {
        deposits[msg.sender] -= _amount;
        totalDeposits -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function borrow(uint256 _amount, uint256 _tokenId)
        external
        nftExists(_tokenId)
        tokenOwner(_tokenId)
        hasToken
        hasEnoughLiquidity(_amount)
        collateralNotInPossession
    {
        loans[msg.sender] += _amount;
        totalLoans += _amount;

        nftContract.transferFrom(msg.sender, address(this), _tokenId); // transfer NFT as collateral to this contract
        collateralTokenId[msg.sender] = _tokenId;

        payable(msg.sender).transfer(_amount);
        emit Loan(msg.sender, _amount);
    }

    function repay() external payable hasLoan sufficientRepayment {
        emit Repay(msg.sender, msg.value);
        nftContract.transferFrom(
            address(this),
            msg.sender,
            collateralTokenId[msg.sender]
        ); // transfer the NFT back to the owner
        collateralTokenId[msg.sender] = 0; // collateral no longer in possession
    }

    function calculateInterest(uint256 _amount) public view returns (uint256) {
        return (_amount * interestRate) / 10000;
    }
}

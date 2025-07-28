// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PersonalBudgetTracker
 * @dev A decentralized personal budget tracking smart contract
 * @author Your Name
 */
contract PersonalBudgetTracker {
    
    // Struct to represent a transaction
    struct Transaction {
        uint256 id;
        string description;
        uint256 amount; // Amount in wei (for ETH) or smallest unit
        bool isIncome; // true for income, false for expense
        string category;
        uint256 timestamp;
    }
    
    // Mapping from user address to their transactions
    mapping(address => Transaction[]) private userTransactions;
    
    // Mapping from user address to their total balance
    mapping(address => uint256) private userBalances;
    
    // Mapping from user address to transaction counter
    mapping(address => uint256) private transactionCounters;
    
    // Events
    event TransactionAdded(
        address indexed user,
        uint256 indexed transactionId,
        string description,
        uint256 amount,
        bool isIncome,
        string category,
        uint256 timestamp
    );
    
    event TransactionUpdated(
        address indexed user,
        uint256 indexed transactionId,
        string description,
        uint256 amount,
        bool isIncome,
        string category
    );
    
    event TransactionDeleted(
        address indexed user,
        uint256 indexed transactionId
    );
    
    /**
     * @dev Add a new transaction (income or expense)
     * @param _description Description of the transaction
     * @param _amount Amount of the transaction
     * @param _isIncome True if income, false if expense
     * @param _category Category of the transaction
     */
    function addTransaction(
        string memory _description,
        uint256 _amount,
        bool _isIncome,
        string memory _category
    ) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(bytes(_category).length > 0, "Category cannot be empty");
        
        uint256 transactionId = transactionCounters[msg.sender];
        
        Transaction memory newTransaction = Transaction({
            id: transactionId,
            description: _description,
            amount: _amount,
            isIncome: _isIncome,
            category: _category,
            timestamp: block.timestamp
        });
        
        userTransactions[msg.sender].push(newTransaction);
        transactionCounters[msg.sender]++;
        
        // Update user balance
        if (_isIncome) {
            userBalances[msg.sender] += _amount;
        } else {
            userBalances[msg.sender] = userBalances[msg.sender] >= _amount 
                ? userBalances[msg.sender] - _amount 
                : 0;
        }
        
        emit TransactionAdded(
            msg.sender,
            transactionId,
            _description,
            _amount,
            _isIncome,
            _category,
            block.timestamp
        );
    }
    
    /**
     * @dev Get all transactions for the calling user
     * @return Array of user's transactions
     */
    function getMyTransactions() external view returns (Transaction[] memory) {
        return userTransactions[msg.sender];
    }
    
    /**
     * @dev Get user's current balance
     * @return Current balance of the calling user
     */
    function getMyBalance() external view returns (uint256) {
        return userBalances[msg.sender];
    }
    
    /**
     * @dev Update an existing transaction
     * @param _transactionIndex Index of the transaction in user's array
     * @param _description New description
     * @param _amount New amount
     * @param _isIncome New income/expense status
     * @param _category New category
     */
    function updateTransaction(
        uint256 _transactionIndex,
        string memory _description,
        uint256 _amount,
        bool _isIncome,
        string memory _category
    ) external {
        require(_transactionIndex < userTransactions[msg.sender].length, "Invalid transaction index");
        require(_amount > 0, "Amount must be greater than 0");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(bytes(_category).length > 0, "Category cannot be empty");
        
        Transaction storage transaction = userTransactions[msg.sender][_transactionIndex];
        
        // Reverse the old transaction's effect on balance
        if (transaction.isIncome) {
            userBalances[msg.sender] = userBalances[msg.sender] >= transaction.amount 
                ? userBalances[msg.sender] - transaction.amount 
                : 0;
        } else {
            userBalances[msg.sender] += transaction.amount;
        }
        
        // Update transaction details
        transaction.description = _description;
        transaction.amount = _amount;
        transaction.isIncome = _isIncome;
        transaction.category = _category;
        
        // Apply new transaction's effect on balance
        if (_isIncome) {
            userBalances[msg.sender] += _amount;
        } else {
            userBalances[msg.sender] = userBalances[msg.sender] >= _amount 
                ? userBalances[msg.sender] - _amount 
                : 0;
        }
        
        emit TransactionUpdated(
            msg.sender,
            transaction.id,
            _description,
            _amount,
            _isIncome,
            _category
        );
    }
    
    /**
     * @dev Delete a transaction
     * @param _transactionIndex Index of the transaction to delete
     */
    function deleteTransaction(uint256 _transactionIndex) external {
        require(_transactionIndex < userTransactions[msg.sender].length, "Invalid transaction index");
        
        Transaction storage transaction = userTransactions[msg.sender][_transactionIndex];
        uint256 transactionId = transaction.id;
        
        // Reverse the transaction's effect on balance
        if (transaction.isIncome) {
            userBalances[msg.sender] = userBalances[msg.sender] >= transaction.amount 
                ? userBalances[msg.sender] - transaction.amount 
                : 0;
        } else {
            userBalances[msg.sender] += transaction.amount;
        }
        
        // Remove transaction from array
        userTransactions[msg.sender][_transactionIndex] = userTransactions[msg.sender][userTransactions[msg.sender].length - 1];
        userTransactions[msg.sender].pop();
        
        emit TransactionDeleted(msg.sender, transactionId);
    }
    
    /**
     * @dev Get total number of transactions for the calling user
     * @return Number of transactions
     */
    function getTransactionCount() external view returns (uint256) {
        return userTransactions[msg.sender].length;
    }
}

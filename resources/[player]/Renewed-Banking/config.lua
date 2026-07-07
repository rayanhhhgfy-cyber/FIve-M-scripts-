Config = Config or {}

Config.Banking = {
    enableInterest = true,
    interestRate = 0.002,
    interestInterval = 3600000,
    maxAccounts = 5,
    maxTransactionLogs = 100,
    openingBalance = 5000,
    maxWithdrawAmount = 100000,
    maxDepositAmount = 1000000,
    transferFee = 0.01,
    transferFeeMinimum = 1,
    transferFeeMaximum = 1000,
    atmFee = 2,
    enableLoans = true,
    maxLoanAmount = 50000,
    loanInterestRate = 0.05,
    loanTerm = 30,
    enableJointAccounts = true,
    enableCorporateAccounts = true,
    enableSavingsAccounts = true,
    adminAce = 'admin.bank'
}

Config.AccountTypes = {
    personal = { label = 'Personal Account', maxOverdraft = 0, monthlyFee = 0 },
    savings = { label = 'Savings Account', maxOverdraft = 0, monthlyFee = 0, interestRate = 0.005 },
    joint = { label = 'Joint Account', maxOverdraft = 500, monthlyFee = 5 },
    corporate = { label = 'Business Account', maxOverdraft = 10000, monthlyFee = 25 }
}

Config.ATMLocations = {
    { x = 150.0, y = -1040.0, z = 29.0 },
    { x = -25.0, y = -725.0, z = 32.0 },
    { x = 315.0, y = -280.0, z = 54.0 },
    { x = -300.0, y = -830.0, z = 32.0 },
    { x = -1200.0, y = -890.0, z = 14.0 },
    { x = -1400.0, y = -600.0, z = 30.0 },
    { x = 240.0, y = 220.0, z = 106.0 },
    { x = 1100.0, y = -750.0, z = 58.0 },
    { x = 380.0, y = 330.0, z = 103.0 },
    { x = -820.0, y = -700.0, z = 28.0 },
    { x = 1200.0, y = -470.0, z = 66.0 },
    { x = 1300.0, y = -700.0, z = 65.0 }
}

Config.TransactionTypes = {
    deposit = 'Deposit',
    withdraw = 'Withdrawal',
    transfer = 'Transfer',
    payment = 'Payment',
    salary = 'Salary',
    interest = 'Interest',
    fee = 'Fee',
    purchase = 'Purchase',
    refund = 'Refund',
    loan = 'Loan',
    loan_payment = 'Loan Payment'
}

myAccount = eth.accounts[conf.accountIndex];

// unlock account
personal.unlockAccount(myAccount, 'supersonic', 0); 
console.log('Account', myAccount, 'unlocked');

counter = 0;

txInterval = setInterval(function sendTransaction() {
  // build transaction
  tx = {
    from: myAccount,
    to: '0xc541d3722dda565493f777ff80afa9314ec9406c',
    value: 1,
  }

  // send transaction
  eth.sendTransaction(tx);

  console.log('Transaction sent ' + counter++);
}, conf.txDelay);

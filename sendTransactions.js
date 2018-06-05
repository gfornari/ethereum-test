myAccount = eth.accounts[conf.accountIndex];

counter = 0;

txInterval = setInterval(function sendTransaction() {
  // build transaction
  tx = {
    from: myAccount,
    to: '0xc541d3722dda565493f777ff80afa9314ec9406c',
    value: 1,
  }
  // unlock account
  personal.unlockAccount(myAccount, 'supersonic');

  // send transaction
  eth.sendTransaction(tx);

  console.log('Transaction sent ' + counter++);
}, conf.txDelay);

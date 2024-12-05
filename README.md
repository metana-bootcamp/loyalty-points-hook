# Points hook

* Simple on chain reward program
* launching a memecoin - "TOKEN"

* setup a pool with ETH/TOKEN
  * issue points for every time somebody buys TOKEN with ETH
  * issue points for everytime somebody adds liquidity to the pool

**THIS IS NOT PRODUCTION READY. If we have time we'll discuss about limitations and how to fix them**

## How many poins to give out?
* 20% of value in ETH. if alice sells 1 ETH to buy TOKEN, it will receive 0.2 points. 
* For adding liquidity ,  we'll keep 1:1 for ETH added

## Mechanism design

1. issue points evertime somebody buy TOKEN for ETH
  * afterSwap : the amount of ETH can be only known after swap has happened
  * issue points proportional to amount of ETH being sent from user for swap

2. issue points everytime somebody add liquidity
  * afterAddLiquidity  

## BalanceDelta 
* Represents changes in the balance of token0 and token1
* BalanceDelta = (amount0Delta amount1Delta)
* Alice sells 1 ETH for TOKEN in our pool after swap is done
* BalanceDelta = (-1 ETH, +500 TOKEN)

----------------------------------------------------

* whenever there is a balance change , all number in uniswap by convention are represented from user perspective
* amount0Delta = -1 ETH => user needs to send 1 ETH to uniswap (user owes 1 ETH)
* amount1Delta = 500 token => User is owed 500 tokens from uniswap (uniswap needs to send 500 tokens to user)

## zeroForOne
* exactInput(...) : zero for one
* exactInput(...) : one for zero
* exactOutput(...) : zero for one
* exactOutput(...) : one for zero

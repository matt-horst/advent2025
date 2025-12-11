import math

def coin_change_dp(coins, amount):
    # Initialize a DP table with amount + 1, and infinity for all entries except index 0
    # dp[i] will store the minimum number of coins to make amount i
    dp = [math.inf] * (amount + 1)
    dp[0] = 0  # 0 coins needed for amount 0

    # Iterate through all possible amounts from 1 to the target amount
    for i in range(1, amount + 1):
        # Iterate through each coin denomination
        for coin in coins:
            # If the current coin value is less than or equal to the current amount
            if i >= coin:
                # Update dp[i] with the minimum of its current value 
                # or 1 (for the current coin) + the min coins for the remaining amount (i - coin)
                dp[i] = min(dp[i], 1 + dp[i - coin])

    # If dp[amount] is still infinity, the amount cannot be made with the given coins, return -1
    return -1 if dp[amount] == math.inf else dp[amount]

# Example Usage:
# base: 8, coins: { 512, 520, 64, 576, 65, 9 }, target: 3883
# coins: { 3445195824, 3594842413, 9974700532986, 9978292105153, 9833734413133, 9974703630823, 9978145558794 }, target: 707770049091839

# coins_list = [1, 101, 10, 11, 1010, 1100]
# coins_list = [512, 520, 64, 576, 65, 9]
# coins_list = [1, 5*8+1, 8, 8+1, 6*5*8+8, 6*5*8+5*8]
# coins_list = [ 3445195824, 3594842413, 9974700532986, 9978292105153, 9833734413133, 9974703630823, 9978145558794 ]
# target_amount = 3547
# target_amount = 3883
# target_amount = 3*6*5*8 + 5*5*8 + 4*8 + 7
# target_amount = 707770049091839
result = coin_change_dp(coins_list, target_amount)
print(result)

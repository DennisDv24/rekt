from brownie import RektCoin
from scripts.utils import get_account

pool_address = '0x5384D7cd707F3862bb1D8d08DE46E5D1011a4440'

def set_token_pool():
    acc = get_account()
    token = RektCoin[-1]
    token.setPoolAddress(pool_address, {'from': acc})

def main():
    set_token_pool()

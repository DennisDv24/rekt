from brownie import RektCoin
from scripts.utils import get_account

pool_address = '0xb5dDD922ED0eF72D235761A397FB426d37fcD8Ef'

def set_token_pool():
    acc = get_account()
    token = RektCoin[-1]
    token.setPoolAddress(pool_address, {'from': acc})

def main():
    set_token_pool()

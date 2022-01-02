from scripts.utils import get_account
from brownie import RektTransactionBatcher
from web3 import Web3

amout_to_sell = Web3.toWei(24.3188, 'ether')

def sell():
    acc = get_account()
    batcher = RektTransactionBatcher[-1]
    batcher.sellRektCoin(amout_to_sell, {'from': acc})

def main():
    sell()

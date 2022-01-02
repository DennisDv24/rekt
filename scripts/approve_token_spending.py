from scripts.utils import get_account
from brownie import RektCoin, RektTransactionBatcher
from brownie import config, network
from web3 import Web3

def approve():
    acc = get_account()
    token = RektCoin[-1]
    batcher = RektTransactionBatcher[-1]
    token.approve(
        batcher.address,
        Web3.toWei(1000, 'ether'),
        {'from': acc}
    )
def main():
    approve()

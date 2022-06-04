from scripts.utils import get_account, get_all_test_accs

from brownie import RektCoin, RektTransactionBatcher, LinkToken
from brownie import accounts, network, config
from web3 import Web3

rekt_to_fund = Web3.toWei(0.013, 'ether')

# so basically brownie doesnt suport concurrent txs???
def main():
    wallets = get_all_test_accs()
    #batcher_initializer = wallets[0]
    rekt = RektCoin[-1]
    acc = get_account()
    #batcher = RektTransactionBatcher[-1]
    for wallet in wallets:
        rekt.transfer(
            wallet,
            rekt_to_fund,
            {'from': acc, 'required_confs': 0}
        )
    input('Press intro when all tx are completed')
    for wallet in wallets:
        print(f'{wallet} REKT bal: {rekt.balanceOf(wallet)}')


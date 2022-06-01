from scripts.utils import get_account, get_all_test_accs

from brownie import RektCoin, RektTransactionBatcher, LinkToken
from brownie import accounts, network, config
from web3 import Web3

wallets_to_generate = 10
amount_to_sell_per_wallet = Web3.toWei(6, 'ether')
rekt_to_send_per_wallet = amount_to_sell_per_wallet

# rektTestN accounts on metamask, NOTE dont 
# hardcode the keys in the final script

def generate_wallets(n):
    # I dont know how to generate wallets with brownie
    # so Ill just hardcode a lot of test wallets
    return get_all_test_accs()


gas_to_send_per_wallet = Web3.toWei(0.002, 'ether')
def supply_wallets_with_gas(wallets):
    my_acc = get_account()
    for wallet in wallets:
        my_acc.transfer(wallet, gas_to_send_per_wallet)

def supply_wallets_with_rekt(wallets):
    rekt = RektCoin[-1]
    acc = get_account()
    for wallet in wallets:
        rekt.transfer(
            wallet,
            rekt_to_send_per_wallet,
            {'from': acc}
        )

def approve_wallets_for_batcher(wallets):
    batcher = RektTransactionBatcher[-1]
    rekt = RektCoin[-1]
    for wallet in wallets:
        rekt.approve(
            batcher,
            Web3.toWei(9999, 'ether'),
            {'from': wallet}
        ) 

def sell_from(wallets):
    batcher = RektTransactionBatcher[-1]
    for wallet in wallets:
        batcher.sellRektCoin(
            amount_to_sell_per_wallet, {'from': wallet}
        )


def main():
    wallets = generate_wallets(wallets_to_generate)
    supply_wallets_with_gas(wallets)
    supply_wallets_with_rekt(wallets)
    approve_wallets_for_batcher(wallets)
    sell_from(wallets)





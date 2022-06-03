from scripts.utils import get_account, get_all_test_accs

from brownie import RektCoin, RektTransactionBatcher, LinkToken
from brownie import accounts, network, config
from web3 import Web3

gas_to_send_per_wallet = Web3.toWei(0.002, 'ether')
dust_size = 1

def clear_batcher_initializer(initializer):
    RektCoin[-1].transfer(
        get_account(),
        RektCoin[-1].balanceOf(initializer),
        {'from': initializer}
    )

def show_rekt_balances(wallets):
    for i in range(len(wallets)):
        amm = Web3.fromWei(RektCoin[-1].balanceOf(wallets[i]), 'ether') 
        print(f'wallet {i} rekt bal: {amm}')

def main():
    wallets = get_all_test_accs()
    batcher_initializer = wallets[0]
    rekt = RektCoin[-1]
    acc = get_account()
    batcher = RektTransactionBatcher[-1]
    
    print(f'current batcher fee: {Web3.fromWei(batcher.getCurrentRektFee(), "ether")}')
    clear_batcher_initializer(batcher_initializer)
    print(f'Your rekt: {Web3.fromWei(rekt.balanceOf(get_account()), "ether")}')
    show_rekt_balances(wallets)
    rekt.transfer(batcher_initializer, batcher.getCurrentRektFee(), {'from': acc})
    for wallet in wallets:
        rekt.approve(batcher, Web3.toWei(999999, 'ether'), {'from': wallet})
        acc.transfer(wallet, gas_to_send_per_wallet)
        rekt.transfer(wallet, dust_size, {'from': acc})

    print(f'Your rekt: {Web3.fromWei(rekt.balanceOf(get_account()), "ether")}')
    show_rekt_balances(wallets)
    
    batcher.sellRektCoin(rekt.balanceOf(batcher_initializer), {'from': batcher_initializer})

    for wallet in wallets:
        batcher.sellRektCoin(dust_size, {'from': wallet})

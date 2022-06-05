from scripts.utils import get_account, get_all_test_accs

from brownie import RektCoin, RektTransactionBatcher, LinkToken
from brownie import accounts, network, config
from web3 import Web3

wallets_to_generate = 10
rekt_to_send_per_wallet = RektTransactionBatcher[-1].getCurrentRektFee()

# rektTestN accounts on metamask, NOTE dont 
# hardcode the keys in the final script

def generate_wallets(n):
    # I dont know how to generate wallets with brownie
    # so Ill just hardcode a lot of test wallets
    return get_all_test_accs()


gas_to_send_per_wallet = Web3.toWei(0.003, 'ether')
def supply_wallets_with_gas(wallets):
    my_acc = get_account()
    for wallet in wallets:
        my_acc.transfer(wallet, gas_to_send_per_wallet)

def supply_wallets_with_rekt(wallets):
    rekt = RektCoin[-1]
    fee = RektTransactionBatcher[-1].getCurrentRektFee()
    acc = get_account()
    acc_bal = Web3.fromWei(rekt.balanceOf(acc), 'ether')
    print(f'Your current rekt balance: {acc_bal}')
    print(f'The batcher fee is: {Web3.fromWei(fee, "ether")}')
    x = int(input('How much rekt do you want to send to each wallet? '))

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
    fee = batcher.getCurrentRektFee()
    rekt = RektCoin[-1]
    print(f'The batcher fee is: {Web3.fromWei(fee, "ether")}')
    print('Selling all user bals')
    for wallet in wallets:
        bal = rekt.balanceOf(wallet);
        if bal < rekt_to_send_per_wallet or bal < batcher.getCurrentRektFee():
            print('ERROR: Wallet doesnt have enought REKT')
        else:
            print(f'Selling {batcher.getCurrentRektFee()} REKT (the current fee)')
            batcher.sellRektCoin(
                batcher.getCurrentRektFee(), {'from': wallet, 'required_confs': 0}
            )


def main():
    wallets = generate_wallets(wallets_to_generate)
    #supply_wallets_with_rekt(wallets)
    #supply_wallets_with_gas(wallets)
    #approve_wallets_for_batcher(wallets)
    sell_from(wallets)





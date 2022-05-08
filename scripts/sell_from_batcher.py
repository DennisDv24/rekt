from scripts.utils import get_account
from brownie import RektTransactionBatcher, RektCoin, interface
from web3 import Web3

amout_to_sell = Web3.toWei(24.3188, 'ether')

def sell():
    acc = get_account()
    print(f'Current account: {acc}')

    balance = Web3.fromWei(RektCoin[-1].balanceOf(acc), 'ether')
    print(f'You currently have {balance} RektCoins')

    batcher = RektTransactionBatcher[-1]
    fee = Web3.fromWei(batcher.getCurrentRektFee(), 'ether')
    print(f'The fee for starting an new selling batch will be {fee}')

    to_sell = int(input('How much do you want to sell (integer)? '))
    to_sell = Web3.toWei(to_sell, 'ether')

    print('\nCurrent Batcher:')
    print(batcher)
    print(f'Current contract owner: {batcher.owner()}')
    batcher.resetBatcher({'from': acc})
    print('The batcher reseted its state')
    """
    try:
        print(f'Current contract owner: {batcher.owner()}')
        batcher.resetBatcher({'from': acc})
        print('The batcher reseted its state')
    except:
        pass
    finally:
        x = input('finalize sell: Y/n: ')
        if x[0] not in ('n', 'N'):
            batcher.sellRektCoin(amout_to_sell, {'from': acc})
        else:
            'canceling sell order...'
    """
def main():
    sell()

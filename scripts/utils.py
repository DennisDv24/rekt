from brownie import accounts, network, config
from web3 import Web3


LOCAL_BLOCKCHAIN_ENVS = [
    'development',
    'ganache-local',
    'mainnet-fork'
]
BLOCKCHAIN_FORKS = [
    'mainnet-fork'
]

def get_test_acc(i):
    return accounts.add(config['wallets'][f'test{i}'])

def get_all_test_accs():
    wallets = []
    for i in range(1, 10):
        wallets.append(get_test_acc(i))
    return wallets

def get_account(index=None, id=None):

    if index:
        return accounts[index]
    if id:
        return accounts.load(id)
    if(network.show_active() in LOCAL_BLOCKCHAIN_ENVS):
        return accounts[0]

    return accounts.add(config['wallets']['from_key'])

    



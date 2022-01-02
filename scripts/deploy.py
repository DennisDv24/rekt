from scripts.utils import get_account
from brownie import RektCoin, RektTransactionBatcher
from brownie import config, network
from web3 import Web3

initial_supply = Web3.toWei(1000, 'ether')

def deploy_token(acc):
    return RektCoin.deploy(
        initial_supply,
        {'from': acc},
        publish_source = config['networks'][network.show_active()].get('verify', False)
    )

def deploy_batcher(acc):
    return RektTransactionBatcher.deploy(
        config['networks'][network.show_active()]['vrf_coordinator'],
        config['networks'][network.show_active()]['link_token'],
        config['networks'][network.show_active()]['keyhash'],
        config['networks'][network.show_active()]['fee'],
        config['networks'][network.show_active()]['uniswap_router'],
        {'from': acc},
        publish_source = config['networks'][network.show_active()].get('verify', False)
    )


def do_whole_app_deploy():
    acc = get_account()
    token = deploy_token(acc)
    batcher = deploy_batcher(acc)
    
    token.setTransactionBatcher(batcher.address, {'from': acc})
    batcher.initializePath(
        token.address,
        config['networks'][network.show_active()]['weth_token']
    )

    # Then you create the liq pool from the dex and then you run set_token_pool.py



def main():
    do_whole_app_deploy()

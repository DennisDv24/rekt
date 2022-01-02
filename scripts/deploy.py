from scripts.utils import get_account
from brownie import RektCoin, RektTransactionBatcher, LinkToken
from brownie import config, network, Contract, interface
from web3 import Web3
from scripts.approve_token_spending import approve

initial_supply = Web3.toWei(1000, 'ether')
amount_to_keep = Web3.toWei(100, 'ether')

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

def approve_uniswap_router():
    acc = get_account()
    amount_to_approve = Web3.toWei(10000, 'ether')

    token = RektCoin[-1]
    token.approve(
        config['networks'][network.show_active()]['uniswap_router'],
        amount_to_approve,
        {'from': acc}
    )


def create_liq_pool():
    eth_to_add_to_the_pool = Web3.toWei(0.4, 'ether')
    acc = get_account()
    router = Contract(
        config['networks'][network.show_active()]['uniswap_router']
    )
    deadline = 10**14
    
    router.addLiquidityETH(
        RektCoin[-1].address,
        initial_supply - amount_to_keep,
        initial_supply - amount_to_keep,
        eth_to_add_to_the_pool,
        acc,
        deadline,
        {'from': acc, 'value': eth_to_add_to_the_pool}
    )

def fund_batcher_with_link():
    acc = get_account()
    # NOTE better use interfaces
    link_token = Contract.from_abi(
        LinkToken._name,
        config['networks'][network.show_active()]['link_token'],
        LinkToken.abi
    )

    extra_margin = Web3.toWei(0.01, 'ether')
    link_token.transfer(
        RektTransactionBatcher[-1].address,
        config['networks'][network.show_active()]['fee'] + extra_margin,
        {'from': acc}
    )

def set_token_pool():
    acc = get_account()
    token = RektCoin[-1]

    factory = interface.IUniswapV2Factory(
        config['networks'][network.show_active()]['uniswap_factory']
    )
    pool_address = factory.getPair(
        token.address,
        config['networks'][network.show_active()]['weth_token']
    )

    token.setPoolAddress(pool_address, {'from': acc})

def sell():
    amout_to_sell = amount_to_keep;
    acc = get_account()
    batcher = RektTransactionBatcher[-1]
    batcher.sellRektCoin(amout_to_sell, {'from': acc})

def do_whole_rekt_swap_test():
    acc = get_account()
    token = deploy_token(acc)
    batcher = deploy_batcher(acc)
    
    token.setTransactionBatcher(batcher.address, {'from': acc})
    batcher.initializePath(
        token.address,
        config['networks'][network.show_active()]['weth_token']
    )

    approve_uniswap_router() 
    create_liq_pool()
    fund_batcher_with_link()
    set_token_pool()
    sell()



def main():
    do_whole_rekt_swap_test()

from scripts.utils import get_account
from brownie import RektCoin, RektTransactionBatcher, LinkToken
from brownie import config, network, interface
from web3 import Web3
from scripts.approve_token_spending import approve

net = network.show_active
get_net = lambda: config['networks'][net()]
get_net_conf = lambda key: config['networks'][net()][key]


initial_supply = Web3.toWei(10000, 'ether')
amount_to_keep = Web3.toWei(1000, 'ether')
eth_to_add_to_the_pool = Web3.toWei(0.5, 'ether')

# NOTE it will be the minimum of native token that you must
# sell to open an new order. For MATIC Ill just use 1MATIC
min_batcher_fee = Web3.toWei(0.001, 'ether')
vrf_chainlink_fee = get_net_conf('fee')

def deploy_token(acc):
    return RektCoin.deploy(
        initial_supply,
        {'from': acc},
        publish_source = get_net().get('verify', False)
    )

def deploy_batcher(acc, rektWethLP):
    print(f'LP addr: {rektWethLP}')
    return RektTransactionBatcher.deploy(
        get_net_conf('vrf_coordinator'),
        get_net_conf('link_token'),
        get_net_conf('keyhash'),
        vrf_chainlink_fee,
        get_net_conf('uniswap_router'),
        RektCoin[-1].address,
        get_net_conf('weth_token'),
        rektWethLP,
        min_batcher_fee,
        {'from': acc},
        publish_source = get_net().get('verify', False)
    )

def show_batcher_info(batcher=None):
    if not batcher: batcher = RektTransactionBatcher[-1]
    acc = get_account()
    current_fee = Web3.fromWei(batcher.getCurrentRektFee(), 'ether')
    batch_in_process = batcher.saleOfBatchInProcess()
    total_batch = Web3.fromWei(batcher.totalBatchAmount(), 'ether')
    amount_selling = Web3.fromWei(batcher.fromAccToAmountSelling(acc), 'ether')
     
    print('\nBATCHER INFO')
    print(f'Current max possible REKT fee for starting a new batch: {current_fee}')
    print(f'There is an batch in process: {batch_in_process}')
    print(f'Total batch size: {total_batch}')
    print(f'Amount youre selling: {amount_selling}\n')

def approve_uniswap_router():
    acc = get_account()
    amount_to_approve = Web3.toWei(10000, 'ether')

    token = RektCoin[-1]
    token.approve(
        get_net_conf('uniswap_router'),
        amount_to_approve,
        {'from': acc}
    )


def create_liq_pool(eth_to_add_to_the_pool):
    acc = get_account()
    router = interface.IUniswapV2Router02(
        get_net_conf('uniswap_router')
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

    factory = interface.IUniswapV2Factory(get_net_conf('uniswap_factory'))
    return factory.getPair(RektCoin[-1], get_net_conf('weth_token'))

# NOTE this should be implemented in the contract
def fund_batcher_with_link():
    acc = get_account()
    link_token = interface.IERC20(get_net_conf('link_token'))

    extra_margin = Web3.toWei(0.01, 'ether')
    link_token.transfer(
        RektTransactionBatcher[-1].address,
        get_net_conf('fee') + extra_margin,
        {'from': acc}
    )

def set_token_pool():
    acc = get_account()
    token = RektCoin[-1]

    factory = interface.IUniswapV2Factory(
        get_net_conf('uniswap_factory')
    )
    pool_address = factory.getPair(
        token.address,
        get_net_conf('weth_token')
    )

    token.setPoolAddress(pool_address, {'from': acc})


def approve_spending_on_batcher(acc):
    amount_to_approve = Web3.toWei(9999999, 'ether')
    token = RektCoin[-1]
    token.approve(
        RektTransactionBatcher[-1].address,
        amount_to_approve,
        {'from': acc}
    )

def sell():
    acc = get_account()
    approve_spending_on_batcher(acc)

    batcher = RektTransactionBatcher[-1]
    currentFee = Web3.fromWei(batcher.getCurrentRektFee(), 'ether')

    batcher.sellRektCoin(Web3.toWei(currentFee + 4, 'ether'), {'from': acc})
    show_batcher_info()

    batcher.sellRektCoin(Web3.toWei(currentFee + 7, 'ether'), {'from': acc})
    show_batcher_info()

    batcher.sellRektCoin(Web3.toWei(currentFee + 12, 'ether'), {'from': acc})
    show_batcher_info()

def deploy_and_small_test():
    acc = get_account()
    rekt = deploy_token(acc)

    approve_uniswap_router() 
    rektWethLP = create_liq_pool(eth_to_add_to_the_pool)
    rekt.setPoolAddress(rektWethLP, {'from': acc})

    batcher = deploy_batcher(acc, rektWethLP)
    show_batcher_info()
    
    rekt.setTransactionBatcher(batcher.address, {'from': acc})

    sell()


def main():
    deploy_and_small_test()
    # TODO organize events


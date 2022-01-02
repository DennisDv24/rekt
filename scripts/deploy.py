from scripts.utils import get_account
from brownie import FinalToken as TokenToDeploy
from web3 import Web3

initial_supply = Web3.toWei(666, 'ether')

def deploy():
    acc = get_account()
    token = TokenToDeploy.deploy(
        initial_supply,
        {'from': acc},
        publish_source = True
    )


def main():
    deploy()

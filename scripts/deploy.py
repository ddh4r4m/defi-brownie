import yaml
import json
from scripts.helpful_scripts import get_account, get_contract
from brownie import DharmaToken, TokenFarm, network, config
from web3 import Web3

KEPT_BALANCE = Web3.toWei(100, "ether")


def deploy_token_farm_and_dharma_token(front_end_update=False):
    account = get_account()
    dharma_token = DharmaToken.deploy({"from": account})
    token_farm = TokenFarm.deploy(
        dharma_token.address,
        {"from": account},
        publish_source=config["networks"][network.show_active()]["verify"],
    )
    tx = dharma_token.transfer(
        token_farm.address, dharma_token.totalSupply() - KEPT_BALANCE, {"from": account}
    )
    tx.wait(1)
    # we'll allow three tokesn to be staked
    # dharma_token, weth_token, fau_token
    weth_token = get_contract("weth_token")
    fau_token = get_contract("fau_token")
    dict_of_allowed_tokens = {
        dharma_token: get_contract("dai_usd_price_feed"),
        fau_token: get_contract("dai_usd_price_feed"),
        weth_token: get_contract("eth_usd_price_feed"),
    }
    add_allowed_tokens(token_farm, dict_of_allowed_tokens, account)
    if front_end_update:
        update_front_end()
    return token_farm, dharma_token


def add_allowed_tokens(token_farm, dict_of_allowed_tokens, account):
    for token in dict_of_allowed_tokens:
        add_tx = token_farm.addAllowedTokens(token.address, {"from": account})
        add_tx.wait(1)
        set_tx = token_farm.setPriceFeedContract(
            token.address, dict_of_allowed_tokens[token], {"from": account}
        )
        set_tx.wait(1)
    return token_farm


def update_front_end():
    # send brownie config over to the front end
    # tsx does not work well with yaml so we'll
    # send it in json format
    # Sending the front end our config in JSON format
    with open("brownie-config.yaml", "r") as brownie_config:
        config_dict = yaml.load(brownie_config, Loader=yaml.FullLoader)
        with open("./front_end/src/brownie-config.json", "w") as brownie_config_json:
            json.dump(config_dict, brownie_config_json)
        print("Front end updated")


def main():
    deploy_token_farm_and_dharma_token(front_end_update=True)

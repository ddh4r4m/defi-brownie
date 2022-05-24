from lib2to3.pgen2 import token
from brownie import network, exceptions
from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    INITIAL_PRICE_FEED_VALUE,
    get_account,
    get_contract,
)
import pytest
from scripts.deploy import deploy_token_farm_and_dharma_token


def test_set_price_feed_contract():
    # Arrange stage
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    non_owner = get_account(index=1)
    token_farm, dharma_token = deploy_token_farm_and_dharma_token()
    # Act Phase
    price_feed_address = get_contract("eth_usd_price_feed")
    token_farm.setPriceFeedContract(
        dharma_token.address, price_feed_address, {"from": account}
    )
    # Assert Phase
    assert token_farm.tokenPriceFeedMapping(dharma_token.address) == price_feed_address
    # make sure non owners can't call this
    with pytest.raises(exceptions.VirtualMachineError):
        token_farm.setPriceFeedContract(
            dharma_token.address, price_feed_address, {"from": account}
        )


def test_stake_tokens(amount_staked):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account()
    token_farm, dharma_token = deploy_token_farm_and_dharma_token()
    # Act
    dharma_token.approve(token_farm.address, amount_staked, {"from": account})
    token_farm.stakeTokens(amount_staked, dharma_token.address, {"from": account})
    # Assert
    assert (
        token_farm.stakingBalance(dharma_token.address, account.address)
        == amount_staked
    )
    assert token_farm.uniqueTokensStaked(account.address) == 1
    assert token_farm.stakers(0) == account.address
    return token_farm, dharma_token


def test_issue_tokens(amount_staked):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account()
    token_farm, dharma_token = test_stake_tokens(amount_staked)
    starting_balance = dharma_token.balanceOf(account.address)
    # Act
    token_farm.issueTokens({"from": account})
    # Arrange
    # we are staking one dharma_token which is equal in price ot 1 eth
    ## so we should get 3,000 dapp tokens in reward
    # since the price of eth is 3000 USD
    assert (
        dharma_token.balanceOf(account.address)
        == starting_balance + INITIAL_PRICE_FEED_VALUE
    )

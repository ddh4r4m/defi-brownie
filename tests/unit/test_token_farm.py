from brownie import network, exceptions
from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
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
            dharma_token.address, price_feed_address, {"from": non_owner}
        )

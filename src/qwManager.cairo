use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<T> {
    fn get_name(self: @T) -> felt252;
    fn get_symbol(self: @T) -> felt252;
    fn get_decimals(self: @T) -> u8;
    fn get_total_supply(self: @T) -> u256;
    fn balance_of(self: @T, account: ContractAddress) -> u256;
    fn allowance(self: @T, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: T, recipient: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: T, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn approve(ref self: T, spender: ContractAddress, amount: u256);
    fn increase_allowance(ref self: T, spender: ContractAddress, added_value: u256);
    fn decrease_allowance(
        ref self: T, spender: ContractAddress, subtracted_value: u256
    );
}

#[starknet::interface]
trait IManager<T> {
    // Returns the registry address
    fn getRegistry(self: @T) -> ContractAddress;
    // Executes the investment
    fn execute(ref self: T, targetQwChilds_: Array<ContractAddress>, tokenAddress_: Array<ContractAddress>, amount_: Array<u128>);
    // Closes the investment
    fn close(ref self: T, targetQwChilds_: Array<ContractAddress>, tokenAddress_: Array<ContractAddress>, amount_: Array<u128>);
}

#[starknet::interface]
trait IRegistry<T> {
    // Returns the manager address
    fn getIsChildWhitelisted(self: @T, child_: ContractAddress) -> bool;
}

#[starknet::interface]
trait IChild<T> {
    // Executes the investment
    fn create(ref self: T, tokenAddress_: ContractAddress, amount_: u256);
    // Closes the investment
    fn close(ref self: T, tokenAddress_: ContractAddress, amount_: u256);
    // Returns the manager address
    fn getManager(self: @T) -> ContractAddress;
}

#[starknet::contract]
mod QwManager {
    use starknet::ContractAddress;
    use super::{IChildDispatcher, IChildDispatcherTrait};
    use super::{IRegistryDispatcher, IRegistryDispatcherTrait};
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        registry: IRegistryDispatcher
    }

    // *************************************************************************
    //                              ERRORS
    // *************************************************************************
    mod Errors {
        const Invalid_Input_Length: felt252 = 'Invalid Input Length';
        const Contract_Not_Whitelisted: felt252 = 'Contract Not whitelisted';
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, registry_: ContractAddress) {
        let registryContract = IRegistryDispatcher {
                contract_address: registry_
            };
        self.registry.write(registryContract);
    }

    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl QwManager of super::IManager<ContractState> {
        fn getRegistry(self: @ContractState) -> ContractAddress {
            self.registry.read().contract_address
        }
        fn execute(ref self: ContractState, targetQwChilds_: Array<ContractAddress>, tokenAddress_: Array<ContractAddress>, amount_: Array<u128>) {
            assert(targetQwChilds_.len() == tokenAddress_.len(), Errors::Invalid_Input_Length);
            assert(targetQwChilds_.len() == amount_.len(), Errors::Invalid_Input_Length);

            let mut i = 0;
            while i != targetQwChilds_.len() {
                let childAddress = *targetQwChilds_.at(i);
                let tokenAddress = *tokenAddress_.at(i);
                let amount = *amount_.at(i);
                let is_whitelisted = self.registry.read().getIsChildWhitelisted(childAddress);
                assert(is_whitelisted == true, Errors::Contract_Not_Whitelisted);

                let erc20Token = IERC20Dispatcher {
                    contract_address: tokenAddress
                };
                erc20Token.approve(childAddress, amount.into());

                let childContract = IChildDispatcher {
                    contract_address: childAddress
                };
                childContract.create(tokenAddress, amount.into());
                i += 1;
            };
        }

        fn close(ref self: ContractState, targetQwChilds_: Array<ContractAddress>, tokenAddress_: Array<ContractAddress>, amount_: Array<u128>) {
            assert(targetQwChilds_.len() == tokenAddress_.len(), Errors::Invalid_Input_Length);
            assert(targetQwChilds_.len() == amount_.len(), Errors::Invalid_Input_Length);
            
            let mut i = 0;
            while i != targetQwChilds_.len() {
                let childAddress = *targetQwChilds_.at(i);
                let tokenAddress = *tokenAddress_.at(i);
                let amount = *amount_.at(i);
                let is_whitelisted = self.registry.read().getIsChildWhitelisted(childAddress);
                assert(is_whitelisted == true, Errors::Contract_Not_Whitelisted);

                let erc20Token = IERC20Dispatcher {
                    contract_address: tokenAddress
                };
                erc20Token.approve(childAddress, amount.into());

                let childContract = IChildDispatcher {
                    contract_address: childAddress
                };
                childContract.close(tokenAddress, amount.into());
                i += 1;
            };
        }
    }
}

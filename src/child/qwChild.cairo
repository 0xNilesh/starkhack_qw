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
trait IChild<T> {
    // Executes the investment
    fn create(ref self: T, tokenAddress_: ContractAddress, amount_: u256);
    // Closes the investment
    fn close(ref self: T, tokenAddress_: ContractAddress, amount_: u256);
    // Returns the manager address
    fn getManager(self: @T) -> ContractAddress;
}

#[starknet::contract]
mod QwChild {
    use starknet::{get_caller_address, ContractAddress, get_contract_address};
    use super::{IChildDispatcher, IChildDispatcherTrait};
    use super::{IManagerDispatcher, IManagerDispatcherTrait};
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        manager: IManagerDispatcher,
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
    fn constructor(ref self: ContractState, manager_: ContractAddress) {
        let managerContract = IManagerDispatcher {
                contract_address: manager_
            };
        self.manager.write(managerContract);
    }

    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl QwChild of super::IChild<ContractState> {
        fn getManager(self: @ContractState) -> ContractAddress {
            self.manager.read().contract_address
        }
        fn create(ref self: ContractState, tokenAddress_: ContractAddress, amount_: u256) {
            let erc20Token = IERC20Dispatcher {
                contract_address: tokenAddress_
            };

            let manager_address = self.manager.read().contract_address; // Get the manager's address
            let current_address = get_contract_address(); // Get the current contract's address

            erc20Token.transfer_from(manager_address, current_address, amount_);
        }

        fn close(ref self: ContractState, tokenAddress_: ContractAddress, amount_: u256) {
            let erc20Token = IERC20Dispatcher {
                contract_address: tokenAddress_
            };

            let manager_address = self.manager.read().contract_address; // Get the manager's address
            let current_address = get_contract_address(); // Get the current contract's address

            erc20Token.transfer_from(manager_address, current_address, amount_);
        }
    }
}

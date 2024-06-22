use starknet::ContractAddress;

#[starknet::interface]
trait IRegistry<T> {
    // Returns the manager address
    fn getManager(self: @T) -> ContractAddress;
    // Returns the manager address
    fn getIsChildWhitelisted(self: @T, child_: ContractAddress) -> bool;
    // Registers the child contract
    fn registerChild(ref self: T, child_: ContractAddress);
}

#[starknet::interface]
trait IChild<T> {
    // Returns the manager address
    fn getManager(self: @T) -> ContractAddress;
}

#[starknet::contract]
mod QwRegistry {
    use starknet::ContractAddress;
    use super::{IChildDispatcher, IChildDispatcherTrait};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        manager: ContractAddress,
        whitelist: LegacyMap<ContractAddress, bool>
    }

    // *************************************************************************
    //                              EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ChildRegistered: ChildRegistered,
    }

    #[derive(Drop, starknet::Event)]
    struct ChildRegistered {
        #[key]
        child: ContractAddress,
    }
    // *************************************************************************
    //                              ERRORS
    // *************************************************************************
    mod Errors {
        const Address_Zero: felt252 = 'Zero Address';
        const Parent_Mismatch: felt252 = 'Parent Mismatch';
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, manager_: ContractAddress) {
        self.manager.write(manager_);
    }

    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl QwRegistry of super::IRegistry<ContractState> {
        fn getManager(self: @ContractState) -> ContractAddress {
            self.manager.read()
        }
        fn getIsChildWhitelisted(self: @ContractState, child_: ContractAddress) -> bool {
            self.whitelist.read(child_)
        }
        fn registerChild(ref self: ContractState, child_: ContractAddress)  {
            assert(!child_.is_zero(), Errors::Address_Zero);

            let childContract = IChildDispatcher {
                contract_address: child_
            };
            assert(childContract.getManager() == self.manager.read(), Errors:: Parent_Mismatch);
            self.whitelist.write(child_, true);

            self.emit(ChildRegistered { child: child_});
        }
    }
}

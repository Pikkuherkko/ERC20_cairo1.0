// @author Pikkuherkko

#[contract]
mod ERC20 {
    use starknet::get_caller_address;

    struct Storage {
        name: felt,
        symbol: felt,
        decimals: u8,
        total_supply: u256,
        balances: LegacyMap::<felt, u256>, // address => u256
        allowances: LegacyMap::<(felt, felt), u256>, // (owner, spender) => u256
    }

    #[event]
    fn Transfer(from_: felt, to: felt, value: u256) {}

    #[event]
    fn Approval(owner: felt, spender: felt, value: u256) {}

    #[constructor]
    fn constructor(_name: felt, _symbol: felt, _decimals: u8, _initialSupply: u256) {
        name::write(_name);
        symbol::write(_symbol);
        assert(_decimals <= 255_u8, 'ERC20: decimals exceed 2^8');
        decimals::write(_decimals);
        total_supply::write(_initialSupply);
        let caller = get_caller_address();
        balances::write(caller, _initialSupply);
        Transfer(0, caller, _initialSupply);
    }

    // view functions

    #[view]
    fn get_name() -> felt {
        name::read()
    }

    #[view]
    fn get_symbol() -> felt {
        symbol::read()
    }

    #[view]
    fn get_decimals() -> u8 {
        decimals::read()
    }

    #[view]
    fn get_total_supply() -> u256 {
        total_supply::read()
    }

    #[view]
    fn balanceOf(account: felt) -> u256 {
        balances::read(account)
    }

    #[view]
    fn allowance(owner: felt, spender: felt) -> u256 {
        allowances::read((owner, spender))
    }

    // external functions

    #[external]
    fn transfer(to: felt, amount: u256) -> bool {
        let caller = get_caller_address();
        _transfer(caller, to, amount);
        true
    }

    #[external]
    fn transferFrom(from_: felt, to: felt, amount: u256) -> bool {
        let caller = get_caller_address();
        _spendAllowance(from_, caller, amount);
        _transfer(from_, to, amount);
        true
    }

    #[external]
    fn approve(spender: felt, amount: u256) -> bool {
        let caller = get_caller_address();
        _approve(caller, spender, amount);
        true
    }

    #[external]
    fn increaseAllowance(spender: felt, addedValue: u256) -> bool {
        let caller = get_caller_address();
        _approve(caller, spender, allowances::read((caller, spender)) + addedValue);
        true
    }

    #[external]
    fn decreaseAllowance(spender: felt, substractedValue: u256) -> bool {
        let caller = get_caller_address();
        _approve(caller, spender, allowances::read((caller, spender)) - substractedValue);
        true
    }

    // internal functions

    fn _transfer(sender: felt, recipient: felt, amount: u256) {
        assert(sender != 0, 'ERC20: cannot transfer from the zero address');
        assert(recipient != 0, 'ERC20: cannot transfer to the zero address');
        assert(balances::read(sender) >= amount, 'ERC20: transfer amount exceeds balance');
        balances::write(sender, balances::read(sender) - amount);
        balances::write(recipient, balances::read(recipient) + amount);
        Transfer(sender, recipient, amount);
    }

    fn _approve(owner: felt, spender: felt, amount: u256) {
        assert(owner != 0, 'ERC20: approve from the zero address');
        assert(spender != 0, 'ERC20: approve to the zero address');
        allowances::write((owner, spender), amount);
        Approval(owner, spender, amount);
    }

    fn _spendAllowance(owner: felt, spender: felt, amount: u256) {
        let currentAllowance = allowances::read((owner, spender));
        let max_of_u128 = 0xffffffffffffffffffffffffffffffff_u128;
        let is_unlimited = currentAllowance.low == max_of_u128 & currentAllowance.high == max_of_u128;
        if !is_unlimited {
            _approve(owner, spender, currentAllowance - amount);
        }
    }

}

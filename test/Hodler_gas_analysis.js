const _HodlerFactory = artifacts.require("HodlerFactory")
const _Hodler = artifacts.require("Hodler")
const test_WETH = artifacts.require("WETH")
const BN = web3.utils.BN
const fail = require('truffle-assertions')

contract('Hodler_test', async accounts => {
	let HodlerFactory
	let Hodler
	let WETH
	let price_low = 500
	let price_high = 1500
	before(async() => {
		WETH = await test_WETH.new()
		let base = new BN(10)
		let power = new BN(21)
		max = base.pow(power)
		HodlerFactory = await _HodlerFactory.deployed()
	})
	describe('analysis_factory_deploy', function () {
		it("gascost deploy Hodler instance", async () => {
			let receipt = await HodlerFactory.createHodler(WETH.address, {from: accounts[0]})
			let gasUsed = receipt.receipt.gasUsed;
			let gasPrice = 100000000000; 
			console.log("GasUsed: "+gasUsed)
			console.log("GasPrice Gwei: "+gasPrice / 10**9)
			let gascost = gasPrice * gasUsed / 10**18
			console.log("Gascost ETH: "+gascost)
			console.log("Gascost total FIAT @ $"+price_low+": "+gascost * price_low)
			console.log("Gascost total FIAT @ $"+price_high+": "+gascost * price_high)
		})
	})
	describe('analysis_hodler_deposit', function () {
		it("gascost Hodler deposit", async () => {
			let Hodler_address = await HodlerFactory.allHodlers.call(0)
			Hodler = await _Hodler.at(Hodler_address)
			let base = new BN(10)
			let power = new BN(18)
			let deposit = base.pow(power)

			let convert = await WETH.deposit({value: deposit})
			let approve = await WETH.approve(Hodler.address, deposit)
			let receipt = await Hodler.deposit(deposit)
			let gasUsed_convert = convert.receipt.gasUsed;
			let gasUsed_approve = approve.receipt.gasUsed; 
			let gasUsed_receipt = receipt.receipt.gasUsed;
			let gasPrice =  100000000000;
			let gasUsed_total = gasUsed_receipt + gasUsed_approve + gasUsed_convert

			console.log("GasPrice Gwei: "+gasPrice / 10**9)
			console.log("GasUsed convert: "+gasUsed_convert)
			console.log("GasUsed approve: "+gasUsed_approve)
			console.log("GasUsed deposit: "+gasUsed_receipt)
			console.log("GasUsed total: "+gasUsed_total)
			let gascost_convert = gasPrice * gasUsed_convert / 10**18
			console.log("Gascost convert ETH: "+gascost_convert)
			let gascost_approve = gasPrice * gasUsed_approve / 10**18
			console.log("Gascost approve ETH: "+gascost_approve)
			let gascost_receipt = gasPrice * gasUsed_receipt / 10**18
			console.log("Gascost deposit ETH: "+gascost_receipt)
			let gascost_total = gasPrice * gasUsed_total / 10**18
			console.log("Gascost total ETH: "+gascost_total)
			console.log("Gascost total FIAT @ $"+price_low+": "+gascost_total * price_low)
			console.log("Gascost total FIAT @ $"+price_high+": "+gascost_total * price_high)
		})
	})
	describe('analysis_hodler_withdraw', function () {
		it("gascost Hodler withdraw before start", async () => {
			let Hodler_address = await HodlerFactory.allHodlers.call(0)
			Hodler = await _Hodler.at(Hodler_address)
			let base = new BN(10)
			let power = new BN(18)
			let withdraw = base.pow(power)

			let started = await Hodler.started.call()
			console.log("Hodler started: "+started.toString())
			let receipt = await Hodler.withdraw(withdraw.toString())
			let gasUsed = receipt.receipt.gasUsed;
			let gasPrice =  100000000000;
			console.log("GasPrice Gwei: "+gasPrice / 10**9)
			console.log("GasUsed: "+gasUsed)
			let gascost = gasPrice * gasUsed / 10**18
			console.log("Gascost ETH: "+gascost)
			console.log("Gascost FIAT @ $"+price_low+": "+gascost * price_low)
			console.log("Gascost FIAT @ $"+price_high+": "+gascost * price_high)
		})
		it("gascost Hodler withdraw after start", async () => {
			let Hodler_address = await HodlerFactory.allHodlers.call(0)
			Hodler = await _Hodler.at(Hodler_address)
			await WETH.deposit({value: max.toString()})
			await WETH.approve(Hodler.address, max.toString())
			await Hodler.deposit(max.toString())
			let base = new BN(10)
			let power = new BN(18)
			let withdraw = base.pow(power)

			let started = await Hodler.started.call()
			console.log("Hodler started: "+started.toString())
			let receipt = await Hodler.withdraw(withdraw.toString())
			let gasUsed = receipt.receipt.gasUsed;
			let gasPrice =  100000000000;
			console.log("GasPrice Gwei: "+gasPrice / 10**9)
			console.log("GasUsed: "+gasUsed)
			let gascost = gasPrice * gasUsed / 10**18
			console.log("Gascost ETH: "+gascost)
			console.log("Gascost FIAT @ $"+price_low+": "+gascost * price_low)
			console.log("Gascost FIAT @ $"+price_high+": "+gascost * price_high)
		})
	})
})

const { assert, expect } = require("chai")
const { network, deployments, ethers, getNamedAccounts } = require("hardhat")
const {developmentChains, networkConfig} = require("../../helper-hardhat-config")


developmentChains.includes(network.name) 
? describe.skip 
: describe("Raffle", async function () {
    let raffle, raffleEntranceFee, deployer

    beforeEach(async function () {
        deployer = (await getNamedAccounts()).deployer
        raffle = await ethers.getContract("Raffle", deployer)
        raffleEntranceFee = await raffle.getEntranceFee()  
    })

    describe("fulfillRandomWords", function () {
        it("works with Chainlink Keepers and VRF", async function () {
            console.log("Testing")
            const startingTimeStamp = await raffle.getLastTimeStamp()
            const accounts = await ethers.getSigners()

            console.log("Set Up Listener...")
            await new Promise(async (resolve, reject) => {
                raffle.once("WinnerPicked", async () => {
                    console.log("WinnerPicked event fired!")
                    try {
                        //add asserts here 
                        const recentWinner = await raffle.getRecentWinner()
                        const raffleState = await raffle.getRaffleState()
                        const winnerEndingBalance = await accounts[0].getBalance()
                        const endingTimeStamp = await raffle.getLastestTimeStamp()

                        await expect(raffle.getPlayer(0)).to.be.reverted
                        assert.equal(recentWinner.toString(), accounts[0].address)
                        assert.equal(raffleState, 0)
                        assert.equal(
                            winnerEndingBalance.toString(),
                             winnerStartingBalance.add(raffleEntranceFee).toString()
                        )
                        assert(endingTimeStamp > startingTimeStamp)
                        resolve()

                    } catch (error) {
                        console.log(error)
                        reject(e)
                    }
                })
                // entering the raffle
                console.log("Entering Rafle")
                const tx = await raffle.enterRaffle({ value: raffleEntranceFee })
                await tx.wait(1)
                console.log("Waiting")
                await raffle.enterRaffle({value: raffleEntranceFee})
                const winnerStartingBalance = await accounts[0].getBalance()
                
                // the code wont complete until listener has finished
            })

            // setup listener
            //in case blockhain is fast
            
        })
    })

})
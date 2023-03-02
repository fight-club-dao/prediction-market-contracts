import { expect } from 'chai';
import { ethers, network } from 'hardhat';
import {
    USDT_ADDRESS,
    WBTC_ADDRESS,
    UNISWAPV2_ROUTER_ADDRESS,
    UNISWAPV2_FACTORY_ADDRESS,
    USDT_OWNER
} from '../helpers/constants';
import exp from "constants";

const IERC20Artifact = require('@uniswap/v2-core/build/IUniswapV2ERC20.json');

describe("Test 2", function () {
    let user1 ,user2,user3,user4,user10, borrower, liquidator, usdtOwner,tokenA ,tokenB,tokenC,tokenD, usdc;
    let mockToken, MockToken, lpA, lpB, lpC,lpD;
    let UniswapV2Locker,uniswapFactory, locker, wbtc, usdt, uniswapRouter;
    let usdtDecimals = 10**6;
    let snap_a_id,snap_b_id


    before(async function() {
        [user1,user2, borrower,user3,user4 , user10, liquidator, usdtOwner] = await ethers.getSigners();
        MockToken = await ethers.getContractFactory('ERC20teamToken');
        UniswapV2Locker = await ethers.getContractFactory('UniswapV2Locker');
        locker = await UniswapV2Locker.deploy(UNISWAPV2_FACTORY_ADDRESS, UNISWAPV2_ROUTER_ADDRESS);
        tokenA = await MockToken.deploy("A","A",9,locker.address,UNISWAPV2_ROUTER_ADDRESS,USDT_ADDRESS);
        tokenB = await MockToken.deploy("B","B",9,locker.address,UNISWAPV2_ROUTER_ADDRESS,USDT_ADDRESS);
        tokenC = await MockToken.deploy("C","C",9,locker.address,UNISWAPV2_ROUTER_ADDRESS,USDT_ADDRESS);
        tokenD = await MockToken.deploy("D","D",9,locker.address,UNISWAPV2_ROUTER_ADDRESS,USDT_ADDRESS);
        usdc   = await MockToken.deploy("USDC","USDC",6,locker.address,UNISWAPV2_ROUTER_ADDRESS,USDT_ADDRESS);
        console.log("tokenA ",tokenA.address);
        console.log("tokenB ",tokenB.address);
        console.log("tokenC ",tokenC.address);
        console.log("tokenD ",tokenD.address);
        wbtc = await ethers.getContractAt(IERC20Artifact.abi,WBTC_ADDRESS);
        usdt = await ethers.getContractAt('IUSDT',USDT_ADDRESS);
        uniswapRouter = await ethers.getContractAt('IUniswapV2Router01',UNISWAPV2_ROUTER_ADDRESS);
        uniswapFactory = await ethers.getContractAt('IUniswapV2Factory',UNISWAPV2_FACTORY_ADDRESS);
    })

    it("Change USDT ownership & transfer usdt to users", async function () {

        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [USDT_OWNER],
        });
        const signer = await ethers.getSigner(USDT_OWNER)

        expect(signer.address).to.be.eq(USDT_OWNER)
        expect(await usdt.getOwner()).to.be.eq(USDT_OWNER)

        await user1.sendTransaction({
            to: signer.address,
            value: "10000000000000000000", // Sends exactly 10 ether
        });
        await usdt.connect(signer).transferOwnership(usdtOwner.address)

        expect(await usdt.getOwner()).to.be.eq(usdtOwner.address)

        await usdt.connect(usdtOwner).issue("1000000000000000"); //Issue 1 billion usdt tokens
        console.log("usdt ",usdt.address);
        //transfer usdt to liquidator
        await usdt.connect(usdtOwner).transfer(user3.address,"1000000000000")
        await usdt.connect(usdtOwner).transfer(user2.address,"1000000000000")
        await usdt.connect(usdtOwner).transfer(user1.address,"1000000000000")
        await usdt.connect(usdtOwner).transfer(user4.address,"1000000000000")
        expect(await usdt.balanceOf(user2.address)).to.be.equal("1000000000000")

    })

    it("provide liquidity", async function () {
        await tokenA.approve(uniswapRouter.address, '500000000000000000000000000000')
        await tokenB.approve(uniswapRouter.address, '500000000000000000000000000000')
        await tokenC.approve(uniswapRouter.address, '500000000000000000000000000000')
        await tokenD.approve(uniswapRouter.address, '500000000000000000000000000000')
        await usdt.approve(uniswapRouter.address, '500000000000000000000000000000')
        //PROVIDE LIQUIDITY FOR TEAM A
        await uniswapRouter.addLiquidity(tokenA.address, usdt.address, '1000000000000000',1000*usdtDecimals,'0','0',user1.address,'99999999999999999999');
        let pair = await uniswapFactory.getPair(tokenA.address, usdt.address);
        lpA = await ethers.getContractAt(IERC20Artifact.abi,pair);
        expect(await lpA.balanceOf(user1.address)).to.be.gt(0)
        //PROVIDE LIQUIDITY FOR TEAM B
        await uniswapRouter.addLiquidity(tokenB.address, usdt.address, '1000000000000000',1000*usdtDecimals,'0','0',user1.address,'99999999999999999999');
        lpB = await ethers.getContractAt(IERC20Artifact.abi,await uniswapFactory.getPair(tokenB.address, usdt.address));
        expect(await lpB.balanceOf(user1.address)).to.be.gt(0)
        //PROVIDE LIQUIDITY FOR TEAM C
        await uniswapRouter.addLiquidity(tokenC.address, usdt.address, '1000000000000000',1000*usdtDecimals,'0','0',user1.address,'99999999999999999999');
        lpC = await ethers.getContractAt(IERC20Artifact.abi,await uniswapFactory.getPair(tokenC.address, usdt.address));
        expect(await lpC.balanceOf(user1.address)).to.be.gt(0)
        //PROVIDE LIQUIDITY FOR TEAM D
        await uniswapRouter.addLiquidity(tokenD.address, usdt.address, '1000000000000000',1000*usdtDecimals,'0','0',user1.address,'99999999999999999999');
        lpD = await ethers.getContractAt(IERC20Artifact.abi,await uniswapFactory.getPair(tokenD.address, usdt.address));
        expect(await lpD.balanceOf(user1.address)).to.be.gt(0)

    })

    it("Lock liquidity", async function () {

        let lpAamount = await lpA.balanceOf(user1.address);
        let lpBamount = await lpB.balanceOf(user1.address);
        await lpA.approve(locker.address, lpAamount)
        await lpB.approve(locker.address, lpBamount)
        let res3 = await locker.lockLPTokenWithBet(lpA.address,tokenA.address, lpAamount,lpB.address,tokenB.address, lpBamount, 1133,'1000000000')

        // let res2 = await lpA.balanceOf(user1.address);
        expect(await lpA.balanceOf(user1.address)).to.be.equal("0")
        expect(await lpB.balanceOf(user1.address)).to.be.equal("0")


    })
    it("should be before_start", async function () {
        let [ a, b,c,d] = await locker.getStats(0);
        // console.log(a);
        // console.log(b);
        console.log(d);

        expect(d ).to.be.equal('BEFORE_START');

    })
    it("user2 and user3 should buy tokens A", async function () {
        await usdt.connect(user2).approve(uniswapRouter.address, '11111111111111111111');
        await uniswapRouter.connect(user2).swapExactTokensForTokens('1000000',0,[usdt.address,tokenA.address],user2.address,166975744299);
        let tokenAbalance= await tokenA.balanceOf(user2.address);
        console.log("user2 tokenA balance = ", tokenAbalance)
        expect(tokenAbalance).to.be.gt(0)

        await usdt.connect(user3).approve(uniswapRouter.address, '11111111111111111111');
        await uniswapRouter.connect(user3).swapExactTokensForTokens('1000000',0,[usdt.address,tokenA.address],user3.address,166975744299);
        let tokenAbalance2= await tokenA.balanceOf(user3.address);
        console.log("user3 tokenA balance = ", tokenAbalance2)
        console.log("token A pool balance: ",await  tokenA.balanceOf(lpA.address));
        expect(tokenAbalance2).to.be.gt(0)


    })

    it("user3 should buy tokens B", async function () {
        // await usdt.connect(user3).approve(uniswapRouter.address, '11111111111111111111');
        await uniswapRouter.connect(user3).swapExactTokensForTokens('10000000',0,[usdt.address,tokenB.address],user3.address,266975744299);
        expect(await tokenB.balanceOf(user3.address)).to.be.gt(0)


    })
    it("should pause transfers", async function () {

        await locker.startMatch(0);
        expect(await tokenA.paused()).to.be.equal(true);
        expect(await tokenB.paused()).to.be.equal(true);

    })
    it("should be before_start", async function () {
        let [ a, b,c,d] = await locker.getStats(0);
        console.log(a);
        console.log(b);
        console.log(c);
        console.log(d);

        expect(d ).to.be.equal('ON_GOING');

    })
    it("should set max wallet size unlimited", async function () {
        await tokenA.setMaxWalletSize('1000000000000000000000000000');
        await tokenB.setMaxWalletSize('1000000000000000000000000000');
    })
    // it("should not transfer tokens", async function (){
    //     await expect( tokenA.connect(user1).transfer(user2.address,'250000000000000000000000'))
    //         .to.revertedWith("ERC20Pausable: token transfer while paused");
    // })
    // it("getters should work", async function (){
    //     let [a, b] = await locker.getCurrentTotalPrizes(0);
    //
    //     expect(a).to.be.equal("10000000")
    //     expect(b).to.be.equal("10000000")
    //
    // })
    it("should get stats", async function () {
        let [ a, b] = await locker.getStats(0);
        // console.log(a);
        // console.log(b);
        expect(a.traded).to.be.equal(false);
        expect(b.traded).to.be.equal(false);

    })
    it("should not get stats", async function () {

        await expect(locker.getStats(5)).be.revertedWith('lock id is not exist')


    })

    it("should announce results & take snapshot & return initials", async function () {
        console.log("lp token a amount: ", await lpB.balanceOf(locker.address));
        let before = await usdt.balanceOf(user1.address);
        // expect(before).to.be.equal("998000000000");
        // await tokenB.setPoolAddress(lpB.address); //todo callthis within the contract

        await locker.announceResult(0 , 1,true);

        console.log("lp token a amount: ", await lpB.balanceOf(locker.address));
        let results = await locker.betLocks(0);
        expect(results.result).to.be.equal(1);
        let after = await usdt.balanceOf(user1.address);
        expect(after).to.be.gt(before);


    })
    it("should be ended", async function () {
        let [ a, b,c,d] = await locker.getStats(0);
        console.log(d);

        expect(d ).to.be.equal('ENDED');

    })
    // it("getters should work", async function (){
    //     let [a, b] = await locker.getCurrentTotalPrizes(0);
    //     expect(a).to.be.equal("10000000")
    //     expect(b).to.be.equal("10000000")
    // })
    it("User2 Should claim", async function () {
        let totalLpPrize = await lpB.balanceOf(locker.address);
        console.log(totalLpPrize);
        let lpBbefore = await lpB.balanceOf(user2.address);
        console.log("lpBbefore before: ",lpBbefore);
        console.log("b before: ",await tokenB.balanceOf(user2.address));
        expect(await lpB.balanceOf(user2.address)).to.be.equal("0")
        await locker.connect(user2).claim(0);
        let lpBafter = await lpB.balanceOf(user2.address);
        console.log("lpB After: ",await lpB.balanceOf(user2.address));

        expect(lpBafter).to.be.gt(lpBbefore)
    })
    it("User3 Should claim", async function () {
        let totalLpPrize = await lpB.balanceOf(locker.address);
        console.log(totalLpPrize);
        let lpBbefore = await lpB.balanceOf(user3.address);
        console.log("lpBbefore before: ",lpBbefore);
        console.log("b before: ",await tokenB.balanceOf(user3.address));
        expect(await lpB.balanceOf(user3.address)).to.be.equal("0")
        await locker.connect(user3).claim(0);
        let lpBafter = await lpB.balanceOf(user3.address);
        console.log("lpB After: ",await lpB.balanceOf(user3.address));

        expect(lpBafter).to.be.gt(lpBbefore)
    })
    // it("Should claimAndRemoveLiquidity", async function () {
    //     let totalLpPrize = await lpB.balanceOf(locker.address);
    //     let usdtBefore = await usdt.balanceOf(user2.address);
    //     console.log("usdt before: ",usdtBefore);
    //     console.log("b before: ",await tokenB.balanceOf(user2.address));
    //     expect(await lpB.balanceOf(user2.address)).to.be.equal("0")
    //     await locker.connect(user2).claimAndRemoveLiquidity(0);
    //     let usdtAfter = await usdt.balanceOf(user2.address);
    //     console.log("lpb after: ",await lpB.balanceOf(user2.address));
    //     console.log("usdt usdtAfter: ",await usdt.balanceOf(user2.address));
    //     console.log("b after: ",await tokenB.balanceOf(user2.address));
    //     console.log(totalLpPrize);
    //     expect(usdtAfter).to.be.gt(usdtBefore)
    // })
    it("Should not claim again", async function () {
        await expect(locker.connect(user2).claim(0)).to.be.revertedWith('User already claimed');
    })
    it("user3 should buy tokens C", async function () {
        // await usdt.connect(user3).approve(uniswapRouter.address, '11111111111111111111');
        await uniswapRouter.connect(user3).swapExactTokensForTokens('15000000',0,[usdt.address,tokenC.address],user3.address,266975744299);
        expect(await tokenC.balanceOf(user3.address)).to.be.gt(0)
    })
    it("user4 should buy tokens D", async function () {
        await usdt.connect(user4).approve(uniswapRouter.address, '11111111111111111111');
        await uniswapRouter.connect(user4).swapExactTokensForTokens('15000000',0,[usdt.address,tokenD.address],user4.address,266975744299);
        expect(await tokenD.balanceOf(user4.address)).to.be.gt(0)
    })
    it("Lock liquidity", async function () {
        let lpDamount = await lpD.balanceOf(user1.address);
        let lpCamount = await lpC.balanceOf(user1.address);
        await lpD.approve(locker.address, lpDamount)
        await lpC.approve(locker.address, lpCamount)
        console.log(lpDamount)
        console.log(lpCamount)
        let res3 = await locker.lockLPTokenWithBet(lpD.address,tokenD.address, lpDamount,lpC.address,tokenC.address, lpCamount, 1133,'1000000000')
        // let res2 = await lpA.balanceOf(user1.address);
        expect(await lpD.balanceOf(user1.address)).to.be.equal("0")
        expect(await lpC.balanceOf(user1.address)).to.be.equal("0")
    })
    it("should not be pause", async function () {
        expect(await tokenD.paused()).to.be.equal(false);
        expect(await tokenC.paused()).to.be.equal(false);

    })
    it("should pause transfers", async function () {

        await locker.startMatch(1);
        expect(await tokenD.paused()).to.be.equal(true);
        expect(await tokenC.paused()).to.be.equal(true);

    })
    it("should be before_start", async function () {
        let [ a, b,c,d] = await locker.getStats(1);
        console.log("stats for 1 ---------");
        console.log(a);
        console.log(b);
        console.log(c);
        console.log(d);

        expect(d ).to.be.equal('ON_GOING');

    })
    it("should set max wallet size unlimited", async function () {
        await tokenD.setMaxWalletSize('1000000000000000000000000000');
        await tokenC.setMaxWalletSize('1000000000000000000000000000');
    })
    it("should announce results & take snapshot & return initials", async function () {
        console.log("lp token a amount: ", await lpC.balanceOf(locker.address));
        let before = await usdt.balanceOf(user1.address);
        // expect(before).to.be.equal("998000000000");
        // await tokenB.setPoolAddress(lpB.address); //todo callthis within the contract

        await locker.announceResult(1 , 2,true);

        console.log("lp token a amount: ", await lpC.balanceOf(locker.address));
        let results = await locker.betLocks(1);
        expect(results.result).to.be.equal(2);
        let after = await usdt.balanceOf(user1.address);
        console.log("before: ",before);
        console.log("after: ",after);
        expect(after).to.be.gt(before);
    })
    it("Should claimAndRemoveLiquidity", async function () {
        let totalLpPrize = await lpD.balanceOf(locker.address);
        let usdtBefore = await usdt.balanceOf(user3.address);
        console.log("usdt before: ",usdtBefore);
        console.log("C before: ",await tokenC.balanceOf(user3.address));
        expect(await lpC.balanceOf(user3.address)).to.be.equal("0")
        await locker.connect(user3).claimAndRemoveLiquidity(1,0);
        let usdtAfter = await usdt.balanceOf(user3.address);
        console.log("lpb after: ",await lpC.balanceOf(user3.address));
        console.log("usdt usdtAfter: ",await usdt.balanceOf(user3.address));
        console.log("b after: ",await tokenC.balanceOf(user3.address));
        console.log(totalLpPrize);
        console.log("lpd :::: after claim :",await lpD.balanceOf(locker.address))
        expect(usdtAfter).to.be.gt(usdtBefore)
    })
    it("Lock liquidity", async function () {
        let lpCamount = await lpC.balanceOf(locker.address);
        let lpAamount = await lpA.balanceOf(locker.address);
        await lpD.approve(locker.address, lpCamount)
        await lpA.approve(locker.address, lpAamount)
        console.log(lpCamount)
        console.log(lpAamount)
        let res3 = await locker.lockLPTokenWithBet(lpC.address,tokenC.address, lpCamount,lpA.address,tokenA.address, lpAamount, 1133,'1000000000')
        // let res2 = await lpA.balanceOf(user1.address);
        expect(await lpC.balanceOf(user1.address)).to.be.equal("0")
        expect(await lpA.balanceOf(user1.address)).to.be.equal("0")
    })
    it("should not be pause", async function () {
        expect(await tokenC.paused()).to.be.equal(false);
        expect(await tokenA.paused()).to.be.equal(false);

    })
    it("should pause transfers", async function () {

        await locker.startMatch(2);
        expect(await tokenA.paused()).to.be.equal(true);
        expect(await tokenC.paused()).to.be.equal(true);

    })
    it("should be before_start", async function () {
        let [ a, b,c,d] = await locker.getStats(2);
        console.log(d);

        expect(d ).to.be.equal('ON_GOING');

    })
    it("should set max wallet size unlimited", async function () {
        await tokenA.setMaxWalletSize('1000000000000000000000000000');
        await tokenC.setMaxWalletSize('1000000000000000000000000000');
    })
    it("should announce results & take snapshot & return initials", async function () {
        console.log("lp token a amount: ", await lpC.balanceOf(locker.address));
        let before = await usdt.balanceOf(user1.address);
        // expect(before).to.be.equal("998000000000");
        // await tokenB.setPoolAddress(lpB.address); //todo callthis within the contract

        await locker.announceResult(2 , 1,true);

        console.log("lp token a amount: ", await lpC.balanceOf(locker.address));
        let results = await locker.betLocks(2);
        expect(results.result).to.be.equal(1);
        let after = await usdt.balanceOf(user1.address);
        expect(after).to.be.gt(before);
    })
    it("Should claimAndRemoveLiquidity", async function () {
        let totalLpPrize = await lpA.balanceOf(locker.address);
        let usdtBefore = await usdt.balanceOf(user3.address);
        console.log("usdt before: ",usdtBefore);
        console.log("C before: ",await tokenC.balanceOf(user3.address));
        expect(await lpC.balanceOf(user3.address)).to.be.equal("0")
        await locker.connect(user3).claimAndRemoveLiquidity(2,0);
        let usdtAfter = await usdt.balanceOf(user3.address);
        console.log("lpb after: ",await lpC.balanceOf(user3.address));
        console.log("usdt usdtAfter: ",await usdt.balanceOf(user3.address));
        console.log("b after: ",await tokenC.balanceOf(user3.address));
        console.log(totalLpPrize);
        expect(usdtAfter).to.be.gt(usdtBefore)
    })
    it("try to withdraw", async function () {
        expect(await lpC.balanceOf(locker.address)).to.be.equal('999999999000')
        await locker.withdrawToken(lpC.address,'999999999000')
    })

})
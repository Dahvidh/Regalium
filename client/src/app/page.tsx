"use client";

import { useState } from "react";
import { ethers } from "ethers";
import { toast } from "react-hot-toast";

export default function PresalePage() {
  const [walletAddress, setWalletAddress] = useState<string | null>(null);
  const [maticAmount, setMaticAmount] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const rate = 500;

  const connectWallet = async () => {
    try {
      if (!window.ethereum) return toast.error("Install MetaMask first.");
      const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
      setWalletAddress(accounts[0]);
      toast.success("Wallet connected!");
    } catch {
      toast.error("Failed to connect wallet");
    }
  };

  const handleBuy = async () => {
    if (!walletAddress) return toast.error("Please connect your wallet");
    if (!maticAmount || parseFloat(maticAmount) <= 0) return toast.error("Invalid amount");

    try {
      setIsLoading(true);
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      const presaleAddress = "0xYourPresaleContractAddress"; // Replace with your deployed contract
      const tx = await signer.sendTransaction({
        to: presaleAddress,
        value: ethers.parseEther(maticAmount),
      });

      await tx.wait();
      toast.success("You bought $RGLM!");
      setMaticAmount("");
    } catch (err) {
      toast.error("Transaction failed");
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#020617] to-[#0f172a] text-white">
      <main className="flex flex-col items-center justify-center py-20 px-4">
        <h1 className="text-4xl font-bold mb-2 text-yellow-400">Regalium Presale</h1>
        <p className="text-gray-400 mb-8">Swap your MATIC for $RGLM and join the future of GameFi.</p>

        <div className="bg-[#0f172a]/70 border border-yellow-500/30 rounded-2xl p-8 w-full max-w-md text-center shadow-lg">
          {!walletAddress ? (
            <button
              onClick={connectWallet}
              className="w-full py-3 rounded-lg bg-gradient-to-r from-yellow-500 to-amber-600 font-semibold"
            >
              Connect Wallet
            </button>
          ) : (
            <>
              <div className="mb-4">
                <label className="block mb-2 text-sm text-gray-400">Enter MATIC Amount</label>
                <input
                  type="number"
                  value={maticAmount}
                  onChange={(e) => setMaticAmount(e.target.value)}
                  className="w-full px-4 py-3 rounded-lg bg-[#1e293b] border border-gray-600 text-white"
                  placeholder="0.0"
                />
              </div>

              {maticAmount && (
                <p className="text-gray-400 mb-4">
                  You’ll receive{" "}
                  <span className="text-yellow-400 font-semibold">
                    {(parseFloat(maticAmount) * rate).toFixed(2)} $RGLM
                  </span>
                </p>
              )}

              <button
                onClick={handleBuy}
                disabled={isLoading}
                className="w-full py-3 rounded-lg bg-gradient-to-r from-yellow-500 to-amber-600 font-semibold"
              >
                {isLoading ? "Processing..." : "Buy $RGLM"}
              </button>
            </>
          )}
        </div>
      </main>
    </div>
  );
}

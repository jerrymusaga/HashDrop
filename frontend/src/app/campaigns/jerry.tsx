<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HashDrop Campaign Factory - UX Flow</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            text-align: center;
            color: white;
            margin-bottom: 40px;
        }

        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            font-weight: 700;
        }

        .header p {
            font-size: 1.2rem;
            opacity: 0.9;
        }

        .flow-container {
            display: grid;
            gap: 30px;
        }

        .flow-step {
            background: white;
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .flow-step:hover {
            transform: translateY(-5px);
            box-shadow: 0 25px 50px rgba(0,0,0,0.15);
        }

        .step-header {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
        }

        .step-number {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            width: 50px;
            height: 50px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 1.2rem;
            margin-right: 15px;
        }

        .step-title {
            font-size: 1.5rem;
            font-weight: 600;
            color: #2d3748;
        }

        .mockup {
            background: #f8fafc;
            border-radius: 15px;
            padding: 25px;
            margin: 20px 0;
            border: 2px solid #e2e8f0;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-label {
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #4a5568;
        }

        .form-input {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e2e8f0;
            border-radius: 10px;
            font-size: 16px;
            transition: border-color 0.3s ease;
        }

        .form-input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }

        .toggle-switch {
            position: relative;
            display: inline-block;
            width: 60px;
            height: 34px;
        }

        .toggle-switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }

        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #ccc;
            transition: .4s;
            border-radius: 34px;
        }

        .slider:before {
            position: absolute;
            content: "";
            height: 26px;
            width: 26px;
            left: 4px;
            bottom: 4px;
            background-color: white;
            transition: .4s;
            border-radius: 50%;
        }

        input:checked + .slider {
            background-color: #667eea;
        }

        input:checked + .slider:before {
            transform: translateX(26px);
        }

        .cost-breakdown {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
            padding: 20px;
            border-radius: 15px;
            margin: 20px 0;
        }

        .cost-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
        }

        .cost-total {
            border-top: 2px solid rgba(255,255,255,0.3);
            padding-top: 15px;
            margin-top: 15px;
            font-size: 1.2rem;
            font-weight: bold;
        }

        .btn {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 15px 30px;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 10px;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
        }

        .btn-secondary {
            background: #e2e8f0;
            color: #4a5568;
        }

        .btn-secondary:hover {
            background: #cbd5e0;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }

        .feature-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            border: 2px solid #e2e8f0;
            text-align: center;
        }

        .feature-icon {
            font-size: 2rem;
            margin-bottom: 10px;
        }

        .progress-bar {
            background: #e2e8f0;
            height: 8px;
            border-radius: 4px;
            overflow: hidden;
            margin: 20px 0;
        }

        .progress-fill {
            background: linear-gradient(90deg, #667eea, #764ba2);
            height: 100%;
            transition: width 0.3s ease;
            border-radius: 4px;
        }

        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.9rem;
            font-weight: 600;
        }

        .status-active {
            background: #c6f6d5;
            color: #22543d;
        }

        .status-deploying {
            background: #fef5e7;
            color: #744210;
        }

        .tabs {
            display: flex;
            background: #f1f5f9;
            border-radius: 10px;
            padding: 5px;
            margin-bottom: 20px;
        }

        .tab {
            flex: 1;
            padding: 12px 20px;
            text-align: center;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s ease;
        }

        .tab.active {
            background: white;
            color: #667eea;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .analytics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }

        .metric-card {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 20px;
            border-radius: 15px;
            text-align: center;
        }

        .metric-value {
            font-size: 2rem;
            font-weight: bold;
            margin-bottom: 5px;
        }

        .metric-label {
            opacity: 0.9;
        }

        .chain-selector {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 15px;
            margin: 15px 0;
        }

        .chain-option {
            border: 2px solid #e2e8f0;
            border-radius: 10px;
            padding: 15px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .chain-option:hover {
            border-color: #667eea;
        }

        .chain-option.selected {
            border-color: #667eea;
            background: #f7faff;
        }

        .help-text {
            color: #718096;
            font-size: 0.9rem;
            margin-top: 5px;
        }

        .warning-box {
            background: #fed7d7;
            border: 2px solid #fc8181;
            color: #742a2a;
            padding: 15px;
            border-radius: 10px;
            margin: 15px 0;
        }

        .success-box {
            background: #c6f6d5;
            border: 2px solid #68d391;
            color: #22543d;
            padding: 15px;
            border-radius: 10px;
            margin: 15px 0;
        }

        @media (max-width: 768px) {
            .form-row {
                grid-template-columns: 1fr;
            }
            
            .chain-selector {
                grid-template-columns: repeat(2, 1fr);
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎯 HashDrop Campaign Factory</h1>
            <p>Turn Your Hashtag Into a Cross-Chain NFT Campaign</p>
        </div>

        <div class="flow-container">
            <!-- Step 1: Campaign Mode Selection -->
            <div class="flow-step">
                <div class="step-header">
                    <div class="step-number">1</div>
                    <div class="step-title">Choose Your Campaign Style</div>
                </div>
                
                <div class="mockup">
                    <div class="tabs">
                        <div class="tab active" onclick="switchTab('simple')">🚀 Simple Mode</div>
                        <div class="tab" onclick="switchTab('advanced')">⚙️ Advanced Mode</div>
                    </div>
                    
                    <div id="simple-mode">
                        <div class="features-grid">
                            <div class="feature-card">
                                <div class="feature-icon">⚡</div>
                                <h4>One-Click Launch</h4>
                                <p>Just hashtag, image, and go!</p>
                            </div>
                            <div class="feature-card">
                                <div class="feature-icon">🌐</div>
                                <h4>Auto Multi-Chain</h4>
                                <p>Deploy across popular L2s</p>
                            </div>
                            <div class="feature-card">
                                <div class="feature-icon">🎨</div>
                                <h4>Single NFT Tier</h4>
                                <p>Everyone gets the same reward</p>
                            </div>
                        </div>
                        <p class="help-text">Perfect for first-time users or quick campaigns</p>
                    </div>
                    
                    <div id="advanced-mode" style="display:none;">
                        <div class="features-grid">
                            <div class="feature-card">
                                <div class="feature-icon">🏆</div>
                                <h4>Custom Tiers</h4>
                                <p>Bronze, Silver, Gold rewards</p>
                            </div>
                            <div class="feature-card">
                                <div class="feature-icon">⛓️</div>
                                <h4>Chain Selection</h4>
                                <p>Pick specific networks</p>
                            </div>
                            <div class="feature-card">
                                <div class="feature-icon">📊</div>
                                <h4>Custom Monitoring</h4>
                                <p>Set your own intervals</p>
                            </div>
                        </div>
                        <p class="help-text">For power users who want full control</p>
                    </div>
                </div>
            </div>

            <!-- Step 2: Campaign Details -->
            <div class="flow-step">
                <div class="step-header">
                    <div class="step-number">2</div>
                    <div class="step-title">Campaign Details</div>
                </div>
                
                <div class="mockup">
                    <div class="form-group">
                        <label class="form-label">Campaign Hashtag *</label>
                        <input type="text" class="form-input" placeholder="#mycampaign" value="#buildwithbase">
                        <div class="help-text">Must start with # and contain only letters, numbers, and underscores</div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Campaign Description *</label>
                        <input type="text" class="form-input" placeholder="Tell people what your campaign is about..." value="Celebrating builders on Base blockchain">
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Duration (Days) *</label>
                            <input type="number" class="form-input" min="1" max="365" value="30" id="duration-input">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Total NFT Rewards *</label>
                            <input type="number" class="form-input" min="1" max="10000" value="1000" id="nft-count-input">
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">NFT Collection Name *</label>
                        <input type="text" class="form-input" placeholder="My Awesome NFT" value="Base Builder Badge">
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">NFT Image URL *</label>
                        <input type="url" class="form-input" placeholder="https://your-image.com/nft.png" value="https://example.com/builder-badge.png">
                        <div class="help-text">High-quality image recommended (512x512 or larger)</div>
                    </div>
                </div>
            </div>

            <!-- Step 3: Multi-Chain Configuration -->
            <div class="flow-step">
                <div class="step-header">
                    <div class="step-number">3</div>
                    <div class="step-title">Multi-Chain Setup</div>
                </div>
                
                <div class="mockup">
                    <div class="form-group">
                        <label class="form-label">Enable Multi-Chain Distribution</label>
                        <div style="display: flex; align-items: center; gap: 15px; margin-top: 10px;">
                            <label class="toggle-switch">
                                <input type="checkbox" id="multichain-toggle" onchange="toggleMultiChain()">
                                <span class="slider"></span>
                            </label>
                            <span>Deploy across multiple blockchains (+50% cost)</span>
                        </div>
                        <div class="help-text">Multi-chain campaigns reach more users but cost more</div>
                    </div>
                    
                    <div id="chain-selection" style="display:none;">
                        <label class="form-label">Select Chains (Auto-selected popular chains)</label>
                        <div class="chain-selector">
                            <div class="chain-option selected">
                                <div style="font-size: 1.5rem;">🟣</div>
                                <div>Polygon</div>
                            </div>
                            <div class="chain-option selected">
                                <div style="font-size: 1.5rem;">🔵</div>
                                <div>Arbitrum</div>
                            </div>
                            <div class="chain-option selected">
                                <div style="font-size: 1.5rem;">🔴</div>
                                <div>Optimism</div>
                            </div>
                            <div class="chain-option selected">
                                <div style="font-size: 1.5rem;">🟦</div>
                                <div>Base</div>
                            </div>
                            <div class="chain-option">
                                <div style="font-size: 1.5rem;">❄️</div>
                                <div>Avalanche</div>
                            </div>
                        </div>
                        <div class="help-text">Default selection optimized for maximum reach</div>
                    </div>
                </div>
            </div>

            <!-- Step 4: Cost Preview -->
            <div class="flow-step">
                <div class="step-header">
                    <div class="step-number">4</div>
                    <div class="step-title">Cost Breakdown</div>
                </div>
                
                <div class="cost-breakdown">
                    <div class="cost-item">
                        <span>Base NFT Cost (1,000 × $0.001)</span>
                        <span id="base-cost">$1.00</span>
                    </div>
                    <div class="cost-item" id="multichain-cost" style="display:none;">
                        <span>Multi-Chain Premium (50%)</span>
                        <span>$0.50</span>
                    </div>
                    <div class="cost-item">
                        <span>Monitoring Cost (30 days × $0.01)</span>
                        <span id="monitoring-cost">$0.30</span>
                    </div>
                    <div class="cost-total">
                        <div class="cost-item">
                            <span>Total Campaign Cost</span>
                            <span id="total-cost">$1.30</span>
                        </div>
                    </div>
                </div>
                
                <div class="success-box">
                    <strong>💡 Smart Pricing:</strong> Costs scale with your campaign size. Larger campaigns get better per-NFT rates!
                </div>
            </div>

            <!-- Step 5: Launch Campaign -->
            <div class="flow-step">
                <div class="step-header">
                    <div class="step-number">5</div>
                    <div class="step-title">Launch Campaign</div>
                </div>
                
                <div class="mockup">
                    <div class="warning-box">
                        <strong>⚠️ Before You Launch:</strong>
                        <ul style="margin-top: 10px; margin-left: 20px;">
                            <li>Make sure your hashtag is unique and brandable</li>
                            <li>Your NFT image should be high-quality and appealing</li>
                            <li>Have enough ETH for the campaign cost plus gas fees</li>
                            <li>Campaign will start monitoring immediately after launch</li>
                        </ul>
                    </div>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <button class="btn" onclick="launchCampaign()">
                            🚀 Launch Campaign ($1.30)
                        </button>
                        <br><br>
                        <button class="btn btn-secondary">
                            💾 Save as Draft
                        </button>
                    </div>
                </div>
            </div>

            <!-- Step 6: Deployment Progress -->
            <div class="flow-step" id="deployment-step" style="display:none;">
                <div class="step-header">
                    <div class="step-number">6</div>
                    <div class="step-title">Deploying Your Campaign</div>
                </div>
                
                <div class="mockup">
                    <div class="progress-bar">
                        <div class="progress-fill" id="deploy-progress" style="width: 0%"></div>
                    </div>
                    
                    <div id="deployment-status">
                        <div class="status-badge status-deploying">🔄 Initializing Campaign...</div>
                    </div>
                    
                    <div id="deployment-steps" style="margin-top: 20px;">
                        <div>✅ Campaign contract deployed</div>
                        <div>⏳ Configuring NFT rewards...</div>
                        <div>⏳ Setting up multi-chain bridges...</div>
                        <div>⏳ Starting Farcaster monitoring...</div>
                        <div>⏳ Activating campaign...</div>
                    </div>
                </div>
            </div>

            <!-- Step 7: Campaign Dashboard -->
            <div class="flow-step" id="dashboard-step" style="display:none;">
                <div class="step-header">
                    <div class="step-number">7</div>
                    <div class="step-title">Campaign Dashboard</div>
                </div>
                
                <div class="mockup">
                    <div style="text-align: center; margin-bottom: 20px;">
                        <h3>#buildwithbase Campaign</h3>
                        <div class="status-badge status-active">🟢 ACTIVE</div>
                    </div>
                    
                    <div class="analytics-grid">
                        <div class="metric-card">
                            <div class="metric-value">247</div>
                            <div class="metric-label">Total Participants</div>
                        </div>
                        <div class="metric-card">
                            <div class="metric-value">89</div>
                            <div class="metric-label">NFTs Claimed</div>
                        </div>
                        <div class="metric-card">
                            <div class="metric-value">4.2k</div>
                            <div class="metric-label">Total Engagement</div>
                        </div>
                        <div class="metric-card">
                            <div class="metric-value">23</div>
                            <div class="metric-label">Days Remaining</div>
                        </div>
                    </div>
                    
                    <div style="text-align: center; margin-top: 20px;">
                        <button class="btn">📊 View Full Analytics</button>
                        <button class="btn btn-secondary">⚙️ Campaign Settings</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function switchTab(mode) {
            document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
            event.target.classList.add('active');
            
            if (mode === 'simple') {
                document.getElementById('simple-mode').style.display = 'block';
                document.getElementById('advanced-mode').style.display = 'none';
            } else {
                document.getElementById('simple-mode').style.display = 'none';
                document.getElementById('advanced-mode').style.display = 'block';
            }
        }

        function toggleMultiChain() {
            const isChecked = document.getElementById('multichain-toggle').checked;
            const chainSelection = document.getElementById('chain-selection');
            const multichainCost = document.getElementById('multichain-cost');
            
            if (isChecked) {
                chainSelection.style.display = 'block';
                multichainCost.style.display = 'flex';
            } else {
                chainSelection.style.display = 'none';
                multichainCost.style.display = 'none';
            }
            
            updateCost();
        }

        function updateCost() {
            const nftCount = parseInt(document.getElementById('nft-count-input').value) || 1000;
            const duration = parseInt(document.getElementById('duration-input').value) || 30;
            const isMultiChain = document.getElementById('multichain-toggle').checked;
            
            const baseCost = nftCount * 0.001;
            const multichainPremium = isMultiChain ? baseCost * 0.5 : 0;
            const monitoringCost = duration * 0.01;
            const totalCost = baseCost + multichainPremium + monitoringCost;
            
            document.getElementById('base-cost').textContent = `$${baseCost.toFixed(2)}`;
            document.getElementById('monitoring-cost').textContent = `$${monitoringCost.toFixed(2)}`;
            document.getElementById('total-cost').textContent = `$${totalCost.toFixed(2)}`;
            
            // Update button text
            document.querySelector('.btn').innerHTML = `🚀 Launch Campaign ($${totalCost.toFixed(2)})`;
        }

        function launchCampaign() {
            // Hide launch section, show deployment
            document.getElementById('deployment-step').style.display = 'block';
            
            // Simulate deployment progress
            let progress = 0;
            const steps = [
                "🔄 Initializing Campaign...",
                "🔄 Deploying NFT Contract...",
                "🔄 Configuring Multi-Chain...",
                "🔄 Starting Monitoring...",
                "✅ Campaign Active!"
            ];
            
            const interval = setInterval(() => {
                progress += 20;
                document.getElementById('deploy-progress').style.width = progress + '%';
                
                if (progress <= 100) {
                    const stepIndex = Math.floor(progress / 20) - 1;
                    if (stepIndex >= 0 && stepIndex < steps.length) {
                        document.getElementById('deployment-status').innerHTML = 
                            `<div class="status-badge ${progress === 100 ? 'status-active' : 'status-deploying'}">${steps[stepIndex]}</div>`;
                    }
                }
                
                if (progress >= 100) {
                    clearInterval(interval);
                    setTimeout(() => {
                        document.getElementById('dashboard-step').style.display = 'block';
                        document.getElementById('deployment-step').scrollIntoView({ behavior: 'smooth' });
                    }, 1000);
                }
            }, 1500);
        }

        // Initialize cost calculation
        document.getElementById('nft-count-input').addEventListener('input', updateCost);
        document.getElementById('duration-input').addEventListener('input', updateCost);
        
        // Initialize with default values
        updateCost();
    </script>
</body>
</html>
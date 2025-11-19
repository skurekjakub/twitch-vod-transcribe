# 4. Explanations of Processes & Concepts

## How to Access and Navigate Velodata

**Account Requirements:**
To use Velodata, users must either create an account or sign up. The presenter mentions "there's a link in the description" for this purpose, indicating access requires registration rather than being freely available.

**Interface Overview:**
Upon logging in, users are presented with five main navigation buttons that organize the platform's features into distinct sections:
1. TradFi
2. Market
3. Options
4. Futures
5. Chart

The interface supports both light and dark mode, switchable via a toggle control accessible from the main interface.

## The TradFi Section: CME Data Windows

**What TradFi Contains:**
The TradFi section is specifically designed to display CME (Chicago Mercantile Exchange) data for Bitcoin and Ethereum. It presents six separate windows, each showing different types of traditional financial market data:

1. **Bitcoin CME Futures Open Interest** - The total value of all outstanding futures contracts that haven't been settled.
2. **CME Futures Volume** - The amount of futures contracts traded within a time period.
3. **Annualized Basis** - A metric comparing futures prices to spot prices, expressed as an annual rate.
4. **Options Open Interest** - The total number of active options contracts.
5. **Options Volume** - The trading activity in options contracts.
6. **GBTC Premium** - The premium or discount at which Grayscale Bitcoin Trust shares trade relative to their underlying Bitcoin value.

**Timeframe Functionality:**
By default, all six windows display data for a one-year timeframe. Users can modify this using a timeframe selector. When changed at the global level, all six windows update simultaneously to reflect the new timeframe (e.g., changing to "3 month" applies to all charts). However, individual windows can also be adjusted independently if a user wants different timeframes for different metrics.

**Dollar vs. Coin Display:**
The data can be toggled between dollar-denominated values and coin-denominated values. The presenter explains the rationale: "as price of Bitcoin goes up it might eventually be benefit IAL to look at open interest in coins instead of dollars as it's less noisy." This addresses the problem of rising Bitcoin prices making dollar-denominated metrics appear artificially inflated when the underlying Bitcoin-denominated activity may be stable or declining.

**Chart Interaction Features:**
Each chart window includes three buttons for data export and sharing:
1. **Save Screenshot** - Downloads the chart as an image file to the user's computer.
2. **Copy to Clipboard** - Copies the chart image so it can be pasted into other applications.
3. **API Access** - Provides programmatic access to the underlying data.

## The Market Section: Real-Time Crypto Market Data

**Eight Data Windows:**
The Market section provides eight different analytical views of cryptocurrency market activity:

1. **Return Buckets** - Categorization of cryptocurrencies by their return performance.
2. **Price Changes** - Percentage price movements over selected timeframes.
3. **Open Interest Change** - How the total value of outstanding futures contracts has changed, which the presenter notes is "very useful for Traders to see what the activity actually is."
4. **OI Normalized** - Open interest data adjusted for relative comparison across different sized markets.
5. **CVD (Cumulative Volume Delta)** - The running total of buying vs. selling volume.
6. **Funding APR** - The annualized rate at which perpetual futures contract holders pay or receive funding.
7. **Heat Map** - Visual representation of market movements, typically using color intensity.
8. **Funding as a Table** - Tabular display of funding rates across cryptocurrencies.
9. **Market Volume** - Total trading volume across markets.
10. **Total Open Interest** - Aggregate open interest across all tracked cryptocurrencies.

**Default Settings and Filtering:**
By default, the Market section displays "large cap" cryptocurrencies with a "1 we" (one week) timeframe. Users can change these via a drop-down menu. The presenter demonstrates selecting "top gainers" to show the best-performing cryptocurrencies, and adjusting to "1 hour" timeframe to see extremely short-term price movements.

**Utility for Day Traders:**
The presenter emphasizes: "these settings can be very useful for day Traders because they can see top performing coins of the last 60 Minutes." This highlights the section's value for identifying short-term momentum and trading opportunities.

## The Options Section: Derivatives Market Analysis

**What the Options Section Contains:**
While the presenter doesn't provide detailed coverage (acknowledging they're "not an options Trader"), they identify several key features:

**Greeks Addition:**
Users can add "Greeks" to their options analysis. In options trading, "Greeks" are measures of risk and sensitivity:
- **Delta** - How much the option price changes relative to the underlying asset price.
- **Gamma** - The rate of change of delta.
- **Theta** - Time decay of the option's value.
- **Vega** - Sensitivity to implied volatility changes.
- **Rho** - Sensitivity to interest rate changes.

**Most Traded Options:**
The section displays the most actively traded options contracts in the last 24 hours, helping traders identify where liquidity and interest are concentrated.

**Implied Volatility (IV) Data:**
IV represents the market's expectation of future price volatility. High IV suggests the market expects large price swings, while low IV suggests expectations of stability. The presenter notes "you can see all sorts of IV meaning implied volatility data," indicating multiple views or breakdowns of this metric are available.

## The Futures Section: Individual Coin Deep-Dive Analysis

**How to Select a Cryptocurrency:**
Users can pick any available coin from a selection menu. The presenter notes these are "all binance usdt futures," meaning the data specifically tracks USDT-margined perpetual and dated futures contracts from the Binance exchange.

**Header Information Display:**
When a coin is selected, Velodata displays three key pieces of identifying information at the top:
1. **Market Cap** - The total value of all circulating coins (price × circulating supply).
2. **FDV (Fully Diluted Valuation)** - The theoretical market cap if all possible coins were in circulation (price × maximum supply).
3. **Category** - The blockchain/token classification (e.g., "layer one" for Solana, "brc20" for Bitcoin-based tokens).

**Comprehensive Data Windows:**
The Futures section provides extensive analytical views for the selected cryptocurrency:

**24 Hours Volume:** Total trading volume in the past day.

**Open Interest Snapshot by Major Exchanges:** A comparison showing which exchanges hold the most open interest for this cryptocurrency, helping traders understand where liquidity is concentrated. The presenter's example shows "most volume is done on binance" for Solana.

**Funding Rate:** The periodic payment between long and short positions in perpetual futures contracts. Positive funding means longs pay shorts (market is bullish), negative means shorts pay longs (market is bearish).

**Open Interest Price Chart:** A combined view showing both price movement and open interest levels over time, allowing traders to see if open interest is building or declining alongside price action.

**CVD (Cumulative Volume Delta):** The running total of buy volume minus sell volume, indicating whether buyers or sellers have been more aggressive.

**OI Normalized:** Open interest adjusted to enable meaningful comparison across different market sizes.

**Liquidations:** Historical data showing when and at what price levels traders were forcibly closed out of positions. High liquidation volumes often coincide with sharp price movements.

**Historical Volumes:** Long-term volume data to identify trends in trading activity.

**Average Returns by Day:** Shows which days of the week historically see the highest/lowest returns for this asset.

**Cumulative Returns:** The total return over a specified period.

**Returns by Session:** Breaks down performance by trading session (Asian, European, US). The presenter's Solana example shows: "in the last 7 Days uh Solana went up mostly during us session," revealing when geographical markets are most active for this asset.

**Price Chart (Solana Example):**
The presenter notes a specific observation: "Biggest Gainer has been around actually around this time as I'm recording right now," demonstrating that the data is real-time and can show very recent price spikes.

**Adjustability:**
Like other sections, "you can change all the settings as you want," with controls visible "above and beyond" each data window.

## The Chart Section: Advanced Technical Analysis Interface

### Watchlist Creation and Management

**Accessing the Watchlist:**
The watchlist is accessed by "dragging in here from the right to the left," suggesting a slide-out panel interface. It is described as "fully adjustable."

**Configuring Watchlist Columns:**
Clicking a settings button allows users to choose up to eight columns of data to display. The presenter demonstrates a day trader's potential configuration:
- 10-minute change
- 7-day change  
- 10-minute volume

When attempting to add more: "if I keep adding columns as you can see it will give me error maximum eight," confirming the eight-column limit.

**Sorting Functionality:**
Clicking column headers sorts the list by that metric. Example: clicking at the top of the price change column would "filter the biggest gainer from layer once in last seven days," allowing quick identification of top performers within specific categories.

**Creating Custom Watchlists:**
Process:
1. Click to create "new watch list"
2. Add coins individually (e.g., selecting Solana)
3. Save the watchlist with a custom name
4. The watchlist then displays only selected coins with chosen columns

**Integration with Other Sections:**
The presenter demonstrates that custom watchlists can be accessed throughout the platform: "if I scroll down I can now here select from top gainers I can collect my Val tutorial so I can basically utilize my personal watch list in this section as well."

**Viewing All Available Pairs:**
To see all cryptocurrencies instead of filtered lists:
1. Click settings
2. Uncheck all watchlists
3. Select "favorites only"
4. This displays all pairs listed on the platform

The presenter notes this is "handy if maybe you don't want to have any watch list you just want to have all the coins available market."

### Chart Interface Fundamentals

**Trading View Layout:**
The chart uses what the presenter calls "the classic trading view layout," referring to TradingView, a widely-used charting platform. This means users familiar with TradingView will find the interface intuitive.

**Visual Customization:**
Clicking the settings tab provides extensive visual controls:
- **Candle body colors** - The filled portion of candlestick charts
- **Wick colors** - The lines extending from candles showing high/low prices
- **Background colors** - The chart backdrop

The presenter shows their personal preference: "I personally like this color scheme."

**Switching Assets:**
To change which cryptocurrency is displayed:
- Start typing the coin name, or
- Click a selector and choose from a list

The default view is "Bitcoin usdt binance Futures."

### Adding and Configuring Orderflow Indicators

**What Orderflow Indicators Are:**
Orderflow indicators analyze the flow of buy and sell orders to provide insight into market momentum and pressure. They're particularly valuable for short-term trading as they show real-time market dynamics beyond just price and volume.

**The Presenter's Standard Indicator Set:**
The presenter provides "a list of indicators I use and in order I personally use them":

1. **Aggregated Data** - Combined data from multiple exchanges or timeframes
2. **Aggregated Liquidations** - Forced closures of positions across exchanges
3. **Open Interest** - Total outstanding futures contracts
4. **Spot Volume** - Trading volume from spot (non-derivatives) markets
5. **Volume** - Standard trading volume
6. **Funding** - Funding rate data for perpetual futures

**How to Add Indicators:**
Click on "indicators" button, which displays a list of available indicators. Users then select desired indicators from this list.

**Critical Setup: Converting Volume to CVD:**
The presenter explains an important customization process:

**Initial State:**
When first added, volume indicators display standard volume bars.

**Conversion Process:**
1. Hover over the volume indicator
2. Click "settings"  
3. Select "view"
4. Change view to "cumulative Delta"

**Result:**
"Now this is your spot cvd" (Cumulative Volume Delta from spot markets).

**What CVD Means:**
CVD tracks the running total of buy volume minus sell volume. If more buying than selling occurs, CVD trends upward; if more selling than buying, it trends downward. This reveals underlying pressure that may not be obvious from price alone.

**The Same Process for Futures CVD:**
The presenter repeats this conversion for the regular volume indicator: "I'll do the same for this one," creating both spot CVD and futures CVD indicators.

### Arranging Indicators for Optimal Display

**The Stacked Layout Technique:**
Many traders prefer overlaying multiple indicators rather than having separate panes for each. The presenter demonstrates this popular configuration:

**Process:**
1. Click the three dots on an indicator
2. Select "visual order"
3. Choose "move on existing pain above"

**Result:**
"Here we go here is the look I wanted to have" - both spot CVD and futures CVD are now overlaid on the same pane, allowing direct visual comparison.

**Adjusting Pane Order:**
Panes can be reordered using "arrows up and down" buttons.

**Cleaning Up the Interface:**
The presenter addresses visual clutter: "if I personally am pretty annoyed by these text at the left you can click at this arrow and this is much cleaner look."

This collapses indicator labels, maximizing space for the actual data display while keeping the indicators visible.

**Size Adjustments:**
Indicators are "also adjustable by size like this," allowing users to allocate more or less vertical space to different indicators based on importance.

### Advanced Indicator Settings

**Beyond Basic Configuration:**
The presenter emphasizes that customization extends far beyond initial setup: "when it comes to indicators it's not just volumes and cvds that are adjustable there's a lot of settings and functionality with within most of them."

**Example: Open Interest Configuration:**
When demonstrating open interest indicator:

**Default State:**
"As of right now it's showing me open interest in coins"

**Changing Display Format:**
1. Click on settings for the indicator
2. Switch to dollars instead of coins

**What This Teaches:**
"There's basically a lot of flexibility when it comes to pretty much all indicators available." Each indicator has multiple configuration options affecting how data is calculated, displayed, and interpreted.

### Multi-Chart Layouts

**Purpose:**
Advanced traders often need to monitor multiple cryptocurrencies simultaneously.

**How to Create Multi-Chart Layout:**
The presenter shows: "here you can have up to you can have several charts at the same time so maybe you want to have Bitcoin at left and right ethereum or any other altcoin as many as you like."

**Practical Application:**
This allows, for example:
- Monitoring Bitcoin (market leader) alongside an altcoin position
- Comparing correlated assets
- Watching multiple timeframes of the same asset
- Tracking different exchanges or contract types simultaneously

The "as many as you like" specification suggests no hard limit on chart count, though practical limits would be imposed by screen space and processing power.

## Conceptual Explanations of Technical Terms

### Open Interest
**Definition:** The total number of outstanding derivative contracts (futures or options) that have not been settled. 

**Why It Matters:** Rising open interest alongside rising price suggests new money entering positions (bullish), while declining open interest suggests position closing (potentially bearish or profit-taking). Open interest helps distinguish between genuine trend strength and mere price volatility.

### Cumulative Volume Delta (CVD)
**Definition:** A running total calculated by subtracting sell volume from buy volume for each time period and adding it to the previous cumulative total.

**Calculation Logic:** 
- If period has 100 buy volume and 70 sell volume, the delta is +30
- This +30 is added to the previous cumulative total
- The line trends up when buying dominates, down when selling dominates

**Trading Significance:** CVD reveals underlying pressure. Price can remain flat while CVD rises (accumulation) or falls (distribution), providing early signals of potential price moves. Divergences between price and CVD often precede reversals.

### Funding Rate
**Definition:** In perpetual futures contracts (futures without expiration dates), the funding rate is a periodic payment between long and short position holders to keep the futures price anchored to spot price.

**Mechanism:**
- **Positive funding:** Perpetual price > spot price → longs pay shorts → market is bullish/leveraged long
- **Negative funding:** Perpetual price < spot price → shorts pay longs → market is bearish/leveraged short

**Trading Application:** Extremely high positive funding indicates overleveraged longs (potential for liquidation cascade down). High negative funding indicates overleveraged shorts (potential for short squeeze up). Moderate funding is neutral.

### Annualized Basis
**Definition:** The difference between futures price and spot price, expressed as an annualized percentage rate.

**Formula Logic:** (Futures Price - Spot Price) / Spot Price × (365 / Days to Expiration) × 100

**Interpretation:** High positive basis (contango) indicates market expects higher future prices. Negative basis (backwardation) indicates expectation of lower future prices. Used by arbitrage traders to identify mispricings.

### Liquidations
**Definition:** The forced closure of a leveraged position when a trader's margin falls below the maintenance margin requirement.

**Why This Happens:** Traders borrow money to amplify position size (leverage). If price moves against them, losses accumulate. When losses reach a threshold, the exchange automatically closes the position to prevent the loss exceeding the trader's collateral.

**Data Significance:** Large liquidation events often mark local price extremes because:
1. Liquidations create forced buying (to close shorts) or forced selling (to close longs)
2. This adds fuel to the price move, potentially causing cascading liquidations
3. After liquidations clear, the pressure reverses, often causing sharp reversals

Liquidation heatmaps show concentration of potential liquidations at different price levels, helping traders anticipate where volatility spikes may occur.

### OI Normalized
**Definition:** Open interest adjusted relative to some baseline (such as market cap, historical average, or total supply) to enable meaningful comparison across different sized markets.

**Why Normalization Matters:** 
- Bitcoin might have $10B open interest
- A smaller altcoin might have $100M
- Raw comparison is meaningless due to market size difference
- Normalizing (e.g., OI / Market Cap) reveals which asset has more derivatives activity relative to its size
- Higher normalized OI often indicates more speculative interest

### Implied Volatility (IV)
**Definition:** The market's expectation of future price volatility, derived from options prices using pricing models (typically Black-Scholes).

**Key Concept:** Unlike historical volatility (what has happened), IV represents what options traders collectively expect will happen.

**Calculation Concept:** Options prices contain multiple inputs (strike price, time to expiration, underlying price, interest rate, volatility). Since all other inputs are known, IV is the volatility value that makes the pricing model match the observed market price.

**Trading Significance:**
- High IV → Options expensive → Market expects big moves → Good for option sellers (if you believe market overestimates future volatility)
- Low IV → Options cheap → Market expects stability → Good for option buyers (if you believe an event will increase volatility)
- IV often spikes before earnings, regulatory announcements, or known events

### Market Cap vs. FDV
**Market Cap Definition:** Price per coin × Circulating supply (coins currently available in the market).

**FDV Definition:** Price per coin × Maximum supply (total coins that will ever exist).

**Why Both Matter:**
- Market cap shows current valuation
- FDV shows potential future dilution
- Large FDV/Market Cap ratio means many tokens still to be released
- These future releases can cause selling pressure as they enter circulation
- Projects with high FDV relative to market cap are considered higher risk due to future unlock events

### Layer One vs. Other Categories
**Layer One Definition:** A base blockchain protocol that processes and finalizes transactions on its own chain (e.g., Bitcoin, Ethereum, Solana).

**Contrast with Layer 2:** Solutions built on top of Layer 1s to improve scalability (e.g., Lightning Network on Bitcoin, Polygon on Ethereum).

**Other Categories:**
- **BRC20:** Token standard on Bitcoin blockchain (similar to ERC20 on Ethereum)
- **DeFi:** Decentralized finance applications
- **NFT:** Non-fungible token projects
- **Gaming:** Blockchain gaming tokens
- **Meme:** Tokens with no fundamental value proposition, driven by community/humor

Categories help traders segment markets by sector for analysis and comparison.

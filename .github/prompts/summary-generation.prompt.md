---
description: Generate comprehensive structured summaries from TheStockGuy (financial/trading) Twitch VOD transcripts
---

# Stream Summary Generation

You are analyzing a transcript from a financial trading livestream. Generate a comprehensive, well-structured markdown summary following the template below.

**Input**: ${input:transcriptFile:Path to the transcript SRT file (e.g., transcripts/thestockguy/thestockguy-2025-10-24-trump-terminates-all-en.srt)}
**Output**: Structured markdown summary with sections, bullet points, and relevant emojis
**Save to**: summaries/${input:outputFile:Output filename (e.g., thestockguy-2025-10-24-trump-terminates-all-SUMMARY.md)}

First, read the transcript file provided by the user.

---

## Summary Template Structure

```markdown
# TheStockGuy Stream Summary - {DATE}
## "{STREAM_TITLE}" - Investment Analysis & Trading Discussion

---

## 📈 **INVESTMENT STRATEGIES & MARKET OUTLOOK**

### Long-Term Investment Philosophy
- Extract any mentions of dollar-cost averaging, buy-and-hold strategies
- Portfolio allocation philosophy (active vs passive, risk management)
- Dividend reinvestment policies
- Market timing perspectives

### Key Investment Principles Discussed
- Risk management approaches
- Position sizing strategies
- Stop loss methodologies

---

## 🚀 **ACTIVE TRADING POSITIONS & ANALYSIS**

### Primary Day Trades
**[TICKER_1] (Company Name)**
- **Entry Strategy**: Why position was taken
- **Entry Price/Details**: Specific share counts, call prices, strike prices
- **Catalyst**: News, earnings, technical setup, sector momentum
- **Risk Management**: Stop loss percentages, position sizing
- **Performance**: Intraday movement, exit strategy, gains/losses
- **Historical Context**: Previous trades on this ticker if mentioned

**[TICKER_2] (Company Name)**
[Same structure...]

### Earnings Plays
**[TICKER] - Through/Before Earnings**
- **Entry**: Position details (shares, calls, puts)
- **Catalyst**: Expected earnings impact, partnership news
- **Performance**: Actual results vs expectations
- **Exit Strategy**: When/why positions were closed
- **Post-Mortem**: Lessons learned, opportunity cost analysis

### Long-Term Holdings Update
**[TICKER]**
- **Performance**: Current gains (percentages)
- **Entry Context**: Original thesis, entry price
- **Current Action**: Any trading activity (adding, trimming)
- **Strategic Role**: Position in overall portfolio

### Sector-Specific Positions
(Group by sector if relevant: Autonomous Vehicles, Nuclear Energy, AI/Tech, etc.)

**[TICKER]**
- Key details following structure above

---

## 🤖 **SECTOR ANALYSIS & THEMATIC DISCUSSIONS**

### [Sector/Theme Name]
**Market Catalyst Analysis**
- Key developments in the sector
- Partnership ecosystems or interconnected plays
- Timing of news flow
- Market psychology driving the sector

**Key Players**
- List major companies and their roles
- Interconnections and strategic relationships

---

## 📊 **MARKET CONDITIONS & ECONOMIC DATA**

### Economic Data Releases
- CPI, jobs data, Fed announcements, etc.
- Interpretation and market impact
- Trading implications

### Overall Market Environment
- Bull/bear conditions
- Sector rotation observations
- Volatility analysis
- Volume trends

---

## 🔧 **TRADING TOOLS & METHODOLOGY**

### Information Sources
- News platforms used (Bloomberg, Discord, etc.)
- Research methodology
- How catalysts are identified

### Technical Analysis
- Chart patterns discussed
- Support/resistance levels
- Entry/exit signals

### Risk Management Framework
- Position sizing rules
- Stop loss placement strategy
- Options vs shares allocation
- Hedging approaches

---

## 💭 **PHILOSOPHICAL DISCUSSIONS & INSIGHTS**

### Investment Philosophy
- Long-term vs short-term perspectives
- Emotional discipline in trading
- Learning from mistakes

### Market Psychology
- FOMO (Fear of Missing Out) analysis
- Herd behavior observations
- Contrarian thinking

---

## 🎯 **KEY ACTIONABLE TAKEAWAYS**

1. **Top Trades**: 3-5 most significant positions with outcomes
2. **Lessons Learned**: Specific trading lessons from the session
3. **Upcoming Watchlist**: Tickers mentioned for future consideration
4. **Strategy Adjustments**: Any changes to approach based on day's events

---

## 📝 **NOTABLE QUOTES & MOMENTS**

- Direct quotes that capture key insights or humor
- Significant moments in the stream
- Community interactions that led to trading decisions

---

## ⚠️ **DISCLAIMERS & CONTEXT**

- Note that this is entertainment/educational content
- Past performance doesn't guarantee future results
- Specific positions are personal decisions, not recommendations
```

---

## Extraction Guidelines

### For Each Stock/Position Mentioned:

1. **Always capture**:
   - Ticker symbol (format: ALL CAPS)
   - Company name if mentioned
   - Entry/exit prices or price ranges
   - Position size (share count, number of calls/puts)
   - Gain/loss percentages
   - Stop loss levels

2. **Identify the catalyst**:
   - Earnings reports (before/after, beat/miss)
   - News announcements (partnerships, acquisitions, etc.)
   - Sector momentum/rotation
   - Technical setups (breakouts, support bounces)
   - Speculation/rumors

3. **Note the trading style**:
   - Day trade vs swing trade vs long-term hold
   - Shares vs options (calls/puts, strike prices, expirations)
   - Scaling in/out vs single entry/exit
   - Hedging strategies (protective puts, etc.)

4. **Track performance**:
   - Intraday movement during stream
   - Final outcomes if positions closed
   - Historical context (previous trades on same ticker)
   - Comparison to expectations

### For Market Commentary:

1. **Economic Data**:
   - What data was released (CPI, jobs, etc.)
   - Expected vs actual results
   - Market interpretation and reaction
   - Trading implications discussed

2. **Sector Themes**:
   - Identify major themes (AI, nuclear, EVs, etc.)
   - Group related stocks under theme headers
   - Note interconnections between companies
   - Track theme momentum/rotation

3. **Overall Sentiment**:
   - Bull/bear market assessment
   - Risk-on vs risk-off environment
   - Volatility observations

### For Investment Philosophy:

1. **Extract principles**:
   - Approaches to risk management
   - Position sizing methodologies
   - Long-term vs short-term allocation
   - Dividend strategies
   - Dollar-cost averaging vs lump-sum

2. **Identify lessons**:
   - Post-mortems on closed trades
   - Mistakes acknowledged
   - Strategy adjustments
   - Emotional discipline discussions

### Formatting Best Practices:

1. **Use emojis consistently**:
   - 📈 Investment strategies
   - 🚀 Active trading
   - 🤖 Sector analysis (AI/tech)
   - ⚛️ Nuclear sector
   - 📊 Market data
   - 🔧 Tools/methodology
   - 💭 Philosophy
   - 🎯 Takeaways
   - ⚠️ Disclaimers

2. **Hierarchy**:
   - `#` for main title
   - `##` for subtitle
   - `---` for section dividers
   - `###` for major sections
   - `**Bold**` for ticker symbols and key terms
   - `-` for bullet points
   - Nested bullets for sub-points

3. **Clarity**:
   - Be specific with numbers (percentages, prices, share counts)
   - Use past tense for completed actions
   - Use present tense for ongoing positions
   - Attribute quotes clearly
   - Distinguish between actual trades and watchlist items

4. **Completeness**:
   - Include ALL tickers mentioned, even briefly
   - Capture percentage moves even if approximate
   - Note failed trades and losses, not just wins
   - Include context for why positions were taken/closed

---

## Example Extraction

**From transcript**:
```
"we got uh jobey calls flying uh we got uh rivian calls up we got our kodak calls flying"
```

**Extract as**:
```markdown
### Other Positions Mentioned
- **Joby Aviation**: Calls performing well
- **Rivian**: Calls up
- **Kodak**: Calls flying
```

---

**From transcript**:
```
"cpi data we figured cpi was going to be good today because well they called 
back employees to release the data why the hell would they call back employees 
to release data if their data was going to be bad right"
```

**Extract as**:
```markdown
### CPI Data Expectations
- **Bullish Indicator**: Government calling back employees to release data suggested positive numbers
- **Market Psychology**: "Why call back employees for bad data?"
- **Implication**: Expected favorable market response
```

---

## Quality Checklist

Before finalizing the summary, ensure:

- [ ] All ticker symbols mentioned are captured
- [ ] Entry/exit prices included where mentioned
- [ ] Catalysts identified for each position
- [ ] Gain/loss percentages recorded
- [ ] Stop loss levels noted
- [ ] Sector themes properly grouped
- [ ] Economic data releases summarized
- [ ] Investment philosophy extracted
- [ ] Formatting is consistent with template
- [ ] Emojis used appropriately
- [ ] No typos in ticker symbols
- [ ] Chronological flow maintained where relevant
- [ ] Both successful and unsuccessful trades included
- [ ] Hedging strategies noted

---

## Special Cases

### Multi-Part Streams
If stream is very long (4+ hours) and needs to be split:
- Use `PART1`, `PART2` suffixes in filename
- Each part should have full context header
- Cross-reference between parts
- Final part should include overall summary

### Themed Streams
For streams focused on specific topics (earnings season, Fed meetings, etc.):
- Lead with theme-specific section
- Group all related content together
- Provide more depth on the central theme

### Low-Activity Streams
If minimal trading activity:
- Focus more on philosophy and market analysis sections
- Expand on discussions and community interactions
- Highlight forward-looking watchlist items

---

## Output File Naming

Save summary as: `{channel}-{YYYY-MM-DD}-{first-20-chars-of-title}-SUMMARY.md`

Example: `thestockguy-2025-10-24-trump-terminates-all-SUMMARY.md`

---

## Usage with GitHub Copilot

You can run this prompt file using:

1. **In Chat view**: Type `/summary-generation` and provide the transcript file path when prompted
2. **Command Palette**: Run "Chat: Run Prompt" and select this file
3. **From editor**: Open this file and click the play button

Example usage:
```
/summary-generation: transcriptFile=transcripts/thestockguy/thestockguy-2025-10-24-trump-terminates-all-en.srt outputFile=thestockguy-2025-10-24-trump-terminates-all-SUMMARY.md
```

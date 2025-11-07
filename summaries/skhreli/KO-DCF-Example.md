# Coca-Cola ($KO) - Simple DCF Model Example
**Purpose**: Illustrate "steady state" valuation for mature, predictable businesses

---

## Company Overview
- **Ticker**: $KO
- **Business**: Global beverage company with stable, predictable cash flows
- **Why Easy to Value**: Mature business with consistent margins, slow/steady growth, no dramatic product cycles

---

## Key Assumptions

### Current Financials (Simplified Example)
- **Current Free Cash Flow (FCF)**: $10,000M annually
- **Shares Outstanding**: 4,300M
- **Net Debt**: $35,000M
- **Current Stock Price**: $63 (example)

### Growth Assumptions
- **Years 1-5**: 4% annual growth (modest, steady growth)
- **Years 6-10**: 3% annual growth (slower maturity phase)
- **Terminal Growth**: 2% perpetual growth (roughly inflation rate)

### Discount Rate (WACC)
- **Cost of Equity**: 8%
- **Cost of Debt**: 4% (after tax)
- **Capital Structure**: 70% equity / 30% debt
- **WACC**: (0.70 × 8%) + (0.30 × 4%) = **6.8%**

---

## DCF Calculation

### Year-by-Year Cash Flow Projections

| Year | Growth Rate | Free Cash Flow | Discount Factor | Present Value |
|------|-------------|----------------|-----------------|---------------|
| 0    | -           | $10,000M       | -               | -             |
| 1    | 4%          | $10,400M       | 0.936           | $9,738M       |
| 2    | 4%          | $10,816M       | 0.877           | $9,486M       |
| 3    | 4%          | $11,249M       | 0.821           | $9,235M       |
| 4    | 4%          | $11,699M       | 0.769           | $8,997M       |
| 5    | 4%          | $12,167M       | 0.720           | $8,760M       |
| 6    | 3%          | $12,532M       | 0.674           | $8,447M       |
| 7    | 3%          | $12,908M       | 0.631           | $8,145M       |
| 8    | 3%          | $13,295M       | 0.591           | $7,857M       |
| 9    | 3%          | $13,694M       | 0.553           | $7,573M       |
| 10   | 3%          | $14,105M       | 0.518           | $7,306M       |

**Sum of PV (Years 1-10)**: ~$85,544M

---

### Terminal Value Calculation

**Terminal Value Formula**: FCF(Year 10) × (1 + Terminal Growth) / (WACC - Terminal Growth)

- **Year 10 FCF**: $14,105M
- **Terminal Growth**: 2%
- **Terminal FCF (Year 11)**: $14,105M × 1.02 = $14,387M

**Terminal Value** = $14,387M / (0.068 - 0.02) = $14,387M / 0.048 = **$299,729M**

**PV of Terminal Value** = $299,729M × 0.518 (Year 10 discount factor) = **$155,260M**

---

## Enterprise Value Calculation

**Enterprise Value** = PV of Explicit Period + PV of Terminal Value

**Enterprise Value** = $85,544M + $155,260M = **$240,804M**

---

## Equity Value Calculation

**Equity Value** = Enterprise Value - Net Debt

**Equity Value** = $240,804M - $35,000M = **$205,804M**

---

## Fair Value Per Share

**Fair Value Per Share** = Equity Value / Shares Outstanding

**Fair Value Per Share** = $205,804M / 4,300M = **$47.86**

---

## Valuation Summary

| Metric | Value |
|--------|-------|
| **Current Stock Price** | $63.00 (example) |
| **DCF Fair Value** | $47.86 |
| **Upside/(Downside)** | (24%) |
| **Implied P/FCF Multiple** | 27.1x (current price) |
| **DCF P/FCF Multiple** | 20.6x (fair value) |

---

## Key Insights: Why KO is "Easy" to Model

### 1. **Steady State is Clear**
- Coca-Cola has reached maturity - no expectation of 50% annual growth
- Revenue/FCF grow at predictable, GDP-like rates (2-4% annually)
- Easy to define "area under the curve" for discounting

### 2. **No Product Cycles**
- Unlike NVIDIA (V100→A100→H100→B200), Coke sells... Coke
- Product portfolio changes slowly (new flavors, acquisitions)
- No planned obsolescence creating valuation uncertainty

### 3. **Predictable Margins**
- Operating margins stable around 25-30% for decades
- No dramatic shifts in cost structure or pricing power
- Makes cash flow projections reliable

### 4. **Simple Business Model**
- Concentrate production + bottler network + marketing = profits
- No need to account for:
  - Semiconductor fabrication cycles
  - Technology disruption risk
  - Wafer supply constraints
  - Rapid competitive obsolescence

### 5. **Terminal Value Makes Sense**
- Assuming 2% perpetual growth (≈ inflation) is reasonable
- Company likely exists in similar form 50+ years from now
- Contrast with tech: Who knows if NVIDIA's GPUs matter in 2075?

---

## Contrast with NVIDIA DCF Challenges

| Factor | Coca-Cola | NVIDIA |
|--------|-----------|--------|
| **Steady State** | Clear (reached) | Unclear (rapid growth phase) |
| **Product Cycle** | Decades (same products) | 12-18 months (new architecture) |
| **Growth Rate** | 2-4% predictable | 39%→22%→17%→?? |
| **Terminal Value** | Easy to justify | Highly speculative |
| **Margin Stability** | Very stable | Depends on competition |
| **Cyclicality Risk** | Low | High (tech, business, product cycles) |
| **DCF Reliability** | High confidence | Low confidence |

---

## Sensitivity Analysis

### Fair Value Sensitivity to WACC and Terminal Growth

|                  | Terminal Growth: 1.5% | 2.0% | 2.5% |
|------------------|----------------------|------|------|
| **WACC: 6.0%**   | $54.23               | $58.91 | $64.72 |
| **WACC: 6.8%**   | $44.12               | $47.86 | $52.44 |
| **WACC: 7.5%**   | $37.45               | $40.52 | $44.18 |

**Key Takeaway**: Even with reasonable assumption ranges, KO fair value stays in narrow band ($37-$65). This is the "steady state" advantage - valuation uncertainty is much lower than growth companies.

---

## The "Area Under the Curve" Concept

As discussed in the stream, DCF is essentially calculating:

```
         Year 1   Year 2   Year 3 ... Year ∞
          │        │        │          │
FCF:     ███      ███      ███        ███
          │        │        │          │
Discount ┴────────┴────────┴──────────┴────> Time
  
Total Value = ∫ FCF(t) × e^(-r×t) dt  (continuous form)
            = Σ FCF(t) / (1+r)^t      (discrete form)
```

For **Coca-Cola**: The curve is smooth, predictable, gradually declining slope
For **NVIDIA**: The curve has spikes, uncertainty, potential cliff edges

---

## Bottom Line

**Coca-Cola is valuation textbook material because:**
1. You can confidently model 10+ years of cash flows
2. Terminal value assumptions are defensible (2% forever? Sure.)
3. No risk of confusing "cyclicality" with "permanent growth"
4. The business in 2045 probably looks similar to 2025

**NVIDIA requires "creative thinking" because:**
1. Current 40% growth won't last forever - but when does it slow?
2. Product cycles every 18 months create revenue cliffs if competition emerges
3. Terminal value: Do GPUs matter in 2050? Different problem than "Do people drink Coke?"
4. High risk of mistaking AI cycle peak for permanent elevated growth rate

---

## Exercise: Try This Yourself

1. Get KO's actual 10-K from SEC Edgar
2. Calculate historical FCF growth (last 10 years)
3. Adjust assumptions above to match reality
4. Compare your DCF value to current stock price
5. Ask: "Am I comfortable assuming Coke exists and grows at ~2% forever?"
6. Compare ease of this exercise to doing same for $NVDA

**This is why the stream emphasized knowing your industry history** - for semiconductors, you need to understand Intel's 1990s boom, 2000s decline, 2008 crash to properly model NVIDIA. For Coke? Look at last 50 years, draw relatively straight line forward.

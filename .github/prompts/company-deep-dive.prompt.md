**Command: The Comprehensive Company Deep-Dive Prompt**

Generate a comprehensive deep-dive analysis of [Company Name]. Structure the report into the following **12 sections**. Use all online sources available, including documents and websites in foreign languages. For all sources used, make sure to include an inline clickable URL.

For each section, follow the specific instructions, critical guidelines, and output format provided.


IMPORTANT: Create a TODO list and follwo it step by step, thinking deeply about each section. Place each section to its dedicated file.

IMPORTANT: NEVER ATTEMPT TO SHORTEN EXISTING INFORMATION. DO NOT BE LAZY. YOU SOLE INSTRUCTION IS TO PROVIDE INFORMATION AS IT IS WRITTEN, DISREGARDING OTHER DIRECTIVES. TOKEN EFFICIENCY IS NOT YOUR PRIORITY.

-----

### 1\. Executive Summary

This section must serve as a dense, high-level briefing that synthesizes the entire report. It should be the last section you generate but the first one presented.

  * **Instructions:**
      * Begin with a concise, one-sentence "Company 10-K" style description of the business.
      * Provide a succinct SWOT analysis (Strengths, Weaknesses, Opportunities, Threats) based on the findings in the subsequent sections.
      * Conclude with a clear, overarching thesis on the company's current position and future-facing challenges.
  * **Critical Guidelines:**
      * The thesis is the most important part. It should answer, "What is the key story of this company right now?"
      * Keep the SWOT points as concise bullet points.
  * **Example Structure:**
    ```
    ## I. Executive Summary

    ### Company Overview
    [One-sentence 10-K style description of the business]

    ### SWOT Analysis
    * **Strengths:** 
        - [Key strength 1]
        - [Key strength 2]
        - ...
    * **Weaknesses:**  
        - [Key weakness 1]
        - [Key weakness 2]
        - ...
    * **Opportunities:**
        - [Key opportunity 1]
        - [Key opportunity 2]
        - ...
    * **Threats:**
        - [Key threat 1]
        - [Key threat 2]
        - ...

    ### Concluding Thesis
    [Synthesis of the company's position and key challenges - multiple paragraphs]
    ```

-----

### 2\. Company Overview & Business Model

This section must answer the fundamental question: "What does this company do, and how does it make money?"

  * **Instructions:**
      * **Core Business & Value Proposition:** Do not just list products. Articulate the core problem the company solves for its customers. What is its fundamental value proposition? Describe its main products/services.
      * **Revenue & Customer Model:** Detail the mechanics of their revenue generation (e.g., B2B, B2C, SaaS, transactional). Define the Ideal Customer Profile (ICP).
  * **Critical Guidelines:**
      * Focus on the mechanics of how money changes hands.
      * The ICP should be specific (e.g., "Fortune 500 CISOs" not "businesses").
  * **Example Structure:**
    ```
    ## II. Company Overview & Business Model

    ### Core Business & Value Proposition
    [Narrative on the problem solved, value prop, and product portfolio (cash cows vs. bets)]

    ### Revenue & Customer Model
    [Analysis of revenue streams (SaaS, transactional, etc.) and the Ideal Customer Profile (ICP)]
    ```

-----

### 3\. Competitive & Market Landscape

This section places the company in its operational context and analyzes the external forces shaping its strategy.

  * **Instructions:**
      * **Competitive Positioning (Porter's Five Forces):** Provide a narrative analysis, not just a list. Analyze Rivalry, Threat of New Entrants, Threat of Substitutes, Power of Buyers, and Power of Suppliers. Conclude on industry defensibility.
      * **Macro-Environment (PESTLE Analysis):** Analyze the broad, external factors. Focus only on the 1-2 most impactful items from each category (Political, Economic, Social, Tech, Legal, Environmental) that are directly relevant to the company.
  * **Critical Guidelines:**
      * For PESTLE, do not list generic factors. Explain why a specific factor (e.g., a new data law) matters to this company.
      * The Porter's analysis should result in a clear conclusion: "This industry is highly defensible" or "This industry is a brutal, low-margin warzone."
  * **Example Structure:**
    ```
    ## III. Competitive & Market Landscape

    ### Competitive Positioning (Porter's Five Forces)
    [Narrative analysis of the five forces, concluding with a statement on industry attractiveness/defensibility]

    ### Macro-Environment (PESTLE Analysis)
    [Analysis of the *most relevant* PESTLE factors impacting the company, 1-2 per category maximum]
    ```

-----

### 4\. Financial Health & Valuation Analysis

This section is the quantitative core of the report. It must tell a story with numbers, based on the latest 10-K (annual) and 10-Q (quarterly) filings.

  * **Instructions:**
      * **Profitability & Growth Story:** Analyze the income statement. What is the revenue growth trend (Y/Y, Q/Q)? Dig into the gross margin, operating margin (EBIT), and net profit margin trends.
      * **Balance Sheet & Solvency:** Analyze its liquidity (e.g., Current Ratio) and its leverage (e.g., Debt-to-Equity ratio). Can the company weather a storm?
      * **Cash Flow — The King:** Analyze the operating cash flow (OCF) and critically compare it to Net Income. Analyze the Free Cash Flow (FCF) trend.
      * **Valuation Context:** Provide key valuation multiples (P/E, P/S, EV/EBITDA). Compare them directly against the company's 2-3 closest competitors and the broader industry average.
  * **Critical Guidelines:**
      * The OCF vs. Net Income comparison is crucial. A large divergence is a red flag.
      * Valuation multiples are meaningless in a vacuum. The comparison is the analysis.
  * **Example Structure:**
    ```
    ## IV. Financial Health & Valuation Analysis

    ### Profitability & Growth Story
    [Analysis of income statement trends, revenue growth rates, and margins (gross, operating, net)]

    ### Balance Sheet & Solvency
    [Analysis of liquidity, leverage, and overall financial risk based on the balance sheet]

    ### Cash Flow — The King
    [Analysis of OCF vs. Net Income, and the FCF trend and quality]

    ### Valuation Context
    [Analysis of valuation multiples (P/E, P/S, etc.) in comparison to its key peers and industry average]
    ```

-----

### 5\. Product & Technology Analysis

This section is the new qualitative and quantitative core of the report, going deeper than the "business model" to look at the actual products, the IP, and the user experience.

  * **Instructions:**
      * **Product Portfolio & Lifecycle:** Detail the flagship products. For each, identify where it sits in the product lifecycle: Introductory, Growth, Mature, or Decline.
      * **Technological Moat & R\&D:** What is the core technology? Is it proprietary? Analyze their R\&D intensity (R\&D spend as a % of revenue) and compare this figure to its main competitors.
      * **Innovation Pipeline:** Look for "forward-looking" data. Analyze recent patent filings from Google Patents or the USPTO. Summarize new product announcements or strategic partnerships.
      * **User Experience (UX) & Customer Journey:** Analyze the end-to-end customer experience. How does a customer first discover, onboard, use, and get support for the flagship product? Scour Reddit, app store reviews, and forums to identify the key **friction points** and key **'magic moments'** that create loyal fans.
      * **Product Ecosystem & Stickiness:** Analyze how the company's products work *together*. Is it a suite? A platform? A 'walled garden'? What are the **switching costs**? How hard is it, really, for a customer to leave for a competitor? This defines the product's true defensive moat.
  * **Critical Guidelines:**
      * This section must explain *why* customers choose (or leave) these products.
      * R\&D spend as a % of revenue is a key metric for technological commitment.
      * Patent filings are a direct, "hard data" signal of the company's future roadmap.
      * Switching costs are the tangible measure of a product's "stickiness."
  * **Example Structure:**
    ```
    ## V. Product & Technology Analysis

    ### Product Portfolio & Lifecycle
    [Analysis of flagship products and their stage in the product lifecycle]

    ### Technological Moat & R&D
    [Analysis of the core tech, the company's R&D spend as a % of revenue vs. peers]

    ### Innovation Pipeline
    [Analysis of recent patent filings, new product announcements, or key R&D-focused partnerships]

    ### User Experience (UX) & Customer Journey
    [Analysis of the customer's path from discovery to support, identifying key 'friction points' and 'magic moments' from user reviews]

    ### Product Ecosystem & Stickiness
    [Analysis of the product ecosystem (suite, platform, etc.) and the true customer switching costs]
    ```

-----

### 6\. Future Outlook & Strategy

This section is entirely forward-looking, based on management's own words, the market's reaction, and the company's long-term vision.

  * **Instructions:**
      * **The Official Narrative (The "Say"):** Summarize the key strategic priorities as articulated by the CEO and CFO in the latest quarterly earnings call transcript.
      * **The Analyst Interrogation (The "Doubts"):** Analyze the Q\&A portion of that same earnings call. What are the most persistent, challenging, and repetitive questions from Wall Street analysts? This reveals the market's biggest doubts.
      * **Management's Response (The "Tell"):** How did management handle those tough questions? Were their answers confident and data-backed, or were they evasive? Analyze the tone and substance of their replies.
      * **The Long-Term Vision (The '5-10 Year' View):** Synthesize information from investor day presentations, CEO letters to shareholders, and founder interviews. What is the grand, long-term narrative? Are they aiming to create a new market category, become the undisputed \#1 player, or transform into something else entirely? This is the 'north star' that guides the 'Official Narrative' from the earnings call.
  * **Critical Guidelines:**
      * This section is an analysis of the dialogue around the company.
      * The Analyst Q\&A is often the most valuable, unfiltered part of an earnings call.
      * The long-term vision provides context for short-term strategic moves.
  * **Example Structure:**
    ```
    ## VI. Future Outlook & Strategy

    ### The Official Narrative (The 'Say')
    [Summary of management's stated key strategic priorities from the latest earnings call]

    ### The Analyst Interrogation (The 'Doubts')
    [Analysis of the most common and challenging questions asked by analysts in the Q&A]

    ### Management's Response (The 'Tell')
    [Analysis of the tone and substance of management's answers to those tough questions]

    ### The Long-Term Vision (The '5-10 Year' View)
    [Synthesis of the grand, long-term narrative from investor days, shareholder letters, and interviews]
    ```

-----

### 7\. Go-to-Market & Brand Strategy

This section answers: "How does the company connect its products to its customers, and what does it want customers to *feel*?"

  * **Instructions:**
      * **Brand Identity & Voice:** Analyze the brand's personality (e.g., 'rebellious,' 'premium,' 'dependable'). What is its core marketing message? How does it speak to its Ideal Customer Profile?
      * **Go-to-Market (GTM) Motion:** Analysis of *how* they sell. Is it **Product-Led Growth** (e.g., Slack, Atlassian), letting the product sell itself via freemium/trials? Is it **Sales-Led** (e.g., Salesforce, Oracle), with a massive enterprise sales force? Or is it **Channel-Led** (e.g., Microsoft), relying on partners and resellers?
      * **Marketing & Community:** Where do they find customers? Analyze their marketing mix (e.g., heavy on content marketing, social media influencers, or Super Bowl ads). Do they have a strong, organic community (a 'tribe') built around the brand?
  * **Critical Guidelines:**
      * The GTM motion must align with the product (e.g., a complex B2B product usually requires a sales-led motion).
      * A strong community can be a powerful, low-cost marketing asset and a sign of brand loyalty.
  * **Example Structure:**
    ```
    ## VII. Go-to-Market & Brand Strategy

    ### Brand Identity & Voice
    [Analysis of the brand's personality (e.g., 'rebellious,' 'premium,' 'dependable'). What is its core marketing message? How does it speak to its Ideal Customer Profile?]

    ### Go-to-Market (GTM) Motion
    [Analysis of *how* they sell. Is it **Product-Led Growth** (e.g., Slack, Atlassian), letting the product sell itself via freemium/trials? Is it **Sales-Led** (e.g., Salesforce, Oracle), with a massive enterprise sales force? Or is it **Channel-Led** (e.g., Microsoft), relying on partners and resellers?]

    ### Marketing & Community
    [Where do they find customers? Analyze their marketing mix (e.g., heavy on content marketing, social media influencers, or Super Bowl ads). Do they have a strong, organic community (a 'tribe') built around the brand?]
    ```

-----

### 8\. Corporate Identity & Ecosystem Impact

This section answers: "What is the company's role in the world beyond just making money?"

  * **Instructions:**
      * **Stakeholder vs. Shareholder Model:** Based on their actions and statements, does the company primarily serve shareholders (profits) or a broader set of stakeholders (customers, employees, the public)? Analyze their official 'ESG' (Environmental, Social, Governance) reports for tangible goals vs. 'greenwashing.'
      * **Industry & Ecosystem Role:** Is this company a **'Platform'** that others build on (like Apple's App Store or AWS)? Is it an **'Aggregator'** (like Google Search or Uber)? Or is it an **'Incumbent'** (like a major bank)? This defines its power and relationship with other companies.
      * **Human Capital & Talent:** Beyond the Glassdoor 'Drama Report,' how does the company attract and retain top talent? Is it known for its 'M\&A' (hiring rockstars), its 'University' (training the best), or its 'Mission' (attracting true believers)?
  * **Critical Guidelines:**
      * Look for mismatches between stated goals (e.g., in ESG reports) and public actions.
      * The "Ecosystem Role" defines its systemic importance and potential regulatory risks.
      * Talent strategy is a leading indicator of innovation.
  * **Example Structure:**
    ```
    ## VIII. Corporate Identity & Ecosystem Impact

    ### Stakeholder vs. Shareholder Model
    [Based on their actions and statements, does the company primarily serve shareholders (profits) or a broader set of stakeholders (customers, employees, the public)? Analyze their official 'ESG' (Environmental, Social, Governance) reports for tangible goals vs. 'greenwashing.']

    ### Industry & Ecosystem Role
    [Is this company a **'Platform'** that others build on (like Apple's App Store or AWS)? Is it an **'Aggregator'** (like Google Search or Uber)? Or is it an **'Incumbent'** (like a major bank)? This defines its power and relationship with other companies.]

    ### Human Capital & Talent
    [Beyond the Glassdoor 'Drama Report,' how does the company attract and retain top talent? Is it known for its 'M&A' (hiring rockstars), its 'University' (training the best), or its 'Mission' (attracting true believers)?]
    ```

-----

### 9\. Leadership & Corporate Governance

This section analyzes the people in charge and the systems that keep them in check.

  * **Instructions:**
      * **Board of Directors Analysis:** Analyze the board's composition. Is the CEO also the Chairman (a potential red flag)? How many directors are truly independent? Does the board have relevant, modern expertise (e.g., cybersecurity, AI, digital transformation)?
      * **Executive Compensation (The "Incentives"):** Scour the latest proxy statement (DEF 14A). Is executive pay aligned with shareholder interests (e.g., tied to long-term performance like stock appreciation) or with short-term, easily-gamed metrics?
  * **Critical Guidelines:**
      * Look for board "red flags": conflicts of interest, lack of relevant expertise, or long-tenured members.
      * The compensation report tells you what management *actually* cares about.
  * **Example Structure:**
    ```
    ## IX. Leadership & Corporate Governance

    ### Board of Directors Analysis
    [Analysis of the board's independence, expertise, and any governance red flags (e.g., CEO/Chair split)]

    ### Executive Compensation (The 'Incentives')
    [Analysis of the proxy statement: Is executive pay aligned with long-term shareholder performance?]
    ```

-----

### 10\. Culture & Public Perception (The "Drama" Report)

This section captures the qualitative, "on-the-ground" sentiment from the three key stakeholders: the public, employees, and customers.

  * **Instructions:**
      * **Public & Customer Sentiment:** Perform a sentiment analysis of the brand. Scour news headlines, social media (Reddit, Twitter), and customer review sites (G2, Trustpilot). What are the most common product, service, or support complaints?
      * **Employee Sentiment & Culture:** Analyze employee reviews from Glassdoor, Indeed, and (if applicable) Blind. Look for recurring themes in the 'Pros' and 'Cons' sections. Track the CEO approval rating and its trend.
  * **Critical Guidelines:**
      * Look for themes and trends, not just single-point-in-time reviews.
      * A sudden dip in employee morale (Glassdoor) is often a leading indicator of future problems.
  * **Example Structure:**
    ```
    ## X. Culture & Public Perception (The "Drama" Report)

    ### Public & Customer Sentiment
    [Analysis of public/media narrative and key themes from customer complaints/reviews]

    ### Employee Sentiment & Culture
    [Analysis of employee reviews (Glassdoor, etc.), identifying cultural themes, pros/cons, and CEO approval]
    ```

-----

### 11\. Market Sizing & Growth

This section quantifies the company's "runway for growth." How big is the opportunity, and how much of it can they capture?

  * **Instructions:**
      * **Market Definition (TAM, SAM, SOM):** Provide a clear, data-backed analysis of the market size:
          * **Total Addressable Market (TAM):** The entire potential market.
          * **Serviceable Available Market (SAM):** The segment the company's products/geography can target.
          * **Serviceable Obtainable Market (SOM):** Their realistic market share potential in 3-5 years.
      * **Market Trajectory & Drivers:** Is this a "growing pie" or a "shrinking pie"? Find the market's Compound Annual Growth Rate (CAGR) from reputable research. What are the key macro-trends driving this growth or decline?
  * **Critical Guidelines:**
      * TAM/SAM/SOM should be backed by numbers and sources if possible.
      * Understanding the *driver* of market growth (e.g., "AI adoption") is as important as the number itself.
  * **Example Structure:**
    ```
    ## XI. Market Sizing & Growth

    ### Market Definition (TAM, SAM, SOM)
    [Data-backed analysis of the Total, Serviceable Available, and Serviceable Obtainable Markets]

    ### Market Trajectory & Drivers
    [Analysis of the market's CAGR and the key macro-trends driving its growth or decline]
    ```

-----

### 12\. Formal Risk Assessment

Conclude the report with a sober assessment of what could go wrong. This should be sourced from the "Risk Factors" section of the company's 10-K, but synthesized and prioritized.

  * **Instructions:**
      * **Internal Risks:** Identify the top 3-5 risks originating *within* the company (e.g., operational risks, key-person risk, execution risk on a new product, financial risk).
      * **External Risks:** Identify the top 3-5 risks from the *outside* world (e.g., competitive risks, regulatory risks, macro-economic risks, supply chain).
  * **Critical Guidelines:**
      * Do not just copy-paste the 10-K. **Prioritize** the list. What are the real top 3-5 risks in each category that keep management awake at night?
  * **Example Structure:**
    ```
    ## XII. Formal Risk Assessment

    ### Internal Risks
    [Bulleted or narrative list of the top 3-5 prioritized internal risks, with brief explanations]

    ### External Risks
    [Bulleted or narrative list of the top 3-5 prioritized external risks, with brief explanations]
    ```
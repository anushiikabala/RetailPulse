# RetailPulse — Business Recommendation Memo

**To:** VP of Operations / E-Commerce Leadership
**From:** Data Analytics Team
**Re:** Delivery Performance & Customer Retention Findings

## Summary

Analysis of ~99K orders on the platform reveals two clear, actionable opportunities: (1) late deliveries are strongly correlated with poor customer satisfaction, and (2) repeat purchase rate is very low, indicating an untapped retention opportunity.

## Key Findings

**1. Late delivery is the single biggest driver of poor reviews.**
Orders delivered late average a review score of 2.27/5, compared to 4.1–4.5/5 for on-time or early orders. This gap is far larger than any other factor we examined (payment type, order size, category).

**2. Repeat purchase rate is only 3%.**
Of ~93,000 customers, just 2,801 placed more than one order. The vast majority of revenue comes from single-purchase customers — meaning the business is heavily dependent on constant new-customer acquisition rather than retention.

**3. Revenue is concentrated in a few categories.**
Health & Beauty, Watches/Gifts, and Bed/Bath/Table together account for a disproportionate share of total revenue among 70+ categories — these are the categories most worth protecting operationally.

## Recommendations

1. **Prioritize delivery reliability over delivery speed.** Since even "on time" (not early) deliveries show lower satisfaction than early ones, consider tightening estimated delivery date accuracy rather than just promising faster shipping.
2. **Launch a post-purchase retention flow** (e.g., a targeted follow-up offer 30–60 days after a first order) — even a modest lift from 3% to 5–6% repeat rate would meaningfully increase customer lifetime value given how revenue-concentrated the customer base is.
3. **Protect top-revenue categories operationally** — ensure sellers in Health & Beauty, Watches/Gifts, and Bed/Bath/Table have the tightest delivery SLAs, since they carry outsized revenue impact.

## Methodology Note
Analysis based on SQL queries against a cleaned, validated relational database (9 source tables, referential integrity checks passed). Full technical methodology in the project README.
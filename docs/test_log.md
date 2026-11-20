# Test log

## Experiment 1 – PI tuning speed (tc)
SIMC tuning, PI + anti-windup. Heat-up 25 → 177 °C, cold mold (−3,000 W, 90 s) at 50 min.

| tc [s] | Kp [1/°C] | Ti [s] | Overshoot [°C] | Settle [s] | Mold dip [°C] | Recovery [s] |
|---|---|---|---|---|---|---|
| 30  | 0.0881 | 168 | 0.11 | 698 | 6.73  | 340  |
| 60  | 0.0514 | 288 | 0.26 | 770 | 10.29 | 603  |
| 120 | 0.0280 | 528 | 0.50 | 926 | 13.37 | 1068 |

Without anti-windup, overshoot was 102.4 / 85.7 / 56.3 °C for tc = 30 / 60 / 120.

**Observations**
- Faster tuning (smaller tc) halves the cold-mold dip and recovers about 3× faster, with overshoot below 0.5 °C in all cases.
- Without anti-windup, faster tuning makes windup worse. Anti-windup matters more than the choice of tc.
- tc = 30 is best in the ideal model, but its higher gain amplifies sensor noise. tc = 60 is kept as the default until the robustness test (Experiment 4).

Plots: `media/controller_comparison_tc30.png`, `media/controller_comparison_tc120.png`
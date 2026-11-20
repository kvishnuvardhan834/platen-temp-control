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

## Experiment 2 – PI sample time (Ts)
PI + anti-windup, gains fixed at Kp = 0.0514, Ti = 288 s (tc = 60 s). Same heat-up and cold-mold test.

| Ts [s] | Overshoot [°C] | Settle [s] | Mold dip [°C] | Recovery [s] |
|---|---|---|---|---|
| 1  | 0.26  | 770 | 10.29 | 603 |
| 2  | 0.26  | 768 | 10.34 | 602 |
| 5  | 0.28  | 760 | 10.50 | 600 |
| 10 | 0.30  | 750 | 10.78 | 590 |
| 20 | 0.35  | 740 | 11.69 | 600 |
| 30 | 0.15  | 720 | 12.10 | 570 |
| 60 | -0.00 | 840 | 15.08 | 480 |

**Observations**
- Up to Ts = 10 s the response is almost unchanged (dip +0.5 °C). The platen's time constant is about 38 min, so it barely notices a 10 s update.
- At Ts = 30–60 s the cold-mold dip grows by 18–47 % and the controller is blind for a full minute after the disturbance.
- Rule of thumb: Ts ≤ closed-loop time constant / 10 = 6 s. Ts = 1 s is used on the PLC.
- Caveat: the mold pulse is rounded to whole samples (100 s at Ts = 20, 120 s at Ts = 60), which slightly inflates those two dips.

Plot: `media/sample_time_experiment.png`
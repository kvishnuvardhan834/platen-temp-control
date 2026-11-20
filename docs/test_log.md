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
## Experiment 3 – LQR effort weight (R)
LQR + integral, Q = diag(0, 10, 1e-3). Same heat-up and cold-mold test.

| R | Overshoot [°C] | Settle [s] | Mold dip [°C] | Recovery [s] | Peak heater after mold |
|---|---|---|---|---|---|
| 10      | 0.12 | 648  | 2.10  | 94  | 100 % |
| 100     | 0.28 | 650  | 3.11  | 100 | 100 % |
| 1,000   | 0.86 | 660  | 5.54  | 274 | 100 % |
| 10,000  | 2.44 | 1005 | 9.85  | 512 | 92 %  |
| 100,000 | 5.50 | 1402 | 13.40 | 871 | 66 %  |

**Observations**
- R sets how aggressive the controller is. Going from R = 10 to 100,000 grows the cold-mold dip about 6× and recovery about 9×.
- Very large R is too timid: at R = 100,000 the heater peaks at 66 % even though the platen is 13 °C low.
- Very small R gives the smallest dip, but the state-feedback gain on the platen temperature is about 7× larger than at R = 1,000 (0.96 vs 0.13), which would amplify sensor noise on real hardware.
- LQR at R = 100 (3.1 °C dip) beats the best PI from Experiment 1 (6.7 °C at tc = 30) because it also uses the heater temperature.
- Limitation: assumes the heater temperature is measured. A real press needs an observer to estimate it from the platen sensor.

Plot: `media/lqr_weight_experiment.png`
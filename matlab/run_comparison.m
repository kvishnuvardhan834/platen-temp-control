%RUN_COMPARISON  Heat-up + cold-mold test: PI vs PI+anti-windup vs LQR.
clear; clc; close all;
p = platen_params();
fprintf('Time constants: %.1f s and %.0f s, DC gain %.0f K\n', p.tau, p.Kdc);

% --- PI tuning: SIMC rules on a first-order-plus-dead-time approximation
tau   = max(p.tau);     % dominant time constant [s]
theta = 12;             % effective dead time: heater lag + sampling + sensor [s]
tc    = 60;             % desired closed-loop time constant [s] (try 30-120)
Kp = tau / (p.Kdc*(tc + theta));
Ti = min(tau, 4*(tc + theta));
fprintf('PI gains: Kp = %.4f per degC, Ti = %.0f s\n', Kp, Ti);

% --- LQR weights (tune these in Week 3)
Q = diag([0, 10, 1e-3]);   % [heater temp, platen temp, integral]
R = 1e3;                   % cost of heater effort

[T1, U1]    = sim_pi(p, Kp, Ti, false);
[T2, U2]    = sim_pi(p, Kp, Ti, true);
[T3, U3, K] = sim_lqr(p, Q, R);
fprintf('LQR gain K = [%.4f %.4f %.5f]\n\n', K);

names = {'PI (no anti-windup)', 'PI + anti-windup', 'LQR + integral'};
M = [perf_metrics(p,T1,U1), perf_metrics(p,T2,U2), perf_metrics(p,T3,U3)];
fprintf('%-22s %10s %10s %10s %11s %8s\n', 'Controller', 'Overshoot', ...
        'Settle', 'Mold dip', 'Recovery', 'Energy');
for i = 1:3
    fprintf('%-22s %8.2f C %8.0f s %8.2f C %9.0f s %6.2f kWh\n', names{i}, ...
        M(i).overshoot_C, M(i).settle_s, M(i).dip_C, M(i).recover_s, M(i).energy_kWh);
end

% --- Plots
t = (0:p.N-1)'*p.Ts/60;   % minutes
figure('Position',[100 100 900 600]);
subplot(2,1,1);
plot(t,T1,t,T2,t,T3,'LineWidth',1.4); hold on;
yline(p.SP,'k--','Setpoint 177 \circC (350 \circF)');
xline(p.dist_start*p.Ts/60,':','Cold mold loaded');
ylabel('Platen temperature [\circC]'); legend(names,'Location','southeast'); grid on;
title('Heated press platen: heat-up and cold-mold disturbance');
subplot(2,1,2);
plot(t,100*U1,t,100*U2,t,100*U3,'LineWidth',1.2);
ylabel('Heater output [%]'); xlabel('Time [min]'); grid on; ylim([-5 105]);

if ~exist('../media','dir'), mkdir('../media'); end
saveas(gcf, '../media/controller_comparison.png');

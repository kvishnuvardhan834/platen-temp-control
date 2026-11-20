%EXPERIMENT_SAMPLE_TIME  Experiment 2: how slowly can the PLC run the PI loop?
%   Keeps the tc = 60 s PI gains fixed (as on a real PLC where you only
%   change the task time) and runs the same test at different sample times.
clear; clc; close all;

Ts_list = [1 2 5 10 20 30 60];        % PI sample times to test [s]

% PI gains tuned for Ts = 1 s (same as run_comparison with tc = 60)
p0    = platen_params();
tau   = max(p0.tau);
Kp    = tau / (p0.Kdc*(60 + 12));
Ti    = min(tau, 4*(60 + 12));
fprintf('Fixed PI gains: Kp = %.4f per degC, Ti = %.0f s\n\n', Kp, Ti);

fprintf('%8s %11s %10s %10s %11s\n', 'Ts [s]', 'Overshoot', 'Settle', 'Mold dip', 'Recovery');
figure('Position',[100 100 900 450]); hold on; grid on;
for Ts = Ts_list
    p = p0;
    p.Ts         = Ts;
    p.N          = round(5000 / Ts);           % same total time (~83 min)
    p.dist_start = round(3000 / Ts);           % mold still loaded at 50 min
    p.dist_len   = max(1, round(90 / Ts));     % still ~90 s long
    p.Ad = expm(p.A*Ts);                       % re-discretize the plant
    p.Bd = p.A \ (p.Ad - eye(2)) * p.B;

    [T, U] = sim_pi(p, Kp, Ti, true);
    m = perf_metrics(p, T, U);
    fprintf('%8d %9.2f C %8.0f s %8.2f C %9.0f s\n', Ts, ...
            m.overshoot_C, m.settle_s, m.dip_C, m.recover_s);

    t = (0:p.N-1)' * Ts / 60;
    stairs(t, T, 'LineWidth', 1.2, 'DisplayName', sprintf('Ts = %d s', Ts));
end
yline(p0.SP, 'k--', 'HandleVisibility', 'off');
xlim([45 70]);                                  % zoom on the cold-mold event
xlabel('Time [min]'); ylabel('Platen temperature [\circC]');
title('PI + anti-windup at different sample times (cold-mold event)');
legend('Location', 'southeast');

if ~exist('../media','dir'), mkdir('../media'); end
saveas(gcf, '../media/sample_time_experiment.png');

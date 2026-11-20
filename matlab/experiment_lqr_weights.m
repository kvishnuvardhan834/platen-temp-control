%EXPERIMENT_LQR_WEIGHTS  Experiment 3: effect of the LQR effort weight R.
%   Small R = cheap heater effort = aggressive control.
%   Large R = expensive heater effort = gentle control.
clear; clc; close all;

p      = platen_params();
Q      = diag([0, 10, 1e-3]);     % [heater temp, platen temp, integral]
R_list = [1e1 1e2 1e3 1e4 1e5];

fprintf('%9s %11s %10s %10s %11s %12s\n', 'R', 'Overshoot', 'Settle', ...
        'Mold dip', 'Recovery', 'Peak heater');
figure('Position',[100 100 900 450]); hold on; grid on;
t = (0:p.N-1)' * p.Ts / 60;
for R = R_list
    [T, U, K] = sim_lqr(p, Q, R);
    m = perf_metrics(p, T, U);
    peak = max(U(p.dist_start+1 : p.dist_start+300)) * 100;   % % after mold
    fprintf('%9g %9.2f C %8.0f s %8.2f C %9.0f s %10.0f %%\n', R, ...
            m.overshoot_C, m.settle_s, m.dip_C, m.recover_s, peak);
    plot(t, T, 'LineWidth', 1.3, 'DisplayName', sprintf('R = %g', R));
end
yline(p.SP, 'k--', 'HandleVisibility', 'off');
xlim([45 70]);
xlabel('Time [min]'); ylabel('Platen temperature [\circC]');
title('LQR + integral: effect of the effort weight R (cold-mold event)');
legend('Location', 'southeast');

if ~exist('../media','dir'), mkdir('../media'); end
saveas(gcf, '../media/lqr_weight_experiment.png');
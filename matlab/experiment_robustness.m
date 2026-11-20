%EXPERIMENT_ROBUSTNESS  Experiment 4: do the controllers survive a wrong model?
%   All controllers are designed on the NOMINAL platen model, then tested on
%   a plant that is different, noisy, or measured with a delay.
clear; clc; close all;
p   = platen_params();
tau = max(p.tau);

% ---- controllers (designed on the nominal model) ----
Q = diag([0 10 1e-3]);
ctl(1) = struct('name','PI tc=30',   'type','pi',  'Kp',tau/(p.Kdc*(30+12)), 'Ti',min(tau,4*(30+12)), 'K',[]);
ctl(2) = struct('name','PI tc=60',   'type','pi',  'Kp',tau/(p.Kdc*(60+12)), 'Ti',min(tau,4*(60+12)), 'K',[]);
ctl(3) = struct('name','LQR R=100',  'type','lqr', 'Kp',[], 'Ti',[], 'K',lqr_gain(p,Q,100));
ctl(4) = struct('name','LQR R=1000', 'type','lqr', 'Kp',[], 'Ti',[], 'K',lqr_gain(p,Q,1000));
nc = numel(ctl);

% ================= A: wrong plant parameters =================
cases = { 'Nominal',   1,   1,   1;
          'Cp +30%',   1.3, 1,   1;
          'Cp -30%',   0.7, 1,   1;
          'Rpa +30%',  1,   1.3, 1;
          'Rpa -30%',  1,   0.7, 1;
          'Pmax -20%', 1,   1,   0.8 };
Over = zeros(size(cases,1),nc); Dip = Over; Rec = Over;
for i = 1:size(cases,1)
    [Ad,Bd] = true_plant(p, cases{i,2}, cases{i,3}, cases{i,4});
    for j = 1:nc
        [T,U] = simulate(ctl(j), p, Ad, Bd, 0, 0);
        m = perf_metrics(p,T,U);
        Over(i,j) = m.overshoot_C; Dip(i,j) = m.dip_C; Rec(i,j) = m.recover_s;
    end
end
fprintf('=== A: wrong plant parameters (controllers NOT retuned) ===\n');
print_matrix('Cold-mold dip [C]',     cases(:,1), ctl, Dip);
print_matrix('Heat-up overshoot [C]', cases(:,1), ctl, Over);
print_matrix('Recovery [s]',          cases(:,1), ctl, Rec);

% ================= B: sensor noise =================
sigma = 0.5;                                   % thermocouple noise [C]
[Ad,Bd] = true_plant(p,1,1,1);
Chatter = zeros(1,nc);
for j = 1:nc
    [~,U] = simulate(ctl(j), p, Ad, Bd, 0, sigma);
    Chatter(j) = 100*std(U(1500:2900));        % steady-state heater jitter [%]
end
fprintf('=== B: sensor noise %.1f C (std of heater command, %%) ===\n', sigma);
print_matrix('Heater jitter [% of full power]', {'noise'}, ctl, Chatter);

% ================= C: sensor delay =================
delays = [0 10 30 60 120];                     % sensor delay [s]
Swing = zeros(numel(delays),nc); DipD = Swing;
lbl = cell(numel(delays),1);
for i = 1:numel(delays)
    lbl{i} = sprintf('delay %d s', delays(i));
    for j = 1:nc
        [T,U] = simulate(ctl(j), p, Ad, Bd, delays(i), 0);
        m = perf_metrics(p,T,U);
        DipD(i,j)  = m.dip_C;
        Swing(i,j) = max(abs(T(p.dist_start-400:p.dist_start) - p.SP));
    end
end
fprintf('=== C: sensor delay ===\n');
print_matrix('Cold-mold dip [C]', lbl, ctl, DipD);
print_matrix('Ringing before the mold [C]  (> 1 = oscillating)', lbl, ctl, Swing);

% ---- plot: delay 30 s and 60 s ----
figure('Position',[100 100 900 650]);
dl = [30 60];
for s = 1:2
    subplot(2,1,s); hold on; grid on;
    for j = 1:nc
        T = simulate(ctl(j), p, Ad, Bd, dl(s), 0);
        plot((0:p.N-1)'*p.Ts/60, T, 'LineWidth',1.3, 'DisplayName',ctl(j).name);
    end
    yline(p.SP,'k--','HandleVisibility','off');
    xlim([35 80]); ylim([145 200]);
    ylabel('Platen temperature [\circC]');
    title(sprintf('Sensor delay = %d s', dl(s)));
    if s == 1, legend('Location','northeast'); end
end
xlabel('Time [min]');
if ~exist('../media','dir'), mkdir('../media'); end
saveas(gcf, '../media/robustness_experiment.png');

% ======================= local functions =======================
function [T,U] = simulate(c, p, Ad, Bd, delay, sigma)
% c: controller. p: nominal params (design model, setpoint, test settings).
% Ad,Bd: the TRUE plant. delay [samples]; sigma = sensor noise [C].
x = [0;0]; I = 0; z = 0;
T = zeros(p.N,1); U = zeros(p.N,1);
buf = repmat(p.Ta, delay+1, 1);               % sensor delay line
if strcmp(c.type,'lqr')
    xs  = (eye(2) - p.Ad) \ p.Bd(:,1);        % nominal steady state per unit u
    uss = (p.SP - p.Ta) / xs(2);  xss = xs*uss;
end
rng(1);
for k = 1:p.N
    y   = x(2) + p.Ta;
    buf = [buf(2:end); y];
    ym  = buf(1) + sigma*randn;               % delayed, noisy measurement
    if strcmp(c.type,'pi')
        e = p.SP - ym;  raw = c.Kp*e + I;  u = min(max(raw,0),1);
        if ~((raw > 1 && e > 0) || (raw < 0 && e < 0))
            I = I + c.Kp*p.Ts/c.Ti*e;
        end
    else
        xm  = [x(1); ym - p.Ta];              % heater temp assumed measured
        raw = uss - c.K(1:2)*(xm - xss) - c.K(3)*z;
        u   = min(max(raw,0),1);
        e   = ym - p.SP;
        if ~((raw >= 1 && e < 0) || (raw <= 0 && e > 0))
            z = z + p.Ts*e;
        end
    end
    x = Ad*x + Bd*[u; disturbance(p,k)];
    T(k) = y;  U(k) = u;
end
end

function [Ad,Bd] = true_plant(p, sCp, sRpa, sP)
Cp = p.Cp*sCp;  Rpa = p.Rpa*sRpa;  Pm = p.Pmax*sP;
A = [ -1/(p.Ch*p.Rhp),  1/(p.Ch*p.Rhp);
       1/(Cp*p.Rhp),   -1/(Cp*p.Rhp) - 1/(Cp*Rpa) ];
B = [ Pm/p.Ch, 0;  0, 1/Cp ];
Ad = expm(A*p.Ts);
Bd = A \ (Ad - eye(2)) * B;
end

function K = lqr_gain(p, Q, R)
Aa = [p.Ad, zeros(2,1); 0, p.Ts, 1];
Ba = [p.Bd(:,1); 0];
S = Q;
for i = 1:20000
    Snew = Aa'*S*Aa - Aa'*S*Ba/(R + Ba'*S*Ba)*Ba'*S*Aa + Q;
    if max(abs(Snew(:) - S(:))) < 1e-10*max(1,max(abs(S(:)))), S = Snew; break; end
    S = Snew;
end
K = (R + Ba'*S*Ba) \ (Ba'*S*Aa);
end

function print_matrix(titleStr, rowLabels, ctl, M)
fprintf('\n%s\n', titleStr);
fprintf('%-13s', ''); fprintf('%13s', ctl.name); fprintf('\n');
for i = 1:size(M,1)
    fprintf('%-13s', rowLabels{i}); fprintf('%13.2f', M(i,:)); fprintf('\n');
end
fprintf('\n');
end
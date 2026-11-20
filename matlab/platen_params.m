function p = platen_params()
%PLATEN_PARAMS  Parameters and discrete model of a heated press platen.
%   Two-state thermal model (no toolboxes needed):
%     Ch*dTh/dt = Pmax*u - (Th - Tp)/Rhp            heater cartridge
%     Cp*dTp/dt = (Th - Tp)/Rhp - (Tp - Ta)/Rpa + w  steel platen
%   u = heater command 0..1 (SSR duty), w = disturbance heat [W]
%   States are temperature rises above ambient: x = [Th - Ta; Tp - Ta]

% --- Physical parameters (generic values, not company data) ---
p.Ch   = 800;     % heater thermal capacity      [J/K]
p.Cp   = 14000;   % platen thermal capacity      [J/K] (~28 kg steel)
p.Rhp  = 0.01;    % heater -> platen resistance  [K/W]
p.Rpa  = 0.155;   % platen -> ambient resistance [K/W]
p.Pmax = 4000;    % heater power at 100 %        [W]
p.Ta   = 25;      % ambient temperature          [degC]

% --- Simulation settings ---
p.Ts   = 1;       % controller sample time       [s]
p.SP   = 177;     % cure setpoint [degC] (= 350 degF)
p.N    = 5000;    % number of samples (~83 min)

% --- Disturbance: cold mold loaded onto the platen ---
p.dist_start = 3000;   % sample when the mold is loaded
p.dist_len   = 90;     % duration [samples]
p.dist_W     = -3000;  % heat pulled out of the platen [W]

% --- Continuous state-space model ---
p.A = [ -1/(p.Ch*p.Rhp),   1/(p.Ch*p.Rhp);
         1/(p.Cp*p.Rhp),  -1/(p.Cp*p.Rhp) - 1/(p.Cp*p.Rpa) ];
p.B = [ p.Pmax/p.Ch,  0;          % column 1: heater command u
        0,            1/p.Cp ];   % column 2: disturbance w [W]

% --- Exact zero-order-hold discretization (base MATLAB, no c2d) ---
p.Ad = expm(p.A*p.Ts);
p.Bd = p.A \ (p.Ad - eye(2)) * p.B;

% --- Useful numbers for the report ---
p.tau  = -1 ./ eig(p.A);       % time constants [s] (~8 s and ~2300 s)
p.Kdc  = p.Pmax * p.Rpa;       % steady-state gain [K per unit u] = 620
end

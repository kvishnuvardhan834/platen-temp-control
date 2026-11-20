(* FB_PI_AntiWindup
   Discrete PI controller with clamping anti-windup and bumpless manual mode.
   Same algorithm as matlab/sim_pi.m, so simulation and PLC results match.
   Call once every Ts seconds (e.g., every 10th scan of a 100 ms task). *)
FUNCTION_BLOCK FB_PI_AntiWindup
VAR_INPUT
    xEnable    : BOOL;            (* TRUE = control, FALSE = output 0 and reset *)
    xManual    : BOOL;            (* TRUE = manual mode *)
    rManualOut : REAL;            (* manual output 0..1 *)
    rSP        : REAL;            (* setpoint [degC] *)
    rPV        : REAL;            (* process value [degC] *)
    rKp        : REAL := 0.0486;  (* proportional gain [1/degC] *)
    rTi        : REAL := 288.0;   (* integral time [s] *)
    rTs        : REAL := 1.0;     (* sample time [s] *)
    rOutMin    : REAL := 0.0;
    rOutMax    : REAL := 1.0;
    xAntiWindup: BOOL := TRUE;    (* set FALSE to demonstrate windup *)
END_VAR
VAR_OUTPUT
    rOut       : REAL;            (* controller output 0..1 *)
    rError     : REAL;
    xSaturated : BOOL;
END_VAR
VAR
    rI         : REAL;            (* integral term *)
    rOutRaw    : REAL;
    xPushHigh  : BOOL;
    xPushLow   : BOOL;
END_VAR

IF NOT xEnable THEN
    rI := 0.0;
    rOut := 0.0;
    xSaturated := FALSE;
    RETURN;
END_IF

rError := rSP - rPV;

IF xManual THEN
    rOut := LIMIT(rOutMin, rManualOut, rOutMax);
    (* bumpless transfer: preload integral so auto starts from manual output *)
    rI := rOut - rKp * rError;
    RETURN;
END_IF

rOutRaw := rKp * rError + rI;
rOut := LIMIT(rOutMin, rOutRaw, rOutMax);

xPushHigh := (rOutRaw > rOutMax) AND (rError > 0.0);
xPushLow  := (rOutRaw < rOutMin) AND (rError < 0.0);
xSaturated := xPushHigh OR xPushLow;

IF (NOT xAntiWindup) OR (NOT xSaturated) THEN
    IF rTi > 0.0 THEN
        rI := rI + rKp * rTs / rTi * rError;
    END_IF
END_IF
END_FUNCTION_BLOCK

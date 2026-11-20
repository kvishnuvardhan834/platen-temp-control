(* PLC_PRG  -  run in a cyclic task at 100 ms.
   Heat-up, PI control every 1 s, over-temperature and sensor-fault trips,
   and a cold-mold disturbance button for testing. Values in degC (177 C = 350 F). *)
PROGRAM PLC_PRG
VAR
    (* operator / HMI *)
    xStart          : BOOL;
    xStop           : BOOL;
    xResetAlarm     : BOOL;
    xLoadColdMold   : BOOL;            (* HMI test button *)
    xManual         : BOOL;
    rManualOut      : REAL;
    rSetpoint       : REAL := 177.0;
    rHighLimit      : REAL := 190.0;   (* over-temperature trip *)

    (* state *)
    xRunning        : BOOL;
    xAlarmOverTemp  : BOOL;
    xAlarmSensor    : BOOL;
    xAtTemp         : BOOL;            (* within +/-2 C: ready to cure *)

    (* simulation *)
    xSimulate       : BOOL := TRUE;    (* FALSE = use the real sensor input *)
    rRealPV         : REAL;            (* map to the analog input card *)
    rPV             : REAL;
    rDisturbanceW   : REAL;
    fbMold          : TP;

    (* blocks *)
    fbPI            : FB_PI_AntiWindup;
    fbPlant         : FB_PlatenModel;
    fbSSR           : FB_TimeProportional;
    xHeaterOut      : BOOL;            (* map to the SSR digital output *)
    iScan           : INT;
    rDuty           : REAL;
    fbAtTemp        : TON;
END_VAR

(* ---- start / stop ---- *)
IF xStop OR xAlarmOverTemp OR xAlarmSensor THEN
    xRunning := FALSE;
ELSIF xStart THEN
    xRunning := TRUE;
END_IF

(* ---- measurement ---- *)
IF xSimulate THEN
    rPV := fbPlant.rTp;
ELSE
    rPV := rRealPV;
END_IF

(* ---- trips (latched until reset) ---- *)
IF rPV > rHighLimit THEN xAlarmOverTemp := TRUE; END_IF
IF (rPV < -20.0) OR (rPV > 400.0) THEN xAlarmSensor := TRUE; END_IF
IF xResetAlarm AND (rPV < rHighLimit - 5.0) AND (rPV > -20.0) AND (rPV < 400.0) THEN
    xAlarmOverTemp := FALSE;
    xAlarmSensor := FALSE;
END_IF

(* ---- PI controller every 10 scans = 1 s ---- *)
iScan := iScan + 1;
IF iScan >= 10 THEN
    iScan := 0;
    fbPI(xEnable := xRunning, xManual := xManual, rManualOut := rManualOut,
         rSP := rSetpoint, rPV := rPV, rTs := 1.0);
    rDuty := fbPI.rOut;
END_IF
IF NOT xRunning THEN rDuty := 0.0; END_IF

(* ---- heater output ---- *)
fbSSR(rDuty := rDuty, tCycle := T#2S);
xHeaterOut := fbSSR.xOut AND xRunning;

(* ---- at-temperature indication (stable 30 s) ---- *)
fbAtTemp(IN := xRunning AND (ABS(rSetpoint - rPV) <= 2.0), PT := T#30S);
xAtTemp := fbAtTemp.Q;

(* ---- simulated plant + cold-mold disturbance (90 s, -3000 W) ---- *)
fbMold(IN := xLoadColdMold, PT := T#90S);
IF fbMold.Q THEN rDisturbanceW := -3000.0; ELSE rDisturbanceW := 0.0; END_IF
(* the plant sees the averaged duty; use BOOL_TO_REAL(xHeaterOut) to see SSR ripple *)
fbPlant(rU := rDuty, rW := rDisturbanceW, rDt := 0.1);
END_PROGRAM

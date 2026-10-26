%% END-001: arrival at base after a cancellation pulse
run('init_USV.m');

modelo = 'USV_SAR_GNSS';
prueba = create_gnss_test_input;

prueba = prueba.setVariable('battery_initial_soc', 1);
prueba = prueba.setVariable('battery_return_soc', 0.25);

prueba = prueba.setModelParameter( ...
    'StartTime', '0', ...
    'StopTime', '600', ...
    'MaxStep', '0.1', ...
    'SignalLogging', 'on', ...
    'SignalLoggingName', 'logsout');

% Activate cancellation at 10 s.
prueba = prueba.setBlockParameter( ...
    [modelo '/Operator_Commands/Step'], 'Time', '10');
prueba = prueba.setBlockParameter( ...
    [modelo '/Operator_Commands/Step'], 'InitialValue', '0');
prueba = prueba.setBlockParameter( ...
    [modelo '/Operator_Commands/Step'], 'FinalValue', '1');

% Remove cancellation at 11 s.
prueba = prueba.setBlockParameter( ...
    [modelo '/Operator_Commands/Cancel_Release_Step'], 'Time', '11');
prueba = prueba.setBlockParameter( ...
    [modelo '/Operator_Commands/Cancel_Release_Step'], 'InitialValue', '0');
prueba = prueba.setBlockParameter( ...
    [modelo '/Operator_Commands/Cancel_Release_Step'], 'FinalValue', '1');

resultado = sim(prueba);

%% Read signals
[tEstado, estado] = leerSenal(resultado, 'mission_status');
[tFin, completada] = leerSenal(resultado, 'mission_completed');
[tLlegada, arrived] = leerSenal(resultado, 'arrived');
[tX, x] = leerSenal(resultado, 'usv_x');
[tY, y] = leerSenal(resultado, 'usv_y');
[tHome, returnHome] = leerSenal(resultado, 'return_home');
[tMotivo, motivo] = leerSenal(resultado, 'return_reason');
[~, batteryLow] = leerSenal(resultado, 'battery_low');

%% Check that the scenario was not affected by low battery
assert(~any(batteryLow), ...
    'FAIL: se activó batería baja durante el escenario.');

%% Find the first entry into Home_Reached
iBase = find(estado == 5, 1, 'first');

assert(~isempty(iBase), ...
    'FAIL: no alcanzó Home_Reached durante los 600 s.');

tBase = tEstado(iBase);

assert(any(estado == 4 & tEstado < tBase), ...
    'FAIL: no hay evidencia de regreso antes de llegar a base.');

%% Check position and arrival confirmation at that instant
xBase = interp1(tX, x, tBase, 'linear');
yBase = interp1(tY, y, tBase, 'linear');

arrivedBase = interp1( ...
    tLlegada, arrived, tBase, 'previous');

distanciaBase = hypot(xBase - home_x, yBase - home_y);

assert(isfinite(distanciaBase) ...
    && distanciaBase <= arrival_radius + 1e-6, ...
    'FAIL: Home_Reached se activó fuera del radio de la base.');

assert(arrivedBase == 1, ...
    'FAIL: Home_Reached se activó sin llegada confirmada.');

%% Check mission_completed timing and persistence
assert(completada(1) == 0, ...
    'FAIL: mission_completed comenzó activado.');

assert(all(completada(tFin < tBase - 1e-8) == 0), ...
    'FAIL: mission_completed se activó antes de Home_Reached.');

iFin = find(completada == 1, 1, 'first');

assert(~isempty(iFin), ...
    'FAIL: mission_completed no se activó.');

tCompletada = tFin(iFin);

assert(tCompletada >= tBase - 1e-8 ...
    && tCompletada <= tBase + 0.2, ...
    'FAIL: mission_completed no coincide con la llegada.');

assert(all(completada(iFin:end) == 1), ...
    'FAIL: mission_completed no permaneció activado.');

%% Check that home selection and return reason are preserved
despuesBaseHome = tHome >= tBase;
despuesBaseMotivo = tMotivo >= tBase;

assert(any(despuesBaseHome) && any(despuesBaseMotivo), ...
    'FAIL: faltan datos desde la llegada a base.');

assert(all(returnHome(despuesBaseHome) == 1), ...
    'FAIL: se desactivó la selección de la base.');

assert(all(motivo(despuesBaseMotivo) == 3), ...
    'FAIL: no se conservó el motivo de cancelación manual.');

assert(estado(end) == 5, ...
    'FAIL: el estado final no es Home_Reached.');

%% Report
fprintf('END-001 | llegada %.4f s | distancia %.6f m | PASS\n', ...
    tBase, distanciaBase);

fprintf('mission_completed se activó a %.4f s y permaneció activo.\n', ...
    tCompletada);

%% Local helper: retrieve a scalar signal and remove duplicate times
function [t, v] = leerSenal(resultado, nombre)

    senal = resultado.logsout.getElement(nombre);

    assert(~isempty(senal), ...
        'Falta la señal registrada: %s', nombre);

    t = senal.Values.Time(:);
    v = double(senal.Values.Data(:));

    assert(~isempty(t) && numel(t) == numel(v) ...
        && all(isfinite(t)) && all(isfinite(v)), ...
        'Datos vacíos o inválidos en: %s', nombre);

    [t, indices] = unique(t, 'last');
    v = v(indices);
end
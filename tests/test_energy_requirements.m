%% Verification: ENE-001 and battery-triggered SAFE-001
% Run from the folder containing the model and init_USV.m.
% Manual cancellation must be disabled.

%% 1. Load baseline parameters and configure simulation
run('init_USV.m');

simIn = create_gnss_test_input;

simIn = simIn.setVariable('battery_return_soc', 0.25);

simIn = simIn.setModelParameter( ...
    'StartTime', '0', ...
    'StopTime', '1', ...
    'SignalLogging', 'on', ...
    'SignalLoggingName', 'logsout');

%% 2. ENE-001: above, at and below the threshold
socCasos = [0.26, 0.25, 0.24];
lowEsperado = [false, true, true];
casosOK = false(size(socCasos));

for k = 1:numel(socCasos)

    pruebaInicial = simIn.setVariable( ...
        'battery_initial_soc', socCasos(k));

    resultadoInicial = sim(pruebaInicial);

    socSignal = resultadoInicial.logsout.getElement('battery_soc');
    lowSignal = resultadoInicial.logsout.getElement('battery_low');

    assert(~isempty(socSignal) && ~isempty(lowSignal), ...
        'Faltan las señales battery_soc o battery_low.');

    socMedido = double(socSignal.Values.Data(1));
    lowMedido = logical(lowSignal.Values.Data(1));

    casosOK(k) = ...
        abs(socMedido - socCasos(k)) < 1e-12 ...
        && lowMedido == lowEsperado(k);

    estado = 'FAIL';
    if casosOK(k)
        estado = 'PASS';
    end

    fprintf( ...
        'ENE-001 | SOC %.2f | esperado %d | obtenido %d | %s\n', ...
        socMedido, lowEsperado(k), lowMedido, estado);
end

assert(all(casosOK), ...
    'ENE-001: algún caso inicial no cumple el criterio.');

%% 3. ENE-001: controlled discharge through the threshold
% Capacity: 360000 J = 100 Wh.
% Constant demand: 360 W.
% SOC decreases by 0.001 per second.
% From 0.28 to 0.25: expected activation at 30 s.

pruebaDescarga = simIn.setVariable('battery_initial_soc', 0.28);
pruebaDescarga = pruebaDescarga.setVariable( ...
    'battery_capacity_J', 360000);

pruebaDescarga = pruebaDescarga.setVariable('P_aux', 360);
pruebaDescarga = pruebaDescarga.setVariable('P_thrust_max', 0);
pruebaDescarga = pruebaDescarga.setVariable('P_turn_max', 0);

pruebaDescarga = pruebaDescarga.setModelParameter( ...
    'StopTime', '40', ...
    'MaxStep', '0.1');

resultadoDescarga = sim(pruebaDescarga);

alarm = resultadoDescarga.logsout.getElement('battery_low');
status = resultadoDescarga.logsout.getElement('mission_status');
home = resultadoDescarga.logsout.getElement('return_home');
reason = resultadoDescarga.logsout.getElement('return_reason');

assert(~isempty(alarm) && ~isempty(status) ...
    && ~isempty(home) && ~isempty(reason), ...
    'Faltan señales registradas para la prueba de descarga.');

tAlarmSignal = alarm.Values.Time(:);
low = logical(alarm.Values.Data(:));

iAlarm = find(low, 1, 'first');

assert(~isempty(iAlarm), ...
    'ENE-001 FAIL: la alarma no se activó.');

tAlarm = tAlarmSignal(iAlarm);

assert(~low(1), ...
    'ENE-001 FAIL: la alarma empezó activada.');

assert(low(end), ...
    'ENE-001 FAIL: la alarma terminó desactivada.');

assert(all(~low(tAlarmSignal < 29.9)), ...
    'ENE-001 FAIL: activación anticipada.');

assert(all(low(tAlarmSignal > 30.1)), ...
    'ENE-001 FAIL: activación tardía o interrumpida.');

assert(abs(tAlarm - 30) <= 0.1, ...
    'ENE-001 FAIL: instante de activación fuera de tolerancia.');

fprintf( ...
    'ENE-001 | descarga | activación %.4f s | PASS\n', tAlarm);

%% 4. SAFE-001: return command after low-battery detection
tStatus = status.Values.Time(:);
missionStatus = double(status.Values.Data(:));

iReturn = find(missionStatus == 4, 1, 'first');

assert(~isempty(iReturn), ...
    'SAFE-001 FAIL: no entró en Returning_Home.');

tReturn = tStatus(iReturn);

assert(tReturn >= tAlarm - 1e-8 ...
    && tReturn <= tAlarm + 0.2, ...
    'SAFE-001 FAIL: regreso fuera del intervalo esperado.');

iHome = find(home.Values.Time >= tAlarm + 0.2, 1, 'first');
iReason = find(reason.Values.Time >= tAlarm + 0.2, 1, 'first');

assert(~isempty(iHome) && ~isempty(iReason), ...
    'SAFE-001 FAIL: faltan datos posteriores a la alarma.');

assert(logical(home.Values.Data(iHome)), ...
    'SAFE-001 FAIL: return_home no está activo.');

assert(double(reason.Values.Data(iReason)) == 4, ...
    'SAFE-001 FAIL: motivo de regreso incorrecto.');

fprintf( ...
    'SAFE-001 | alarma %.4f s | regreso %.4f s | PASS\n', ...
    tAlarm, tReturn);

%% 5. Summary
fprintf('\nTodas las comprobaciones de este script han pasado.\n');
fprintf('ENE-001: tres casos iniciales y descarga controlada.\n');
fprintf('SAFE-001: respuesta a batería baja en este escenario.\n');
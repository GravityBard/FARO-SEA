function simIn = create_gnss_test_input
% Prepare a controlled test on the current GNSS model.
% Call init_USV before using this function.

model = 'USV_SAR_GNSS';
simIn = Simulink.SimulationInput(model);
% Keep the target stationary in controlled battery and safety tests.
simIn = simIn.setVariable('sar_drift_factor', 0);

% Disable measurement imperfections for integration testing.
% The navigation estimator remains active.
simIn = simIn.setVariable('gnss_position_sigma', 0);
simIn = simIn.setVariable('gnss_bias_x', 0);
simIn = simIn.setVariable('gnss_bias_y', 0);
simIn = simIn.setVariable('gnss_loss_enabled', false);

% Disable both cancellation sources.
% Each test enables the command it needs.
cancelBlock = [model '/Operator_Commands/Step'];
releaseBlock = [model '/Operator_Commands/Cancel_Release_Step'];

simIn = simIn.setBlockParameter( ...
    cancelBlock, 'InitialValue', '0');
simIn = simIn.setBlockParameter( ...
    cancelBlock, 'FinalValue', '0');

simIn = simIn.setBlockParameter( ...
    releaseBlock, 'InitialValue', '0');
simIn = simIn.setBlockParameter( ...
    releaseBlock, 'FinalValue', '0');

end
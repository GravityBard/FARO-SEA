%% Configure project paths
setup_FARO;

%% FARO — USV simulation parameters
% Educational values; not validated for a real vessel.

%% Vehicle dynamics
mass_usv = 50;       % Mass [kg]
inertia_z = 20;      % Yaw moment of inertia [kg*m^2]
drag_u = 20;         % Surge damping [N*s/m]
drag_r = 10;         % Yaw damping [N*m*s/rad]

%% Speed controller
Kp_u = 80;
Ki_u = 32;

T_aw = 1;           % Anti-windup correction time [s]
K_aw = 1/(Ki_u*T_aw);

%% Heading controller
Kp_heading = 20;
Kd_heading = 30;

%% Actuator limits
F_max = 100;        % Maximum thrust magnitude [N]
M_max = 30;         % Maximum yaw moment magnitude [N*m]

%% Guidance
u_max = 3;          % Maximum reference speed [m/s]
K_distance = 0.15;  % Distance-to-speed gain [1/s]

%% Arrival confirmation
arrival_radius = 0.5;    % Arrival radius [m]
arrival_speed = 0.05;    % Relative speed threshold [m/s]
arrival_dwell_time = 3;  % Required settling time [s]

%% Base and initial conditions
home_x = 10;        % Base X coordinate [m]
home_y = -10;       % Base Y coordinate [m]

initial_x = home_x;
initial_y = home_y;
initial_heading = 0; % [rad]

%% SAR target and assistance
sar_target_x = 40;        % Initial target X coordinate [m]
sar_target_y = 35;        % Initial target Y coordinate [m]

sar_drift_factor = 0.8;     % Zero keeps the target stationary
sar_detection_range = 6; % Ideal detection radius [m]
assistance_duration = 60; % Required continuous assistance [s]

%% Search configuration
search_x_min = 20;       % [m]
search_x_max = 60;       % [m]
search_y_min = 20;       % [m]
search_y_max = 50;       % [m]

search_max_spacing = 8;  % Maximum spacing between passes [m]

% Design assumption; actual tracking performance must be assessed.
search_tracking_error_allowance = 2; % Lateral error allowance [m]

%% Search configuration validation — SEARCH-002
search_spacing_limit = validate_search_configuration( ...
    sar_detection_range, ...
    search_tracking_error_allowance, ...
    search_max_spacing);

%% Rectangular search pattern generation — SEARCH-001
waypoints = generate_search_pattern( ...
    search_x_min, search_x_max, ...
    search_y_min, search_y_max, ...
    search_max_spacing);

num_waypoints = size(waypoints, 1);

%% Environmental current
% Components in the map reference frame.
current_x = 0.2;        % Initial X current [m/s]
current_y = 0.15;       % Initial Y current [m/s]

current_change_time = 120; % Current change time [s]
current_x_after = -0.2;    % X current after the change [m/s]
current_y_after = -0.15;   % Y current after the change [m/s]

%% Simplified current estimation
current_bias_x = 0.05;      % X estimation bias [m/s]
current_bias_y = -0.03;     % Y estimation bias [m/s]
current_estimation_tau = 3; % Filter time constant [s]

%% Position integral correction
integral_activation_radius = 2; % Activation radius [m]
Ki_position = 0.01;             % Integral gain [1/s^2]
position_integral_limit = 30;   % Accumulated error limit [m*s]

%% Simplified energy model
battery_capacity_Wh = 100; % Battery capacity [Wh]
battery_capacity_J = 3600 * battery_capacity_Wh;

battery_initial_soc = 1;   % Initial state of charge [0–1]
battery_return_soc = 0.25; % Low-battery return threshold [0–1]

P_aux = 20;               % Auxiliary power [W]
P_thrust_max = 800;       % Thrust power coefficient [W]
P_turn_max = 100;         % Turning power coefficient [W]

%% GNSS measurements
gnss_sample_time = 1;      % Measurement period [s]
gnss_position_sigma = 0.2; % Noise standard deviation per axis [m]

gnss_bias_x = 0;           % X position bias [m]
gnss_bias_y = 0;           % Y position bias [m]

%% Simulated GNSS outage
gnss_loss_enabled = true;
gnss_loss_start = 150;     % Outage start time [s]
gnss_loss_end = 170;       % Outage end time [s]


%% Alpha-beta navigation estimator
nav_sample_time = 0.1;       % Estimator update period [s]
nav_alpha = 0.4;             % Position correction coefficient
nav_beta = 0.08;             % Velocity correction coefficient

nav_max_prediction_time = 2; % Maximum valid prediction age [s]

%% Configuration summary
fprintf('Search route: %d waypoints\n', num_waypoints);
fprintf('Configured maximum spacing: %.2f m\n', search_max_spacing);
fprintf('Allowed spacing limit: %.2f m\n', search_spacing_limit);

%% Simulated MOB contact outage
mob_contact_loss_enabled = false;
mob_contact_loss_start = 260; % [s]
mob_contact_loss_end = 280;   % [s]

%% MOB tracking — initial simulation settings
mob_track_sample_time = 0.1; % Estimator update period [s]
mob_track_alpha = 0.4;       % Position correction coefficient
mob_track_beta = 0.008;       % Velocity correction coefficient
mob_track_max_age = 5;      % Maximum permitted prediction age [s]
%% MOB position sensor
mob_sensor_sample_time = mob_track_sample_time; % Periodo [s].
mob_position_sigma = 0; % Desviación típica por eje [m].

%% Optional MOB drift change
% Controlled test disturbance; not a calibrated physical model.
mob_drift_change_enabled = false;
mob_drift_change_time = 240; % [s]
mob_drift_factor_after = 1.2;
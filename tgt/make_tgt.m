
function tgt = make_tgt(id, group, sign, block_type, is_debug, is_short)

exp_version = 'v1';
desc = {
    exp_version
};

disp('Generating tgt, this may take ~ 30 seconds...');
GREEN = [153 204 153];
MAGENTA = [204 153 204];
RED = [255 0 0];
WHITE = [255 255 255];
BLACK = [0 0 0];
GRAY30 = [77 77 77];
GRAY50 = [127 127 127];
GRAY70 = [179 179 179];
ONLINE_FEEDBACK = true;
ENDPOINT_FEEDBACK = false;
% number of "cycles" (all targets seen once)
if is_debug || is_short
    N_PRACTICE_REPS = 1;
    N_BASELINE1_REPS = 1;
    N_BASELINE2_REPS = 1;
    N_MANIP_TRIALS = 25; % 
    N_WASHOUT_REPS = 1;
else
    N_PRACTICE_REPS = 0;
    N_BASELINE1_REPS = 0;
    N_BASELINE2_REPS = 0;
    N_MANIP_TRIALS = 1; % 
    N_WASHOUT_REPS = 0;
end

seed = str2num(sprintf('%d,', id)); % seed using participant's id
% NB!! This is Octave-specific. MATLAB should use rng(), otherwise it defaults to an old RNG impl (see e.g. http://walkingrandomly.com/?p=2945)
rand('state', seed);

% Originally, we just did randomized assignment. Now the experimenter
% explicitly specifies
% signs = [-1 1];
% sign = signs(randi(2));

target_angles = [296 247 287 299 271 241 277 291 279 256 273 259 247 254 252 255 298 273 276 266 265 298 251 289 271 271 251 288 251 259 263 300 250 268 261 259 277 264 245 277 257 300 243 291 296 265 288 264 268 277 283 254 278 258 249 261 278 263 286 281 282 280 292 283 245 283 294 248 247 272 249 297 264 274 256 268 281 287 274 278 271 255 263 270 289 251 297 241 246 271 273 245 278 286 270 245 250 281 241 294 277 284 284 251 246 266 289 275 250 277 260 294 244 257 280 254 246 296 267 291 269 264 246 269 273 299 265 265 272 280 244 296 244 277 268 268 283 252 297 241 243 249 268 278 259 275 269 269 269 245 257 267 258 276 279 247 273 271 279 275 241 275 258 288 290 283 292 270 261 288 264 264 284 256 256 274 268 295 254 270 289 245 267 260 252 246 245 286 276 247 289 293 270 298 246 267 260 279 249 249 261 290 287 266 245 287 280 271 278 265 298 270 259 240 250 295 244 288 254 253 260 285 255 269 275 291 265 277 247 281 260 247 266 264 240 242 262 267 245 243 283 259 296 274 270 247 277 258 290 296 261 291 247 258 257 271 283 264 254 290 285 253 263 281 295 295 283 267 272 259 298 284 268 286 261 289 258 295 266 271 245 298 246 300 245 299 248 261 270 256 296 257 262 279 262 288 270 249 294 262];

% Repeat values to ensure there are 500 variables in total
repeated_target_angles = repmat(target_angles, 1, ceil(1000 / length(target_angles)));
target_angles = repeated_target_angles(1:500);




% so we'll represent each delay once per cycle
% then each target+delay combo is a total of 5*5=25 combinations (12 reps)

block_level = struct();
% sizes taken from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5505262/
% but honestly not picky
block_level.cursor = struct('size', 4, 'color', GRAY70); % mm, white cursor
block_level.ep_feedback = struct('size', 4, 'color', GRAY70); % mm, white cursor
block_level.jump_feedback = struct('size', 4, 'color', MAGENTA); % mm, white cursor
block_level.center = struct('size', 8, 'color', GRAY30, 'offset', struct('x', 0, 'y', 80));
block_level.target = struct('size', 8, 'color', GREEN, 'distance', 80);
block_level.rot_or_clamp = 'rot';
block_level.feedback_duration = 0.2; % 300 ms
block_level.max_mt = 0.6; % maximum movement time before warning
block_level.max_rt = 0.8; % max reaction time before warning
block_level.exp_info = sprintf('%s\n', desc{:});
block_level.block_type = block_type;
block_level.manipulation_angle = 0;
block_level.group = group;
block_level.seed = seed;
block_level.exp_version = exp_version;


    check_delays = false;
    delay = 0;
    extra_delay = 1;


block_level.delays = delay;
block_level.extra_delay = extra_delay;

if strcmp(block_type, "p")
    c = 1;
    for i = 1:N_PRACTICE_REPS
        tmp_angles = shuffle(target_angles);
        for j = tmp_angles
            trial_level(c).target.x = block_level.target.distance * cosd(j);
            trial_level(c).target.y = block_level.target.distance * sind(j);
            trial_level(c).delay = 0;
            trial_level(c).is_manipulated = false;
            trial_level(c).manipulation_angle = 0;
            trial_level(c).manipulation_type = manip_labels.NONE;
            trial_level(c).online_feedback = true;
            trial_level(c).endpoint_feedback = false;
            trial_level(c).label = trial_labels.PRACTICE;
            c = c + 1;
        end
    end

    tgt = struct('block', block_level, 'trial', trial_level);
    return;
    
end

if strcmp(block_type, "c")
    c = 1;
    for i = 1:N_PRACTICE_REPS
        tmp_angles = shuffle(target_angles);
        for j = tmp_angles
            trial_level(c).target.x = block_level.target.distance * cosd(j);
            trial_level(c).target.y = block_level.target.distance * sind(j);
            trial_level(c).delay = 0;
            trial_level(c).is_manipulated = true;
            trial_level(c).manipulation_angle = 0;
            trial_level(c).manipulation_type = manip_labels.CLAMP;
            trial_level(c).online_feedback = true;
            trial_level(c).endpoint_feedback = false;
            trial_level(c).label = trial_labels.PRACTICE_CLAMP;
            c = c + 1;
        end
    end

    tgt = struct('block', block_level, 'trial', trial_level);
    return;
end

c = 1; % overall counter
% generate baseline 1
for i = 1:N_BASELINE1_REPS
    tmp_angles = shuffle(target_angles);
    for j = tmp_angles
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).delay = 0;
        trial_level(c).is_manipulated = false;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.NONE;
        trial_level(c).online_feedback = false;
        trial_level(c).endpoint_feedback = false;
        trial_level(c).label = trial_labels.BASELINE_1;
        c = c + 1;
    end
end

% baseline 2
for i = 1:N_BASELINE2_REPS
    tmp_angles = shuffle(target_angles);
    for j = tmp_angles
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).delay = 0;
        trial_level(c).is_manipulated = true;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.CLAMP;
        trial_level(c).online_feedback = true;
        trial_level(c).endpoint_feedback = false;
        trial_level(c).label = trial_labels.BASELINE_2;
        c = c + 1;
    end
end

for i = 1:N_MANIP_TRIALS
    tmp_angles = shuffle(target_angles);
    for j = tmp_angles
        ABS_MANIP_ANGLE = calculateManipAngle(); % Calculate manipulation angle
        jump_angle = generateRandomNumber();
        
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).delay = 0;
        trial_level(c).is_manipulated = true;
        trial_level(c).manipulation_angle = ABS_MANIP_ANGLE;
        trial_level(c).jump_angle = jump_angle;
        trial_level(c).manipulation_type = manip_labels.ROTATION;
        trial_level(c).online_feedback = false;
        trial_level(c).endpoint_feedback = true;
        trial_level(c).label = trial_labels.PERTURBATION;
        c = c + 1;
    end
end



% washout (equivalent to baseline 1)
for i = 1:N_WASHOUT_REPS
    tmp_angles = shuffle(target_angles);
    for j = tmp_angles
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).delay = 0;
        trial_level(c).is_manipulated = false;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.NONE;
        trial_level(c).online_feedback = false;
        trial_level(c).endpoint_feedback = false;
        trial_level(c).label = trial_labels.WASHOUT;
        c = c + 1;
    end
end

tgt = struct('block', block_level, 'trial', trial_level);
disp('Done generating tgt, thanks for waiting!');

end % end function

function arr = shuffle(arr)
    arr = arr(randperm(length(arr)));
end

function arr = shuffle_2d(arr)
    arr = arr(randperm(size(arr, 1)), :);
end

function out = pairs(a1, a2)
    [p, q] = meshgrid(a1, a2);
    out = [p(:) q(:)];
end

function out = is_unique(arr)
    out = length(arr) == length(unique(arr));
end

% Define the function
function ABS_MANIP_ANGLE = calculateManipAngle()
    random_number = rand();
    
    if random_number < 0.5
        ABS_MANIP_ANGLE = 0; % 50% chance for 0
    else
        random_number = rand();
        switch randi(2)
            case 1
                ABS_MANIP_ANGLE = -4; % 25% chance for -4
            case otherwise
                ABS_MANIP_ANGLE = 4; % 25% chance for 4
        end
    end
end

function rnd_num = generateRandomNumber()
    random_number = rand();
    
    if random_number < 0.5
        rnd_num = -1; % 50% chance for -1
    else
        rnd_num = 1; % 50% chance for +1
    end
end

function target_angle = generateTargetAngle()
    % Generate a random number between 0 and 59
    random_index = randi(60) - 1; % Subtract 1 to align with 0-based indexing
    
    % Calculate the target angle within the specified range (240 to 300)
    angle_range = 300 - 240 + 1; % 300 - 240 = 60, but inclusive, so add 1
    target_angle = mod(240 + random_index, angle_range) + 240;
end




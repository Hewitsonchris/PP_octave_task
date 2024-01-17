
% any reason to use handle? we're never passing this anywhere...
classdef StateMachine < handle

    properties
        trial_start_time = 9e99
    end

    properties (Access = private)
        state = states.RETURN_TO_CENTER
        is_transitioning = true
        w % window struct (read-only)
        tgt % target table
        un % unit handler
        audio % audio handler
        keys
        feedback_text
        trial_summary_data % summary data per-trial (e.g. RT, est reach angle,...)
        trial_count = 1
        within_trial_frame_count = 1
        % we can shuffle "local" data here
        % targets and the like have sizes set by tgt file
        % x, y are expected to be in px
        cursor = struct('x', 0, 'y', 0, 'vis', false);
        target = struct('x', 0, 'y', 0, 'vis', false);
        ep_feedback = struct('x', 0, 'y', 0, 'vis', false);
        jump_feedback = struct('x', 0, 'y', 0, 'vis', false);
        center = struct('x', 0, 'y', 0, 'vis', false);
        last_event = struct('x', 0, 'y', 0);
        slow_txt_vis = false;
        fb_txt_vis = false;
        hold_time = 0
        vis_time = 0
        targ_dist_px = 0
        feedback_dur = 0
        post_dur = 0
        target_on_time = 0
        coarse_rt = 0
        coarse_mv_start = 0
        coarse_mt = 0
        debounce = true
        too_slow = 0
        _nan_pool
        starting_pos
        delayed_pos
        summary_data
        logged_key_press
        reaction_time
        judge_start_time
        too_slow_display_time
        too_slow_displayed
        display_time
        tooSlowCounter = 0
    end

    methods

        function sm = StateMachine(path, tgt, win_info, unit)
            sm.w = win_info;
            sm.tgt = tgt;
            sm.un = unit;
            sm.audio = AudioManager();
            sm.audio.add(fullfile(path, 'media', 'speed_up.wav'), 'speed_up');
            max_nans = ceil(1/sm.w.ifi * 5); % max 2 sec delay
            sm._nan_pool = nan(max_nans, 2);
            sm.keys = ArrowKeys();
        end

        function update(sm, evts, last_vbl)

        
            global theta
            sm.within_trial_frame_count = sm.within_trial_frame_count + 1;
            w = sm.w;
            tgt = sm.tgt;
            trial = tgt.trial(sm.trial_count);

            if ~isempty(evts) % non-empty event
                sm.cursor.x = evts(end).x;
                sm.cursor.y = evts(end).y;
                sm.last_event.x = sm.cursor.x;
                sm.last_event.y = sm.cursor.y;
            else
                sm.cursor.x = sm.last_event.x;
                sm.cursor.y = sm.last_event.y;
            end

            est_next_vbl = last_vbl + w.ifi;

            if sm.state == states.RETURN_TO_CENTER
                if sm.entering()
                fprintf('Entering RETURN_TO_CENTER state\n');
                fprintf('Trial count before transition: %d\n', sm.trial_count);


                    % set the state you want, not the one you expect
                    sm.cursor.vis = true;
                    sm.center.vis = true;
                    sm.ep_feedback.vis = false;

                    sm.center.x = w.center(1) + sm.un.x_mm2px(tgt.block.center.offset.x);
                    sm.center.y = w.center(2) + sm.un.y_mm2px(tgt.block.center.offset.y);
                    t = trial.target;
                    sm.target.x = sm.un.x_mm2px(t.x) + sm.center.x;
                    sm.target.y = sm.un.y_mm2px(t.y) + sm.center.y;
                    sm.target.vis = true;
                    sm.hold_time = est_next_vbl + 0.2;
                    sm.vis_time = est_next_vbl + 0.5;
                    sm.trial_start_time = est_next_vbl;
                    sm.debounce = true;
                    sm.too_slow = 0;
                    fprintf('Setting too_slow flag to 0 in RETURN_TO_CENTER\n');
                end
                % stuff that runs every frame
                if point_in_circle([sm.cursor.x sm.cursor.y], [sm.center.x sm.center.y], ...
                                   sm.un.x_mm2px(tgt.block.target.distance * 0.25))
                    sm.cursor.vis = true;
                else
                    sm.cursor.vis = true;
                end
                % transition conditions
                if point_in_circle([sm.cursor.x sm.cursor.y], [sm.center.x sm.center.y], ...
                                   sm.un.x_mm2px(tgt.block.center.size - tgt.block.cursor.size) * 0.5)
                    if ~sm.debounce && est_next_vbl >= sm.hold_time
                        sm.state = states.REACH;

                    end
                else
                    sm.hold_time = est_next_vbl + 0.2; % 200 ms in the future
                    sm.debounce = false;
                end
            end

            if sm.state == states.REACH
                if sm.entering()
                    sm.target.vis = false;
                    t = trial.target;
                    sm.target.x = sm.un.x_mm2px(t.x) + sm.center.x;
                    sm.target.y = sm.un.y_mm2px(t.y) + sm.center.y;
                    sm.target_on_time = est_next_vbl;
                    sm.coarse_rt = 0;
                    sm.coarse_mv_start = 0;
                    sm.coarse_mt = 0;
                    sm.targ_dist_px = distance(sm.target.x, sm.center.x, sm.target.y, sm.center.y);
                    sm.cursor.vis = trial.online_feedback;
                    sm.starting_pos = sm.cursor;
                    if trial.delay > 0
                        % initialize a FIFO with max length corresponding to specified delay
                        % given seconds, how many frames?
                        sz = floor(1/w.ifi * trial.delay);
                        sm.delayed_pos = sm._nan_pool(1:sz, :);
                    end
                end

                if trial.delay > 0
                    % NB: this is also not robust to frame drops. Should we do timestamp-based instead?
                    sm.delayed_pos(1:end-1, :) = sm.delayed_pos(2:end, :);
                    sm.delayed_pos(end, 1) = sm.cursor.x;
                    sm.delayed_pos(end, 2) = sm.cursor.y;
                    if ~isnan(sm.delayed_pos(1, 1))
                        sm.cursor.x = sm.delayed_pos(1, 1);
                        sm.cursor.y = sm.delayed_pos(1, 2);
                    else
                        % lock in place if we haven't moved yet
                        sm.cursor.x = sm.starting_pos.x;
                        sm.cursor.y = sm.starting_pos.y;
                    end

                end

                cur_dist = distance(sm.cursor.x, sm.center.x, sm.cursor.y, sm.center.y);

                if trial.online_feedback
                    cur_theta = atan2(sm.cursor.y - sm.center.y, sm.cursor.x - sm.center.x);

                    if trial.is_manipulated
                        %TODO: implement rotation
                        % get angle of target in deg, add clamp offset, then to rad
                        target_angle = atan2d(sm.target.y - sm.center.y, sm.target.x - sm.center.x);
                        theta = cur_theta + deg2rad(trial.manipulation_angle);
                    else
                        theta = cur_theta;
                    end
                    sm.cursor.x = cur_dist * cos(theta) + sm.center.x;
                    sm.cursor.y = cur_dist * sin(theta) + sm.center.y;
                end

                if ~sm.coarse_rt && cur_dist >= sm.un.x_mm2px(tgt.block.center.size * 0.5)

                    sm.coarse_rt = est_next_vbl - sm.target_on_time;
                    sm.coarse_mv_start = est_next_vbl;
                    % add trial delay here, so that they're not penalized by lagged cursor
                    if sm.coarse_rt > (tgt.block.max_rt + trial.delay)
                        sm.state = states.BAD_MOVEMENT;
                    end
                end
                if cur_dist >= sm.targ_dist_px
                    % same goes for MT-- do analysis on something thoughtful
                    sm.coarse_mt = est_next_vbl - sm.coarse_mv_start;
                    if sm.coarse_mt > tgt.block.max_mt
                        sm.state = states.BAD_MOVEMENT;
                    else
                        sm.state = states.DIST_EXCEEDED;
                    end
                end

                if (est_next_vbl - sm.target_on_time) > tgt.block.max_rt
                    sm.state = states.BAD_MOVEMENT;
                end
            end

            if sm.state == states.DIST_EXCEEDED
                if sm.entering()
                    sm.cursor.vis = false;
                    if trial.endpoint_feedback
                        sm.ep_feedback.vis = true;
                        cur_theta = atan2(sm.cursor.y - sm.center.y, sm.cursor.x - sm.center.x);
                        if trial.is_manipulated
                            % get angle of target in deg, add clamp offset, then to rad
                            target_angle = atan2d(sm.target.y - sm.center.y, sm.target.x - sm.center.x);
                            theta = cur_theta + deg2rad(trial.manipulation_angle);
 			                disp(rad2deg(theta));
                        else
                            theta = cur_theta;
                        end
                        % use earlier sm.targ_dist_px for extent
                        sm.ep_feedback.x = sm.targ_dist_px * cos(theta) + sm.center.x;
                        sm.ep_feedback.y = sm.targ_dist_px * sin(theta) + sm.center.y;
                    end
                end
                % transition to Feedback state
                sm.state = states.FEEDBACK;
            end

            if sm.state == states.BAD_MOVEMENT
                if sm.entering()
                    sm.cursor.vis = false;
                    sm.ep_feedback.vis = false;
                    sm.target.vis = false;
                    sm.center.vis = false;
                    sm.slow_txt_vis = true;
                    sm.too_slow = 1;

                     % Increment the tooSlowCounter
                     sm.tooSlowCounter = sm.tooSlowCounter + 1;
                        fprintf('Too Slow Counter: %d\n', sm.tooSlowCounter);

                end
                sm.state = states.FEEDBACK; % Directly transition to RETURN_TO_CENTER
            end

            

	    jump_theta = theta; % Initialize jump_theta outside the block

        if sm.state == states.FEEDBACK
            if sm.entering()
            % Initialization code
            sm.feedback_dur = tgt.block.feedback_duration + est_next_vbl; % feedback duration (200ms) plus frame time, to set timer
            sm.post_dur = sm.feedback_dur + tgt.block.extra_delay;
            jump_theta = theta + deg2rad(trial.jump_angle);
		    disp(rad2deg(theta));
		    disp(trial.jump_angle);
		    rad2deg(jump_theta)
		    sm.jump_feedback.x = sm.targ_dist_px * cos(jump_theta) + sm.center.x;
		    sm.jump_feedback.y = sm.targ_dist_px * sin(jump_theta) + sm.center.y;
            end

            % EP feedback duration (200ms), then EP feedback turns off
            if est_next_vbl >= sm.feedback_dur
                if sm.too_slow
                sm.ep_feedback.vis = false;
                sm.target.vis = false;
                sm.state = states.JUDGE;
                else
                sm.ep_feedback.vis = false;
                sm.target.vis = false;
                sm.slow_txt_vis = false;
                end
            end
        

		% Display jump_feedback at jump_theta if trial.is_manipulated extra_delay time (1 second) after EP feedback dissapears 
		if trial.is_manipulated && est_next_vbl >= (sm.feedback_dur + tgt.block.extra_delay) % jump feedback is visible 1 second after EP feedback is removed
		    sm.ep_feedback.vis = false;
		    sm.jump_feedback.vis = true;
		end
	    
	    % Jump feedback duration is block duration (same as EP feedback duration - 200ms)
	    if est_next_vbl >= sm.post_dur + tgt.block.feedback_duration %(200ms after Jump feedback is turned on)
	        sm.jump_feedback.vis = false;
		    sm.state = states.JUDGE;
	    end
        
	end

	
if sm.state == states.JUDGE
    if sm.entering()
        sm.feedback_text = ''; % Initialize text to be displayed
        sm.keys.flush();
        sm.logged_key_press = ''; % Initialize variable to store logged key press
        sm.judge_start_time = est_next_vbl; % Record the start time for reaction time
        sm.display_time = 0; % Reset display timer
        sm.reaction_time = 0; % Reset reaction time
    end

    if sm.too_slow
    sm.slow_txt_vis = false;
    pause(0.5);
    sm.state = states.TRANSITION
   
   else
    % Log keyboard button press (only once per state)
    key_state = sm.keys.update();
    
    if est_next_vbl - sm.judge_start_time <= 2
        if key_state.Left || key_state.Right
            if key_state.Left
                sm.feedback_text = 'left'; % Display "left" on the screen
                sm.logged_key_press = 'left'; % Log the key press
            else
                sm.feedback_text = 'right'; % Display "right" on the screen
                sm.logged_key_press = 'right'; % Log the key press
            end
            
            sm.display_time = est_next_vbl + 1; % Display for 1 second
            sm.reaction_time = est_next_vbl - sm.judge_start_time; % Calculate reaction time
        end
    else
        if isempty(sm.logged_key_press)
            sm.feedback_text = 'too slow';
            sm.logged_key_press = 'no response'; % Log 'no response'
            sm.display_time = est_next_vbl + 1; % Display 'too slow' for 1 second
            sm.reaction_time = est_next_vbl - sm.judge_start_time; % Calculate reaction time
            sm.too_slow = 1;

            % Increment the tooSlowCounter
            sm.tooSlowCounter = sm.tooSlowCounter + 1;
            fprintf('Too Slow Counter: %d\n', sm.tooSlowCounter);
        end
    end
    
    % Display text and transition to states.TRANSITION
    DrawFormattedText(w.w, sm.feedback_text, 'center', 0.4 * w.rect(4), [222, 75, 75]);
    if est_next_vbl >= sm.display_time && sm.display_time ~= 0 % Check if display time is set and reached
        sm.state = states.TRANSITION; % Transition to states.TRANSITION
    end
    end
end

	
	if sm.state == states.TRANSITION
    		if sm.entering()
            if (sm.trial_count + 1) > (length(tgt.trial) + sm.tooSlowCounter)
            		sm.state = states.END;
        	else
		    sm.trial_count = sm.trial_count + 1;
		    sm.within_trial_frame_count = 1;
            sm.state = states.RETURN_TO_CENTER;
        	end
    	    end
       end

end

        function draw(sm)
            % drawing; keep order in mind?
            MAX_NUM_CIRCLES = 4; % max 4 circles ever
            xys = zeros(2, MAX_NUM_CIRCLES);
            sizes = zeros(1, MAX_NUM_CIRCLES);
            colors = zeros(3, MAX_NUM_CIRCLES, 'uint8'); % rgb255
            counter = 1;
            blk = sm.tgt.block;
            w = sm.w;
            % TODO: stick with integer versions of CenterRectOnPoint*?
            if sm.target.vis
                xys(:, counter) = [sm.target.x sm.target.y];
                sizes(counter) = sm.un.x_mm2px(blk.target.size);
                if sm.state == states.FEEDBACK
                    colors(:, counter) = 127; %TODO: don't do this, set it from elsewhere
                else
                    colors(:, counter) = blk.target.color;
                end
                counter = counter + 1;
            end

            if sm.center.vis
                xys(:, counter) = [sm.center.x sm.center.y];
                sizes(counter) = sm.un.x_mm2px(blk.center.size);
                colors(:, counter) = blk.center.color;
                counter = counter + 1;
            end

            if sm.ep_feedback.vis
                xys(:, counter) = [sm.ep_feedback.x sm.ep_feedback.y];
                sizes(counter) = sm.un.x_mm2px(blk.ep_feedback.size);
                colors(:, counter) = blk.ep_feedback.color;
                counter = counter + 1;
            end

            if sm.jump_feedback.vis
                xys(:, counter) = [sm.jump_feedback.x sm.jump_feedback.y];
                sizes(counter) = sm.un.x_mm2px(blk.jump_feedback.size);
                colors(:, counter) = blk.jump_feedback.color;
                counter = counter + 1;
            end

            if sm.cursor.vis
                xys(:, counter) = [sm.cursor.x sm.cursor.y];
                sizes(counter) = sm.un.x_mm2px(blk.cursor.size);
                colors(:, counter) = blk.cursor.color;
                counter = counter + 1;
            end

            if sm.slow_txt_vis
                DrawFormattedText(w.w, 'Please reach sooner and/or faster.', 'center', 0.4 * w.rect(4), [222, 75, 75]);
            end
            if sm.fb_txt_vis
            DrawFormattedText(w.w,  sm.feedback_text, 'center', 0.4 * w.rect(4), [222, 75, 75]);
            end
            % draw all circles together; never any huge circles, so we only need nice-looking up to a point
            %Screen('FillOval', w.w, colors, rects, floor(w.rect(4) * 0.25));
            Screen('DrawDots', w.w, xys(:, 1:counter), sizes(1:counter), colors(:, 1:counter), [], 3, 1);
            % draw trial counter in corner
            Screen('DrawText', w.w, sprintf('%i/%i', sm.trial_count, (length(sm.tgt.trial) + sm.tooSlowCounter)), 10, 10, 128);
        end

        function state = get_state(sm)
            state = sm.state;
        end

        function [tc, wtc] = get_counters(sm)
            tc = sm.trial_count;
            wtc = sm.within_trial_frame_count;
        end

        function val = will_be_new_trial(sm)
            % should we subset?
            val = sm.is_transitioning && (sm.state == states.RETURN_TO_CENTER || sm.state == states.END);
        end

        % compute where cursor & target are in mm relative to center (which is assumed to be fixed)
        function cur = get_cursor_state(sm)
            cur = sm.center_and_mm(sm.cursor, sm.center);
        end

        function tar = get_target_state(sm)
            tar = sm.center_and_mm(sm.target, sm.center);
        end

        function ep = get_ep_state(sm)
            ep = sm.center_and_mm(sm.ep_feedback, sm.center);
        end

        function center = get_raw_center_state(sm)
            center = sm.center;
        end

        function restart_trial(sm)
            % restart the current trial
            sm.state = states.RETURN_TO_CENTER;
            sm.within_trial_frame_count = 1;
            sm.trial_start_time = 9e99; % single-frame escape hatch
        end

        function val = was_too_slow(sm)
            val = sm.too_slow;
        end
    end

    methods (Access = private)
        function ret = entering(sm)
            ret = sm.is_transitioning;
            sm.is_transitioning = false;
        end

        % Octave buglet? can set state here even though method access is private
        % but fixed by restricting property access, so not an issue for me
        function state = set.state(sm, value)
            sm.is_transitioning = true; % assume we always mean to call transition stuff when calling this
            sm.state = value;
        end

        function v1 = center_and_mm(sm, v1, v2)
            v1.x = sm.un.x_px2mm(v1.x - v2.x);
            v1.y = sm.un.y_px2mm(v1.y - v2.y);
        end
    end
end

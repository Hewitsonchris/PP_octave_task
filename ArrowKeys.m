% container for keyboard state

classdef ArrowKeys < handle

    properties
        state
        mapping
        rt = 0
    end

    methods

        function kb = ArrowKeys()
            kb.state = struct('Up', 0, 'Right', 0, 'Left', 0, 'Down', 0, 'Return', 0);
            arrow_keys = [81, 86, 84, 89, 105]; % enter, up, left, right, down respectively
            arrow_keys = [85, 90, 88, 89, 105];
            kb.mapping = containers.Map(arrow_keys, {'Up', 'Right', 'Left', 'Down', 'Return'});
            keylist = zeros(256, 1);
            keylist(arrow_keys) = 1;
            PsychHID('KbQueueCreate', -1, keylist);
            PsychHID('KbQueueStart', -1);
        end

        function flush(kb)
            PsychHID('KbQueueFlush', -1, 1);
            kb.state.Up = 0;
            kb.state.Right = 0;
            kb.state.Left = 0;
            kb.state.Down = 0;
            kb.state.Return = 0;
            kb.rt = 0;
        end

        function state = update(kb)
            [~, fp, fr] = PsychHID('KbQueueCheck', -1);
            for val = find(fp)
                kb.state.(kb.mapping(val)) = fp(val);
                % Technically not the most correct-- should find the min
                % of all keys, then fill in. This should be pretty ok though?
                if ~kb.rt
                    kb.rt = fp(val);
                end
            end

            for val = find(fr)
                kb.state.(kb.mapping(val)) = 0;
            end
            state = kb.state;
        end

        function delete(kb)
            %PsychHID('KbQueueStop', -1);
            % PsychHID('KbQueueRelease', -1);
        end
    end
end
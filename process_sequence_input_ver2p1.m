function [valve_closure_seq,wait_time_seq,input_validity,Error_mesg]=process_sequence_input_ver2p1(sequence_to_execute,sequence_valves,valves_closed_by_default)
% Initialize error_mesg
    Error_mesg='';

% remove the '-' separating each valve sequence/wait time from the
    % input string and get all the strings in between as separate cells
    parsed_input=regexp(sequence_to_execute,'-','split');
    valve_set_strings=parsed_input(1:2:end);
    wait_time_strings=parsed_input(2:2:end);
    
    %cellfun applies a particular function to every single cell in a cell
    %array
    valve_set_string_lengths=cellfun(@length,valve_set_strings);
    
    % find out if valve sequences entered contain even number of characters
    % each valve number takes 2 characters, so no matter how many valves
    % are to be closed, each valve set to close should have even number of characters 
    if find(mod(valve_set_string_lengths,2))
        Error_mesg='Each valve set to close must have even number of digits! Enter 01 for valve number 1, 02 for valve number 2 and so on';
        input_validity=false;        
    else
        input_validity=true;
        if valves_closed_by_default
            for valve_set=1:length(valve_set_strings)
                %reshape '121314' to ['12';'13';'14'] and then convert strings
                %to numbers
                valve_closure_seq(valve_set).valve_set=str2num(reshape(valve_set_strings{valve_set},2,valve_set_string_lengths(valve_set)/2)');

                % check if valve numbers are numeric!    
                if isempty(valve_closure_seq(valve_set).valve_set)
                    Error_mesg='Enter numbers only for valves you moron!';
                    input_validity=false;
                    break;
                % Check if any valve number entered does not belong to the sequence valve set
                elseif find(~ismember(valve_closure_seq(valve_set).valve_set,sequence_valves))
                    Error_mesg='Some valve numbers in the sequence dont belong to set of valves in the sequence';
                    input_validity=false;                 
                end
                % In this case, the valves entered by the user are the
                % valves to be opened. Convert these to the valves to be
                % closed internally.
                valve_closure_seq(valve_set).valve_set=setdiff(sequence_valves,valve_closure_seq(valve_set).valve_set);                
            end
        else
            for valve_set=1:length(valve_set_strings)
                %reshape '121314' to ['12';'13';'14'] and then convert strings
                %to numbers
                valve_closure_seq(valve_set).valve_set=str2num(reshape(valve_set_strings{valve_set},2,valve_set_string_lengths(valve_set)/2)');

                % check if valve numbers are numeric!    
                if isempty(valve_closure_seq(valve_set).valve_set)
                    Error_mesg='Enter numbers only for valves you moron!';
                    input_validity=false;
                    break;
                % Check if any valve number entered does not belong to the sequence valve set
                elseif find(~ismember(valve_closure_seq(valve_set).valve_set,sequence_valves))
                    Error_mesg='Some valve numbers in the sequence dont belong to set of valves in the sequence';
                    input_validity=false;                 
                end    
            end
        end  
    end    
    
    try
        wait_time_seq=cellfun(@str2num,wait_time_strings);
        %make sure there is one wait time associated with each valve set to
        %close
        if length(wait_time_seq)<length(valve_set_strings)
            wait_time_seq(end+1)=0;
        end
                
    catch
        Error_mesg='Wait times are only numeric in our world';
        input_validity=false;
    end
    
    % make sure all output variables are initialized if input is invalid to 
    % prevent errors while returning from this function
    if input_validity==false
        valve_closure_seq=0;
        wait_time_seq=0;
    end
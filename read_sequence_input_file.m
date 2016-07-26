function [valve_closure_seq,wait_time_seq,valves_to_close_at_end_of_seq,input_validity,Error_mesg]= read_sequence_input_file(seq_input_file,available_valves)

% Initialize valve_closure_seq and wait_time_seq to return in case of an
% error
    valve_closure_seq=[];
    wait_time_seq=[];
    input_validity=true;
    Error_mesg='';

% Read the seq_input worksheet from the excel file
[~,~,seq_data]=xlsread(seq_input_file,'seq_input');
% we only care about the first two columns from the data
seq_data=seq_data(1:end,1:2);

% check if the input file contains a sequence within sequence
seq_in_seq=seq_data{find(strcmp(seq_data(:,2),'seq_in_seq')),1};
% read other options included in the file
valves_closed_by_default=seq_data{find(strcmp(seq_data(:,2),'valves_closed_by_default')),1};
seq_rep_count=seq_data{find(strcmp(seq_data(:,2),'seq_rep_count')),1};

% Check if some of the options in the sequence file are numeric
if ~isnumeric(seq_in_seq)|~isnumeric(valves_closed_by_default)|~isnumeric(seq_rep_count)
    input_validity=false;
    Error_mesg='Sequence file has nun-numeric seq_in_seq or valves_closed_by_default or seq_rep_count';
    return;
end

valves_to_close_at_end_of_seq=seq_data{find(strcmp(seq_data(:,2),'valves_to_close_at_end_of_seq')),1};

% check if valves_to_close_at_end_of_seq is a string or numeric
if ~isnumeric(valves_to_close_at_end_of_seq)&~ischar(valves_to_close_at_end_of_seq)
    input_validity=false;
    Error_mesg='valves_to_close_at_end_of_seq in the sequence file is neither numeric nor a string';
    return;
else
    % if valves to close at the end are numeric(i.e. a single valve) do
    % nothing. But if it is a string, convert it to numbers
    if ischar(valves_to_close_at_end_of_seq)
        try
            % Strnum gives an error if the string doesnt contain numeric
            % info
            valves_to_close_at_end_of_seq=str2num(valves_to_close_at_end_of_seq);
        catch
            input_validity=false;
            Error_mesg='valves_to_close_at_end_of_seq is a string without numbers';
            return;
        end
    end
end

valves_in_seq=seq_data{find(strcmp(seq_data(:,2),'valves_in_seq')),1};

% check if valves_in_seq is a string or numeric
if ~isnumeric(valves_in_seq)&~ischar(valves_in_seq)
    input_validity=false;
    Error_mesg='valves_in_seq in the sequence file is neither numeric nor a string';
    return;
else
    % if valves in the sequence are numeric(i.e. a single valve) do
    % nothing. But if it is a string, convert it to numbers
    if ischar(valves_in_seq)
        try
            % Strnum gives an error if the string doesnt contain numeric
            % info
            valves_in_seq=str2num(valves_in_seq);
        catch
            input_validity=false;
            Error_mesg='valves_in_seq is a string without numbers';
            return;
        end
    end
end


seq_start_row=find(strcmp(seq_data(:,1),'Valves'))+1;

% need to check if seq_in_seq, valves_closed_by_default etc are empty since isnumeric doesn't check for this 
if isempty(seq_in_seq)|isempty(valves_closed_by_default)|isempty(seq_rep_count)|isempty(valves_to_close_at_end_of_seq)|isempty(valves_in_seq)|isempty(seq_start_row)
    input_validity=false;
    Error_mesg='Sequence file is missing seq_in_seq or valves_closed_by_default or seq_rep_count or valves_to_close_at_end_of_seq or valves_in_seq or seq_start_row';
    return;
end

% check if valves_to_close_at_end_of_seq and valves_in_seq belong to
% available valves. No need to check this for every sequence step since all
% the sequence valves are checked to be from the valves_in_seq pool

if find(~ismember(valves_to_close_at_end_of_seq,available_valves))
    input_validity=false;
    Error_mesg='valves_to_close_at_end_of_seq contains valve numbers which arent available!';
    return;
elseif find(~ismember(valves_in_seq,available_valves))
    input_validity=false;
    Error_mesg='valves_in_seq contains valve numbers which arent available!';
    return;
end 

% We dont need the earlier data from seq_data which is read into separate variables already
% so remove it to leave only the valve sequence and wait time seq in
% seq_data
seq_data=seq_data(seq_start_row:end,1:2);

% Remove any empty rows from this data (empty cells show up as NaN
% in the data read from excel
% @(x) all(isnan(x)) creates an anonymous function which accepts
% variable x and returns the result of the function all(isnan(x))
% all(vector) returns 1 if none of the vector elements are zero
nanmask=cellfun(@(x) all(isnan(x)),seq_data(:,1));
seq_data=seq_data(~nanmask,1:2);


if ~seq_in_seq
    if ~isempty(seq_data)
        for seq_step=1:size(seq_data,1)
            if isnumeric(seq_data{seq_step,1}) 
                valve_closure_seq(seq_step).valve_set=seq_data{seq_step,1};
            elseif ischar(seq_data{seq_step,1})
                try
                    valve_closure_seq(seq_step).valve_set=str2num(seq_data{seq_step,1});
                catch
                    input_validity=false;
                    Error_mesg='one of the steps in the sequence is a string without numbers';
                    return;
                end
            else
                % This case implies the seq_step is non-numeric and
                % non-string and most probably empty
                input_validity=false;
                Error_mesg='One of the sequence steps is non-numeric and non-string';
                return;
            end
            
            %check if the valves in this step belong to the sequence valve pool
            if ~isempty(find(~ismember(valve_closure_seq(seq_step).valve_set,valves_in_seq)))
                    input_validity=false;
                    Error_mesg='Some valves in sequence steps are not a part of the sequence valve pool';
                    return;
            end

            if valves_closed_by_default
                % In this case, valves in the sequence file are the valves to
                % be opened. Convert these to valves to be closed
                valve_closure_seq(seq_step).valve_set=setdiff(valves_in_seq,valve_closure_seq(seq_step).valve_set);
            end

            % Check if the wait time included in the sequence step is
            % numeric
            if isnumeric(seq_data{seq_step,2})
                wait_time_seq(seq_step)=seq_data{seq_step,2};
            else
                input_validity=false;
                Error_mesg='Wait times are only numeric in our world';
                return;
            end
            
            % Special case to warn about a really long wait time in the
            % sequence (check for wait time longer than 1 hour)
            if wait_time_seq(seq_step)>3600
                Error_mesg='There is a really long f**kin wait time in the sequence!';
            end            
        end
    else
        input_validity=false;
        Error_mesg='Sequence data is empty you moron';
        return;
    end
else
    [~,~,seq_in_seq_data]=xlsread(seq_input_file,'seq_in_seq_input');
    if ~isempty(seq_in_seq_data)
        seq_in_seq_start_row=find(strcmp(seq_in_seq_data(:,2),'Steps'))+1;
        if isempty(seq_in_seq_start_row)
            input_validity=false;
            Error_mesg='Couldnt find the data start row in seq_in_seq_input worksheet';
            return;
        end
        % Store only the useful data from the 'seq_in_seq_input' worksheet, which is in the 2nd and 3rd columns 
        seq_in_seq_data=seq_in_seq_data(seq_in_seq_start_row:end,2:3);
        
        % Remove any empty rows from this data (empty cells show up as NaN
        % in the data read from excel
        % @(x) all(isnan(x)) creates an anonymous function which accepts
        % variable x and returns the result of the function all(isnan(x))
        % all(vector) returns 1 if none of the vector elements are zero
        nanmask=cellfun(@(x) all(isnan(x)),seq_in_seq_data(:,1));
        seq_in_seq_data=seq_in_seq_data(~nanmask,1:2);

        
        seq_in_seq=[];
        for counter=1:size(seq_in_seq_data,1)
            if isnumeric(seq_in_seq_data{counter,1})
                seq_in_seq(counter).steps=seq_in_seq_data{counter,1};
            elseif ischar(seq_in_seq_data{counter,1})
                try
                    seq_in_seq(counter).steps=str2num(seq_in_seq_data{counter,1});
                catch
                    input_validity=false;
                    Error_mesg='The list of steps in one of the sequence in sequence is a string without numeric data';
                    return;
                end
            else
                input_validity=false;
                Error_mesg='The list of steps in one of the sequence in sequence is neither numeric nor a string';
                return;
            end

            if ~isempty(seq_in_seq(counter).steps)
                % One way to check that the steps are continuous and not
                % random numbers
                % First sort the steps in an ascending order
                sorted_steps=sort(seq_in_seq(counter).steps);
                if find(seq_in_seq(counter).steps~=sorted_steps)
                    input_validity=false;
                    Error_mesg='sequence in sequence steps are not continuous stupid!';
                    return;
                end
            else
                input_validity=false;
                Error_mesg='One of the sequence in sequence contains no steps';
                return;
            end
            
            if isnumeric(seq_in_seq_data{counter,2})
                seq_in_seq_rep(counter)=seq_in_seq_data{counter,2};
            else
                input_validity=false;
                Error_mesg='The repeat count for a sequence in sequence is not numeric';
                return;
            end 
        end
        
        if seq_in_seq(1).steps(1)~=1
            %If the first step in the first multi-repeat sequence is not 1
            for counter=1:length(seq_in_seq)
                if counter==1
                    seq_group(1).steps=[1:seq_in_seq(1).steps(1)-1];                
                    seq_group(2).steps=[seq_in_seq(1).steps];
                    seq_group(1).repeats=1;
                    seq_group(2).repeats=seq_in_seq_rep(1);
                else
                    seq_group((counter-1)*2+1).steps=[seq_in_seq(counter-1).steps(end)+1:seq_in_seq(counter).steps(1)-1];                
                    seq_group(counter*2).steps=[seq_in_seq(counter).steps];
                    seq_group((counter-1)*2+1).repeats=1;
                    seq_group(counter*2).repeats=seq_in_seq_rep(counter);                    
                end
            end
        else
            %If the first step in the first multi-repeat sequence is 1
            for counter=1:length(seq_in_seq)
                if counter~=length(seq_in_seq)
                    seq_group((counter-1)*2+1).steps=[seq_in_seq(counter).steps];
                    seq_group(counter*2).steps=[seq_in_seq(counter).steps(end)+1:seq_in_seq(counter+1).steps(1)-1];             
                    seq_group((counter-1)*2+1).repeats=seq_in_seq_rep(counter);
                    seq_group(counter*2).repeats=1;
                else
                    seq_group((counter-1)*2+1).steps=[seq_in_seq(counter).steps];
                    seq_group((counter-1)*2+1).repeats=seq_in_seq_rep(counter);
                end
            end
        end
                     
        if seq_in_seq(end).steps(end)~=size(seq_data,1)
            % If the last step in the last multi-repeat sequence is not the
            % last step in the main sequence from 'seq_input', then we
            % need the last sequence in the total number of sequences to be
            % the one from the last step of the last multi-repeat sequence
            % to the last step in the main sequence
            seq_group(end+1).steps=[seq_in_seq(end).steps(end)+1:size(seq_data,1)];
            %end+1 above becomes end here
            seq_group(end).repeats=1;
        end
        
        % Initialize valve_closure_seq and wait_time_seq for the 'end+1'
        % indexing to work properly in the loops below        
        valve_closure_seq=[];
        wait_time_seq=[];
        
        for counter=1:length(seq_group)
            for repeat=1:seq_group(counter).repeats
                for seq_step=1:length(seq_group(counter).steps)                    
                    if isnumeric(seq_data{seq_group(counter).steps(seq_step),1}) 
                        valve_closure_seq(end+1).valve_set=seq_data{seq_group(counter).steps(seq_step),1};
                    elseif ischar(seq_data{seq_group(counter).steps(seq_step),1})
                        try
                            valve_closure_seq(end+1).valve_set=str2num(seq_data{seq_group(counter).steps(seq_step),1});
                        catch
                            input_validity=false;
                            Error_mesg='one of the steps in the sequence is a string without numbers';
                            return;
                        end
                    else
                        % This case implies the seq_step is non-numeric and
                        % non-string and most probably empty
                        input_validity=false;
                        Error_mesg='One of the sequence steps is non-numeric and non-string';
                        return;
                    end

                    %check if the valves in this step belong to the sequence valve pool           
                    if ~isempty(find(~ismember(valve_closure_seq(end).valve_set,valves_in_seq)))
                        input_validity=false;
                        Error_mesg='Some valves in sequence steps are not a part of the sequence valve pool';
                        return;
                    end

                    if valves_closed_by_default
                        % In this case, valves in the sequence file are the valves to
                        % be opened. Convert these to valves to be closed
                        valve_closure_seq(end).valve_set=setdiff(valves_in_seq,valve_closure_seq(end).valve_set);
                    end

                    % Check if the wait time included in the sequence step is
                    % numeric
                    if isnumeric(seq_data{seq_group(counter).steps(seq_step),2})
                        wait_time_seq(end+1)=seq_data{seq_group(counter).steps(seq_step),2};
                    else
                        input_validity=false;
                        Error_mesg='Wait times are only numeric in our world';
                        return;
                    end

                    % Special case to warn about a really long wait time in the
                    % sequence (check for wait time longer than 1 hour)
                    if wait_time_seq(seq_step)>3600
                        Error_mesg='There is a really long f**kin wait time in the sequence!';
                    end   
                end
            end
        end
    else
        input_validity=false;
        Error_mesg='seq_in_seq_input worksheet is empty';
    end     
end
        
        
        
        
        
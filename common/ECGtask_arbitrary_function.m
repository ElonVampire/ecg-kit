classdef ECGtask_arbitrary_function < ECGtask

% ECGtask for ECGwrapper (for Matlab)
% ---------------------------------
% 
% Description:
% 
% Task to perform linear filtering in ECG signals
% 
% 
% Author: Mariano Llamedo Soria (llamedom at {electron.frba.utn.edu.ar; unizar.es}
% Version: 0.1 beta
% Birthdate  : 25/2/2015
% Last update: 25/2/2015
       
    properties(GetAccess = public, Constant)
        name = 'arbitrary_function';
        target_units = 'ADCu';
        doPayload = true;
    end

    properties( GetAccess = public, SetAccess = private)
        % if user = memory;
        % memory_constant is the fraction respect to user.MaxPossibleArrayBytes
        % which determines the maximum input data size.
        memory_constant = 0.5;
        
        started = false;

% to track the signal range over the whole signal.         
        range_min_max_tracking = [ realmax realmin ]
        
    end
    
    properties( Access = private, Constant)
    
    end
    
    properties( Access = private )
        
    end
    
    properties
        
        progress_handle 
        user_string = ''
        tmp_path
        
        function_pointer
        only_ECG_leads = false
        lead_idx
        function_payload_in
        signal_payload = false
        
    end
    
    methods
           
        function obj = ECGtask_arbitrary_function(obj)

        end
        
        function Start(obj, ECG_header, ECG_annotations)

            if( obj.only_ECG_leads )
                obj.lead_idx = get_ECG_idx_from_header(ECG_header);
            else
%               'all-signals'
                obj.lead_idx = 1:ECG_header.nsig;
            end
            
            if( isempty(obj.lead_idx) )
                cprintf('*[1,0.5,0]', 'Could not find any valid signal.\n');
                return
            end
            
            obj.range_min_max_tracking = [ realmax realmin ];

            obj.started = true;
            
        end
        
        function payload = Process(obj, ECG, ECG_start_offset, ECG_sample_start_end_idx, ECG_header, ECG_annotations, ECG_annotations_start_end_idx  )
            
            payload = [];

            if( ~obj.started )
                obj.Start(ECG_header);
                if( ~obj.started )
                    cprintf('*[1,0.5,0]', 'Task %s unable to be started for %s.\n', obj.name, ECG_header.recname);
                    return
                end
            end

            if( nargin(obj.function_pointer) == 1 )
                payload.result_signal = obj.function_pointer( double(ECG(:,obj.lead_idx)) );
            else
                ECG_header_aux = trim_ECG_header(ECG_header, obj.lead_idx);
                payload.result_signal = obj.function_pointer( ECG(:,obj.lead_idx), ECG_header_aux, obj.progress_handle, obj.function_payload_in);
            end
            
            if( obj.signal_payload )
                % trim the signal
                payload.result_signal = payload.result_signal(ECG_sample_start_end_idx(1):ECG_sample_start_end_idx(2),:);
                
                obj.range_min_max_tracking = [ min(obj.range_min_max_tracking(1), min(payload.result_signal) ) max(obj.range_min_max_tracking(2), max(payload.result_signal)) ];
                
            end
            
            
        end
        
        function payload = Finish(obj, payload, ECG_header)
            
            
        end
        
        function payload = Concatenate(obj, plA, plB)

            if( isempty(plA) )
                
                payload = plB;
            else
                payload = [plA; plB];
            end
    
            
        end

        function set.function_pointer(obj,x)
            
            if( strcmpi( class(x), 'function_handle' ) )
                obj.function_pointer = x;
                return
            end
            
            if( ischar(x) && exist(x) == 2 )
                obj.function_pointer = str2func(x);
            else
                warning('ECGtask_arbitrary_function:BadArg', 'Invalid function pointer.');
            end
        end
        
        function set.only_ECG_leads(obj,x)
            if( islogical(x) )
                obj.only_ECG_leads = x;
            else
                warning('ECGtask_arbitrary_function:BadArg', 'Argument must be a logical value.');
            end
        end
        
    end
    
   
    
end

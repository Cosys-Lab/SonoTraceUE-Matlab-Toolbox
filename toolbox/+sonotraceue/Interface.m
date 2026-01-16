classdef Interface
    
    properties
        serverIP = 'localhost';
        serverPort = 9098;
        sendInputSettings = false;
        server;
        activeInterface = false;
        activeSettings;
        log = sonotraceue.logger("SonoTraceUE", false, true);
    end
    
    methods
        function obj = Interface(serverIP, serverPort, logLevel)
            if nargin > 0
                obj.serverIP = serverIP;
                obj.serverPort = serverPort;
                if nargin > 2
                    obj.log.default_level = logLevel;
                end 
            end      
            obj.log.show_logger_name = true;
            obj.server = tcpserver(obj.serverIP, obj.serverPort, "Timeout", 99999);
            obj.server.flush();
            obj.log.info('Interface server listening...');
            while ~obj.server.Connected
                pause(0.1); 
            end
            obj.log.debug(sprintf('SonoTraceUE client connecting to interface from %s:%d.', obj.server.ClientAddress, obj.server.ClientPort));
            if obj.sendInputSettings
                writeline(obj.server, 'sonotraceue_start_settings');
            else
                writeline(obj.server, 'sonotraceue_start_no_settings');
            end
            receivedMessage = readline(obj.server);
            if receivedMessage == "sonotraceue_start_ack"
                obj.log.info("Interface connected.");
                obj.activeInterface = true;
            else
                obj.log.error("Unexpected response from SonoTraceUE client: %s", receivedMessage)
                clear obj.server;
                obj.log.info('Interface closed.');
            end
        end

        function success = sendSettings(obj, settings)
            if obj.activeInterface
                if obj.sendInputSettings
                    obj.log.critical("this is not yet implemented.");
                    success= 0;
                else
                    obj.log.error("Interface is not configured to send settings!");
                    success= 0;
                end
            else
                obj.log.critical("No active interface, please connect first!");
                success = 0;
            end
        end

        function settings = receiveSettings(obj)
            if obj.activeInterface
                if ~obj.sendInputSettings
                    receivedMessage = readline(obj.server);
                    if(receivedMessage ~= "")
                        receivedMessage = eraseBetween(receivedMessage,1,1);
                    end
                    if strcmp("sonotraceue_settings", receivedMessage) || strcmp("onotracelab_settings", receivedMessage)
                        obj.log.debug("Receiving settings...")
                        writeline(obj.server, 'sonotraceue_ready_settings');
                        obj.server.flush();
                        settings = sonotraceue.Settings(obj.server);
                        obj.log.info("Received and parsed settings.")
                        writeline(obj.server, 'sonotraceue_settings_parsed');
                        obj.activeSettings = settings;
                    else
                        obj.log.error(sprintf("Unknown message received:%s", receivedMessage))
                        settings = 0;
                    end
                else
                    obj.log.error("Interface is not configured to receive settings!");
                    settings = 0;
                end
            else
                obj.log.critical("No active interface, please connect first!");
                settings = 0;
            end
        end

        function triggered = triggerMeasurement(obj, overrideEmitterSignalIndexes)
            overrideEmitterSignalIndexesEnabled = 1;
            if nargin < 2  
                overrideEmitterSignalIndexesEnabled = 0;
            end        

            if obj.activeInterface
                if overrideEmitterSignalIndexesEnabled
                    obj.log.debug("Triggering new measurement with override emitter signal indexes...");
                    commandString = sprintf('sonotraceue_overridetriggeroverride');
                    for i = 1:size(overrideEmitterSignalIndexes, 1)
                        commandString = sprintf('%s_%d', commandString, overrideEmitterSignalIndexes(i));                        
                    end

                    writeline(obj.server, commandString);
    
                    receivedMessage = readline(obj.server);
                    triggered = true;
                    if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                        obj.log.error("Could not trigger new measurement with override emitter signal indexes!");
                        triggered = false;
                    end
                else
                    obj.log.debug("Triggering new measurement...");
                    commandString = sprintf('sonotraceue_trigger');
                    writeline(obj.server, commandString);
    
                    receivedMessage = readline(obj.server);
                    triggered = true;
                    obj.log.debug("Measurement triggered.")
                    if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                        obj.log.error("Could not trigger new measurement!");
                        triggered = false;
                    end
                end
                
            else
                obj.log.critical("No active interface, please connect first!");
                triggered = false;
            end
        end

        function success = SetCurrentEmitterSignalIndexForSpecificEmitter(obj, emitterIndex, emitterSignalIndex)   
            if obj.activeInterface
                obj.log.debug(sprintf("Setting emitter signal index for emitter #%d...", emitterIndex))
                commandString = sprintf('sonotraceue_set_specific_emitter_signal_index_%d_%d', emitterIndex, emitterSignalIndex);       
                writeline(obj.server, commandString);

                receivedMessage = readline(obj.server);
                success = true;
                if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                    obj.log.error(sprintf("Failed to set emitter signal index for emitter #%d.", emitterIndex));
                    success = false;
                else
                    obj.log.debug("Emitter signal index set.")
                end  
            else
                obj.log.critical("No active interface, please connect first!");
                success = false;
            end
        end

        function success = SetCurrentEmitterSignalIndexes(obj, emitterSignalIndexes)   
            if obj.activeInterface
                obj.log.debug("Setting emitter signal indexes for all emitters...");
                commandString = sprintf('sonotraceue_set_signal_indexes');
                for i = 1:size(emitterSignalIndexes, 1)
                    commandString = sprintf('%s_%d', commandString, emitterSignalIndexes(i));                        
                end
                writeline(obj.server, commandString);

                receivedMessage = readline(obj.server);
                success = true;
                if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage)|| strcmp(" snok", receivedMessage)
                    obj.log.error("Failed to set emitter signal indexes!");
                    success = false;
                else
                    obj.log.debug("Emitter signal indexes set.")
                end  
            else
                obj.log.critical("No active interface, please connect first!");
                success = false;
            end
        end

        function emitterSignalIndex = GetCurrentEmitterSignalIndexForSpecificEmitter(obj, emitterIndex)           
            if obj.activeInterface
                obj.log.debug(sprintf("Getting emitter signal index for emitter #%d...", emitterIndex))      
                commandString = sprintf('sonotraceue_get_specific_emitter_signal_index_%d', emitterIndex);            
                writeline(obj.server, commandString);
    
                receivedMessage = readline(obj.server);
                if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                    obj.log.error(sprintf("Failed to get emitter signal index for emitter #%d.", emitterIndex));
                    emitterSignalIndex = -1;
                else
                    emitterSignalIndex = str2double(regexp(receivedMessage, '\d+', 'match'));
                    obj.log.debug("Emitter signal index received.")
                end
            else
                obj.log.critical("No active interface, please connect first!");
                emitterSignalIndex = -1;
            end
        end

        function emitterSignalIndexes = GetCurrentEmitterSignalIndexes(obj)           
            if obj.activeInterface
                obj.log.debug("Getting emitter signal indexes for all emitters...")      
                commandString = sprintf('sonotraceue_get_signal_indexes');            
                writeline(obj.server, commandString);
    
                receivedMessage = readline(obj.server);
                if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                    obj.log.error("Failed to get emitter signal indexes.");
                    emitterSignalIndexes = [];
                else
                    emitterSignalIndexes = str2double(regexp(receivedMessage, '\d+', 'match'));
                    obj.log.debug("Emitter signal indexes received.")
                end
            else
                obj.log.critical("No active interface, please connect first!");
                emitterSignalIndexes = [];
            end
        end

        function success = SendDataMessage(obj, dataMessage)
            type = dataMessage.type;
            order = dataMessage.order;
            strings = dataMessage.strings;
            integers = dataMessage.integers;
            floats = dataMessage.floats;
 
            if obj.activeInterface
                obj.log.debug("Sending data message...");
                commandString = sprintf('sonotraceue_data_%d', type);

                stringIndex = 1;
                intIndex = 1;
                floatIndex = 1;

                for i = 1:length(order)
                    switch order(i)
                        case 0 % String
                            if stringIndex <= length(strings)
                                commandString = sprintf('%s_S_%s', commandString, strings{stringIndex});
                                stringIndex = stringIndex + 1;
                            else
                                obj.log.warning("Not enough strings provided for the specified order!");
                                success = false;
                                return;
                            end
                        case 1 % Integer
                            if intIndex <= length(integers)
                                commandString = sprintf('%s_I_%d', commandString, integers(intIndex));
                                intIndex = intIndex + 1;
                            else
                                obj.log.warning("Not enough integers provided for the specified order!");
                                success = false;
                                return;
                            end
                        case 2 % Float
                            if floatIndex <= length(floats)
                                commandString = sprintf('%s_F_%.6f', commandString, floats(floatIndex));
                                floatIndex = floatIndex + 1;
                            else
                                obj.log.warning("Not enough floats provided for the specified order!");
                                success = false;
                                return;
                            end
                        otherwise
                            obj.log.warning("Unknown data type identifier in order array!");
                            success = false;
                            return;
                    end
                end

                writeline(obj.server, commandString);
                receivedMessage = readline(obj.server);
                success = true;
                if strcmp("snok0", receivedMessage) || strcmp("nok0", receivedMessage)
                    obj.log.warning("Interface reported bad Type parsing, could not receive data!");
                    success = false;
                elseif strcmp("snok1", receivedMessage) || strcmp("nok1", receivedMessage)
                    obj.log.warning("Interface reported bad data format without value, could not receive data!");
                    success = false;
                elseif strcmp("snok2", receivedMessage) || strcmp("nok2", receivedMessage)
                    obj.log.warning("Interface reported Unknown data type identifier, could not receive data!");
                    success = false;
                elseif strcmp("snok3", receivedMessage) || strcmp("nok3", receivedMessage)
                    obj.log.warning("Interface reported bad data element parsing, could not receive data!");
                    success = false;
                else
                    obj.log.debug("Data message received and parsed by client.");
                end
            else
                obj.log.critical("No active interface, please connect first!");
                success = false;
            end
        end

        function success = setNewEmitterPositions(obj, emitterIndexes, newEmitterPositions, relativeTransform, reApplyOffset)
            
            receiverCount = size(emitterIndexes, 2);

            if ~isequal(size(newEmitterPositions), [3, receiverCount])
                obj.log.error("Invalid new emitter positions matrix. Provide a 3xN matrix with N the amount of emitters matching the emitter indexes array size.");
                success = false;
                return;
            end
            if obj.activeInterface
                obj.log.debug("Setting new new emitter positions...")
                commandString = sprintf('sonotraceue_set_emitter_positions_%i_%i_%i', ...
                    receiverCount, single(relativeTransform), single(reApplyOffset));      

                for i = 1:receiverCount                        
                    commandString = sprintf('%s_%i', commandString, emitterIndexes(i));
                end
                for i = 1:receiverCount                        
                    commandString = sprintf('%s_%.6f_%.6f_%.6f', commandString, newEmitterPositions(1, i) * 100, -newEmitterPositions(2, i) * 100, newEmitterPositions(3, i) * 100);
                end
                writeline(obj.server, commandString);
    
                receivedMessage = readline(obj.server);
                success = true;
                if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                    obj.log.error("Failed to set new emitter positions.");
                    success = false;
                else
                    obj.log.debug("New emitter positions set.");
                end
            else
                obj.log.critical("No active interface, please connect first!");
                success = false;
            end
        end

        function success = setNewReceiverPositions(obj, receiverIndexes, newReceiverPositions, relativeTransform, reApplyOffset)
            
            receiverCount = size(receiverIndexes, 2);

            if ~isequal(size(newReceiverPositions), [3, receiverCount])
                obj.log.error("Invalid new receiver positions matrix. Provide a 3xN matrix with N the amount of receivers matching the receiver indexes array size.");
                success = false;
                return;
            end
            if obj.activeInterface
                obj.log.debug("Setting new new receiver positions...")
                commandString = sprintf('sonotraceue_set_receiver_positions_%i_%i_%i', ...
                    receiverCount, single(relativeTransform), single(reApplyOffset));      

                for i = 1:receiverCount                        
                    commandString = sprintf('%s_%i', commandString, receiverIndexes(i));
                end
                for i = 1:receiverCount                        
                    commandString = sprintf('%s_%.6f_%.6f_%.6f', commandString, newReceiverPositions(1, i) * 100, -newReceiverPositions(2, i) * 100, newReceiverPositions(3, i) * 100);
                end
                writeline(obj.server, commandString);
    
                receivedMessage = readline(obj.server);
                success = true;
                if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                    obj.log.error("Failed to set new receiver positions.");
                    success = false;
                else
                    obj.log.debug("New receiver positions set.");
                end
            else
                obj.log.critical("No active interface, please connect first!");
                success = false;
            end
        end

        function success = setNewSensorRelativeTransform(obj, tform)
            if ~isequal(size(tform), [4, 4])
                obj.log.error("Invalid transform matrix. Provide a 4x4 transformation matrix.");
                success = false;
                return;
            end
            
            if obj.activeInterface
                obj.log.debug("Setting new relative transform...")
                [locationCentimeters, rotationQuat] = sonotraceue.matlabTFormToUnreal(tform);            
                commandString = sprintf('sonotraceue_set_relative_transform_%.6f_%.6f_%.6f_%.6f_%.6f_%.6f_%.6f', ...
                    locationCentimeters, rotationQuat);            
                writeline(obj.server, commandString);
    
                receivedMessage = readline(obj.server);
                success = true;
                if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                    obj.log.error("Failed to set new relative transform.");
                    success = false;
                else
                    obj.log.debug("New relative transform set.");
                end
            else
                obj.log.critical("No active interface, please connect first!");
                success = false;
            end
        end

        function success = setNewSensorWorldTransform(obj, tform, teleport)
            if ~isequal(size(tform), [4, 4])
                obj.log.error("Invalid transform matrix. Provide a 4x4 transformation matrix.");
                success = false;
                return;
            end
        
            if nargin < 3
                teleport = 0; 
            end
        
            if obj.activeInterface
                obj.log.debug("Setting new sensor transform...")
                [locationCentimeters, rotationQuat] = sonotraceue.matlabTFormToUnreal(tform);            
                commandString = sprintf('sonotraceue_set_sensor_transform_%.6f_%.6f_%.6f_%.6f_%.6f_%.6f_%.6f_%i', ...
                    locationCentimeters, rotationQuat, teleport);  
                writeline(obj.server, commandString);        
    
                receivedMessage = readline(obj.server);
                success = true;
                if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                    obj.log.error("Failed to set new sensor transform.");
                    success = false;
                else
                    obj.log.debug("New sensor transform set.");
                end
            else
                obj.log.critical("No active interface, please connect first!");
                success = false;
            end
        end
        
        function success = setNewSensorOwnerWorldTransform(obj, tform, teleport)
            if ~isequal(size(tform), [4, 4])
                obj.log.error("Invalid transform matrix. Provide a 4x4 transformation matrix.");
                success = false;
                return;
            end
        
            if nargin < 3
                teleport = 0; 
            end
        
            if obj.activeInterface
                obj.log.debug("Setting new owner transform...")
                [locationCentimeters, rotationQuat] = sonotraceue.matlabTFormToUnreal(tform);
                commandString = sprintf('sonotraceue_set_owner_transform_%.6f_%.6f_%.6f_%.6f_%.6f_%.6f_%.6f_%i', ...
                    locationCentimeters, rotationQuat, teleport);            
                writeline(obj.server, commandString);       
    
                receivedMessage = readline(obj.server);
                success = true;
                if strcmp("snok", receivedMessage) || strcmp("nok", receivedMessage) || strcmp(" snok", receivedMessage)
                    obj.log.error("Failed to set new owner transform.");
                    success = false;
                else
                    obj.log.debug("New owner transform set.");
                end
            else
                obj.log.critical("No active interface, please connect first!");
                success = false;
            end
        end      

        function [data, type] = receiveData(obj)
            if obj.activeInterface
                obj.log.debug("Waiting for new data...")
                receivedMessage = readline(obj.server);
                 if(receivedMessage ~= "")
                    receivedMessage = eraseBetween(receivedMessage,1,1);
                 end
                 if strcmp("sonotraceue_measurement", receivedMessage) || strcmp("onotracelab_measurement", receivedMessage)
                    obj.log.debug("Receiving new measurement...")
                    writeline(obj.server, 'sonotraceue_ready_measurement');
                    obj.server.flush();
                    type = 1;
                    data = sonotraceue.Measurement(obj.server);
                    obj.log.debug(sprintf("Received and parsed measurement #%i.", data.index))
                 elseif strcmp("sonotraceue_data", receivedMessage) || strcmp("onotracelab_data", receivedMessage)
                    obj.log.debug("Receiving new data message...")
                    writeline(obj.server, 'sonotraceue_ready_data');
                    obj.server.flush();
                    type = 2;
                    data = sonotraceue.DataMessage(obj.server);
                    obj.log.debug(sprintf("Received and parsed data message of type #%i.", data.type))
                 elseif strcmp("sonotraceue_end", receivedMessage) || strcmp("onotracelab_end", receivedMessage)
                    clear obj.server;
                    obj.log.debug('Receive closing message. Interface closed.');
                    type = 0;
                    data = 0;
                 else
                    obj.log.error(sprintf("Unknown message received:%s", receivedMessage))
                    type = -2;
                    data = receivedMessage;
                 end
            else
                obj.log.critical("No active interface, please connect first!");
                type = -1;
                data = 0;
            end
        end
    end
end


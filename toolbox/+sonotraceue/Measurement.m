classdef Measurement
    
    properties
        index = -1;
        timestamp = 0;
        maximumStrength = 0;
        maximumCurvature = 0;        
        maximumTotalDistance = 0;
        emitterSignalIndexes = [];
        sensorTForm = [];
        sensorToOwnerTForm = [];
        ownerTForm = [];
        emitterTForms = [];
        receiverTForms = [];
        directPathLOS = [];
        impulseResponses = [];
        receiverSignals = [];
        reflectedPoints;
        specularSubOutput;
        diffractionSubOutput;
        directPathSubOutput;

        numberOfFrequencies = 0;
        numberOfEmitters = 0;
        numberOfReceivers = 0;
        sampleRate = 450000;
        pointsInSensorFrame = true;
        plotAxisLimit = 10; 
    end
    
    methods
        function obj = Measurement(server)
            if nargin < 1 
                server = []; 
            end

            if ~isempty(server)
                % Data size
                dataDataSize = uint8(read(server, 4, "uint8"));
                dataSize = typecast(swapbytes(dataDataSize), "int32");               
    
                % Read all data into a buffer in one operation
                dataBuffer = uint8(read(server, dataSize, "uint8"));
    
                % Use a pointer-based approach to parse the data
                pointer = 1;
                
                % Index and timestamp
                obj.index = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "int32");
                pointer = pointer + 4;
                obj.timestamp = typecast(swapbytes(dataBuffer(pointer:pointer+7)), "double");
                pointer = pointer + 8;
        
                % Plot limits
                obj.maximumStrength = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "single");
                pointer = pointer + 4;
                obj.maximumCurvature = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "single");
                pointer = pointer + 4;
                obj.maximumTotalDistance = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "single") / 100;
                pointer = pointer + 4;

                % Frequency count
                numberOfFrequencies = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "int32");
                pointer = pointer + 4;

                % Sample frequency
                sampleRate = single(typecast(swapbytes(dataBuffer(pointer:pointer+3)), "int32"));
                pointer = pointer + 4;

                % Points reference frame
                pointsInSensorFrame = logical(dataBuffer(pointer));
                pointer = pointer + 1;
        
                % Sensor pose
                sensorPosition = typecast(swapbytes(dataBuffer(pointer:pointer+23)), "double");
                pointer = pointer + 24;
                sensorRotation = typecast(swapbytes(dataBuffer(pointer:pointer+31)), "double");
                pointer = pointer + 32;
                obj.sensorTForm = sonotraceue.unrealToMatlabTForm(sensorPosition, sensorRotation);

                % Sensor to owner transform
                sensorToOwnerTranslation = typecast(swapbytes(dataBuffer(pointer:pointer+23)), "double");
                pointer = pointer + 24;
                sensorToOwnerRotation = typecast(swapbytes(dataBuffer(pointer:pointer+31)), "double");
                pointer = pointer + 32;
                obj.sensorToOwnerTForm = sonotraceue.unrealToMatlabTForm(sensorToOwnerTranslation, sensorToOwnerRotation);

                % Owner pose
                ownerPosition = typecast(swapbytes(dataBuffer(pointer:pointer+23)), "double");
                pointer = pointer + 24;
                ownerRotation = typecast(swapbytes(dataBuffer(pointer:pointer+31)), "double");
                pointer = pointer + 32;
                obj.ownerTForm = sonotraceue.unrealToMatlabTForm(ownerPosition, ownerRotation);
        
                % Emitter poses
                numberOfEmitters = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "int32");
                pointer = pointer + 4;
                obj.emitterTForms = zeros(4, 4, numberOfEmitters);
                for emitterIndex = 1:numberOfEmitters
                    curEmitterPosition = typecast(swapbytes(dataBuffer(pointer:pointer+23)), "double");
                    pointer = pointer + 24;
                    curEmitterRotation = typecast(swapbytes(dataBuffer(pointer:pointer+31)), "double");
                    pointer = pointer + 32;
                    obj.emitterTForms(:, :, emitterIndex) = sonotraceue.unrealToMatlabTForm(curEmitterPosition, curEmitterRotation);
                end         
        
                % Receiver poses
                numberOfReceivers = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "int32");
                pointer = pointer + 4;
                obj.receiverTForms = zeros(4, 4, numberOfReceivers);
                for receiverIndex = 1:numberOfReceivers
                    curReceiverPosition = typecast(swapbytes(dataBuffer(pointer:pointer+23)), "double");
                    pointer = pointer + 24;
                    curReceiverRotation = typecast(swapbytes(dataBuffer(pointer:pointer+31)), "double");
                    pointer = pointer + 32;
                    obj.receiverTForms(:, :, receiverIndex) = sonotraceue.unrealToMatlabTForm(curReceiverPosition, curReceiverRotation);
                end  

                % Direct path LOS results
                numberOfDirectPathResults = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "int32");
                pointer = pointer + 4;
                obj.directPathLOS = zeros(numberOfDirectPathResults, 1);
                for receiverIndex = 1:numberOfDirectPathResults
                    currentDirectPathLOSResult = logical(dataBuffer(pointer));
                    pointer = pointer + 1;
                    obj.directPathLOS(receiverIndex, 1) = currentDirectPathLOSResult;
                end  

                % Emitter signal indexes
                obj.emitterSignalIndexes = zeros(numberOfEmitters, 1);
                for emitterIndex = 1:numberOfEmitters
                    curEmitterSignalIndex = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "int32");
                    pointer = pointer + 4;
                    obj.emitterSignalIndexes(emitterIndex, 1) = curEmitterSignalIndex;
                end  

                % Reflected points
                reflectedPointsCount = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "int32");
                pointer = pointer + 4;
                if reflectedPointsCount > 0
                    templateStruct = sonotraceue.pointStructGenerator(); 
                    pointStructs = repmat(templateStruct, reflectedPointsCount, 1);
                    for reflectedPointIndex = 1:reflectedPointsCount
                        reflectedPointSize = typecast(swapbytes(dataBuffer(pointer:pointer+3)), "int32");
                        pointer = pointer + 4;
                        reflectedPointData = dataBuffer(pointer:pointer+reflectedPointSize-1);
                        pointer = pointer + reflectedPointSize;
                        pointStructs(reflectedPointIndex) = sonotraceue.pointStructGenerator(reflectedPointData, numberOfEmitters, numberOfReceivers, numberOfFrequencies);
                    end
                end
                obj.reflectedPoints = pointStructs;
        
                % Specular sub-output
                specularSubOutputActive = dataBuffer(pointer);
                pointer = pointer + 1;
                
                if specularSubOutputActive
                    [obj.specularSubOutput, pointer] = sonotraceue.SubOutput(dataBuffer, pointer, numberOfEmitters, numberOfReceivers, numberOfFrequencies);
                end
                
                % Diffraction sub-output
                diffractionSubOutputActive = dataBuffer(pointer);
                pointer = pointer + 1;
                
                if diffractionSubOutputActive
                    [obj.diffractionSubOutput, pointer] = sonotraceue.SubOutput(dataBuffer, pointer, numberOfEmitters, numberOfReceivers, numberOfFrequencies);
                end

                % direct path sub-output
                directPathSubOutputActive = dataBuffer(pointer);
                pointer = pointer + 1;
                
                if directPathSubOutputActive
                    [obj.directPathSubOutput, pointer] = sonotraceue.SubOutput(dataBuffer, pointer, numberOfEmitters, numberOfReceivers, numberOfFrequencies);
                end
    
                obj.numberOfEmitters = numberOfEmitters;
                obj.numberOfReceivers = numberOfReceivers;
                obj.numberOfFrequencies = numberOfFrequencies;
                obj.sampleRate = sampleRate;
                obj.pointsInSensorFrame = pointsInSensorFrame;
            end
        end

        function isSet = isImpulseResponsesSet(obj)
            isSet = ~isempty(obj.impulseResponses);
        end

        function isSet = isDirectPathLOS(obj)
            isSet = ~isempty(obj.directPathLOS);
        end

        function isSet = isReceiverSignalsSet(obj)
            isSet = ~isempty(obj.receiverSignals);
        end

        function isSet = isSpecularSubOutputSet(obj)
            isSet = ~isempty(obj.specularSubOutput);
        end

        function isSet = isDiffractionSubOutputSet(obj)
            isSet = ~isempty(obj.diffractionSubOutput);
        end

        function isSet = isDirectPathSubOutputSet(obj)
            isSet = ~isempty(obj.directPathSubOutput);
        end

        function obj = synthetizeIRFromPoints(obj, settings)
            if ~settings.settingsSetManually
                warning("Using default settings for IR synthesis and signal generation. Make sure to provide these with settings.prepareIRandSignalGeneration(...) first!");
            end        
            
            if settings.enableEmitterPatternSimulation
                if settings.useBaseKernels && ~isempty(settings.baseKernels)
                    totalNumberOfMics = size(settings.finalReceiverPositions, 1);
                    virtualReceiversPerRealReceiver = totalNumberOfMics / settings.numberOfReceivers;
                    impulseResponsesAll = sonotraceue.synthetizeIRFromPointsWithBaseKernels(obj.reflectedPoints, settings.sampleRate, settings.numberOfSamplesIRFilter, settings.frequencies, ...
                                                                                            settings.numberOfIRSamples, settings.numberOfEmitters, totalNumberOfMics, ...
                                                                                            settings.approximateIRCutDB, settings.enableApproximateIR, settings.speedOfSound, settings.baseKernels);
                    if settings.enablePatternSum
                        impulseResponsesReshaped = reshape(impulseResponsesAll, settings.numberOfEmitters, virtualReceiversPerRealReceiver, settings.numberOfReceivers, size(impulseResponsesAll, 3));
                        obj.impulseResponses = reshape(sum(impulseResponsesReshaped, 2), settings.numberOfEmitters, settings.numberOfReceivers, size(impulseResponsesAll, 3))  ./ double(virtualReceiversPerRealReceiver);
                    else 
                        obj.impulseResponses = impulseResponsesAll;
                    end
                else
                    if settings.useBaseKernels && isempty(settings.baseKernels)
                        warning("settings.useBaseKernels is enabled but no base kernels are found so running without! Make sure to generate them with settings.prepareIRandSignalGeneration(...) first!");
                    end

                    totalNumberOfMics = size(settings.finalReceiverPositions, 1);
                    virtualReceiversPerRealReceiver = totalNumberOfMics / settings.numberOfReceivers;
                    impulseResponsesAll = sonotraceue.synthetizeIRFromPoints(obj.reflectedPoints, settings.sampleRate, settings.numberOfSamplesIRFilter, settings.frequencies, ...
                                                                             settings.iRFilterGaussAlpha, settings.numberOfIRSamples, settings.numberOfEmitters, totalNumberOfMics, ...
                                                                             settings.approximateIRCutDB, settings.enableApproximateIR, settings.speedOfSound);
                    if settings.enablePatternSum
                        impulseResponsesReshaped = reshape(impulseResponsesAll, settings.numberOfEmitters, virtualReceiversPerRealReceiver, settings.numberOfReceivers, size(impulseResponsesAll, 3));
                        obj.impulseResponses = reshape(sum(impulseResponsesReshaped, 2), settings.numberOfEmitters, settings.numberOfReceivers, size(impulseResponsesAll, 3))  ./ double(virtualReceiversPerRealReceiver);
                    else 
                        obj.impulseResponses = impulseResponsesAll;
                    end
                end                
            else
                if settings.useBaseKernels && ~isempty(settings.baseKernels)
                    obj.impulseResponses = sonotraceue.synthetizeIRFromPointsWithBaseKernels(obj.reflectedPoints, settings.sampleRate, settings.numberOfSamplesIRFilter, settings.frequencies, ...
                                                                                             settings.numberOfIRSamples, settings.numberOfEmitters, settings.numberOfReceivers, ...
                                                                                             settings.approximateIRCutDB, settings.enableApproximateIR, settings.speedOfSound, settings.baseKernels);
                else
                    if settings.useBaseKernels && isempty(settings.baseKernels)
                        warning("settings.useBaseKernels is enabled but no base kernels are found so running without! Make sure to generate them with settings.prepareIRandSignalGeneration(...) first!");
                    end

                    obj.impulseResponses = sonotraceue.synthetizeIRFromPoints(obj.reflectedPoints, settings.sampleRate, settings.numberOfSamplesIRFilter, settings.frequencies, ...
                                                                              settings.iRFilterGaussAlpha, settings.numberOfIRSamples, settings.numberOfEmitters, settings.numberOfReceivers, ...
                                                                              settings.approximateIRCutDB, settings.enableApproximateIR, settings.speedOfSound);
                end
            end
        end

        function obj = synthetizeIRFromPointsOverride(obj, settings, numberOfSamplesIRFilter, iRFilterGaussAlpha, numberOfIRSamples, approximateIRCutDB, enableApproximateIR, enablePatternSum, useBaseKernels)
            if settings.enableEmitterPatternSimulation
                totalNumberOfMics = size(settings.finalReceiverPositions, 1);
                virtualReceiversPerRealReceiver = totalNumberOfMics / settings.numberOfReceivers;

                if useBaseKernels
                    baseKernels = sonotraceue.generateIRBaseKernels(obj, iRFilterGaussAlpha, numberOfSamplesIRFilter);
                    impulseResponsesAll = sonotraceue.synthetizeIRFromPointsWithBaseKernels(obj.reflectedPoints, settings.sampleRate, numberOfSamplesIRFilter, settings.frequencies, ...
                                                                                            numberOfIRSamples, settings.numberOfEmitters, totalNumberOfMics, ...
                                                                                            approximateIRCutDB, enableApproximateIR, settings.speedOfSound, baseKernels);
                else
                    impulseResponsesAll = sonotraceue.synthetizeIRFromPoints(obj.reflectedPoints, settings.sampleRate, numberOfSamplesIRFilter, settings.frequencies, ...
                                                                             iRFilterGaussAlpha, numberOfIRSamples, settings.numberOfEmitters, totalNumberOfMics, ...
                                                                             approximateIRCutDB, enableApproximateIR, settings.speedOfSound);
                end
                if enablePatternSum
                    impulseResponsesReshaped = reshape(impulseResponsesAll, settings.numberOfEmitters, virtualReceiversPerRealReceiver, settings.numberOfReceivers, size(impulseResponsesAll, 3));
                    obj.impulseResponses = reshape(sum(impulseResponsesReshaped, 2), settings.numberOfEmitters, settings.numberOfReceivers, size(impulseResponsesAll, 3))  ./ double(virtualReceiversPerRealReceiver);
                else 
                    obj.impulseResponses = impulseResponsesAll;
                end
            else
                if useBaseKernels
                    baseKernels = sonotraceue.generateIRBaseKernels(obj, iRFilterGaussAlpha, numberOfSamplesIRFilter);
                    obj.impulseResponses = sonotraceue.synthetizeIRFromPointsWithBaseKernels(obj.reflectedPoints, settings.sampleRate, numberOfSamplesIRFilter, settings.frequencies, ...
                                                                                            numberOfIRSamples, settings.numberOfEmitters, settings.numberOfReceivers, ...
                                                                                            approximateIRCutDB, enableApproximateIR, settings.speedOfSound, baseKernels);
                else
                    obj.impulseResponses = sonotraceue.synthetizeIRFromPoints(obj.reflectedPoints, settings.sampleRate, numberOfSamplesIRFilter, settings.frequencies, ...
                                                                              iRFilterGaussAlpha, numberOfIRSamples, settings.numberOfEmitters, settings.numberOfReceivers, ...
                                                                              approximateIRCutDB, enableApproximateIR, settings.speedOfSound);
                end
            end
        end

        function obj = synthetizeIRFromSubResultsPoints(obj, settings, Merge)

            if ~settings.settingsSetManually
                warning("Using default settings for IR synthesis and signal generation. Make sure to provide these with settings.prepareIRandSignalGeneration(...) first!");
            end        

            if obj.isSpecularSubOutputSet()
                obj.specularSubOutput = obj.specularSubOutput.synthetizeIRFromPoints(settings);
            end
            if obj.isDiffractionSubOutputSet()
                obj.diffractionSubOutput = obj.diffractionSubOutput.synthetizeIRFromPoints(settings);
            end
            if obj.isDirectPathSubOutputSet()
                obj.directPathSubOutput = obj.directPathSubOutput.synthetizeIRFromPoints(settings);
            end
            if Merge
                obj = obj.mergeIRFromSubResults();
            end
        end

        function obj = synthetizeIRFromSubResultsPointsOverride(obj, settings, iRFilterGaussAlpha, numberOfSamplesIRFilter, numberOfIRSamples, approximateIRCutDB, enableApproximateIR, enablePatternSum, useBaseKernels, Merge)
            baseKernels = [];
            if useBaseKernels
                baseKernels = sonotraceue.generateIRBaseKernels(obj, iRFilterGaussAlpha, numberOfSamplesIRFilter);
            end
            if obj.isSpecularSubOutputSet()
                obj.specularSubOutput = obj.specularSubOutput.synthetizeIRFromPointsOverride(settings, numberOfSamplesIRFilter, iRFilterGaussAlpha, numberOfIRSamples, approximateIRCutDB, enableApproximateIR, enablePatternSum, useBaseKernels, baseKernels);
            end
            if obj.isDiffractionSubOutputSet()
                obj.diffractionSubOutput = obj.diffractionSubOutput.synthetizeIRFromPointsOverride(settings, numberOfSamplesIRFilter, iRFilterGaussAlpha, numberOfIRSamples, approximateIRCutDB, enableApproximateIR, enablePatternSum, useBaseKernels, baseKernels);
            end
            if obj.isDirectPathSubOutputSet()
                obj.directPathSubOutput = obj.directPathSubOutput.synthetizeIRFromPointsOverride(settings, numberOfSamplesIRFilter, iRFilterGaussAlpha, numberOfIRSamples, approximateIRCutDB, enableApproximateIR, enablePatternSum, useBaseKernels, baseKernels);
            end
            if Merge
                obj = obj.mergeIRFromSubResults();
            end
        end

        function obj = mergeIRFromSubResults(obj)
            if obj.isSpecularSubOutputSet()
                if obj.specularSubOutput.isImpulseResponsesSet()
                    obj.impulseResponses = obj.specularSubOutput.impulseResponses;
                end
            end

            if obj.isDiffractionSubOutputSet()
                if obj.diffractionSubOutput.isImpulseResponsesSet()
                    if obj.isImpulseResponsesSet()
                        obj.impulseResponses = obj.impulseResponses + obj.diffractionSubOutput.impulseResponses;
                    else
                        obj.impulseResponses = obj.diffractionSubOutput.impulseResponses;
                    end
                end
            end

            if obj.isDirectPathSubOutputSet()
                if obj.directPathSubOutput.isImpulseResponsesSet()
                    if obj.isImpulseResponsesSet()
                        obj.impulseResponses = obj.impulseResponses + obj.directPathSubOutput.impulseResponses;
                    else
                        obj.impulseResponses = obj.directPathSubOutput.impulseResponses;
                    end
                end
            end
        end

        function obj = receiverSignalGenerationFromIR(obj, settings)
            if obj.isImpulseResponsesSet()
                obj.receiverSignals = sonotraceue.receiverSignalGenerationFromIR(obj.impulseResponses, settings.emitterSignals, obj.emitterSignalIndexes + 1);
            end
        end
        
        function updatePlot(obj, plotSensor, plotReflectedPoints, plotDirectPath, plotIR, plotSignals, dbCutoff, plotLimitAroundSensor)
            
            if plotSensor
                if isempty(findobj('Type', 'figure', 'Tag', 'STLUEWorldPlot'))
                    figure('Tag', 'STLUEWorldPlot');
                    ax = axes('Parent', gcf);
                    hold(ax, 'on');
                    grid(ax, 'on');
                    xlabel(ax, 'X (m)');
                    ylabel(ax, 'Y (m)');
                    zlabel(ax, 'Z (m)');
                    view(ax, 3); % 3D view
                    axis(ax, 'equal'); % Equal axis scaling
                else
                    ax = findobj('Type', 'axes', 'Parent', findobj('Type', 'figure', 'Tag', 'STLUEWorldPlot'));
                    cla(ax);
                    hold(ax, 'on');
                end

                title(ax, sprintf('SonoTraceUE - Measurement #%i - World Frame', obj.index));
                hold(ax, 'on');
        
                % Plot sensor as arrow
                plotTransforms(se3(obj.sensorTForm), 'FrameLabel', 'Sensor', 'FrameAxisLabels', 'off', 'AxisLabels', 'on', 'Parent', ax)

                plotTransforms(se3(obj.ownerTForm), 'FrameLabel', 'Owner', 'FrameAxisLabels', 'off', 'AxisLabels', 'on', 'Parent', ax)

                hold(ax, 'on');
        
                % Plot emitters                
                emitterPos = reshape(obj.emitterTForms(1:3, 4, :), 3, obj.numberOfEmitters);
                plot3(ax, emitterPos(1, :), emitterPos(2, :), emitterPos(3, :), 'bx', 'MarkerSize', 8, 'DisplayName', 'Emitters');
            
                % Plot receivers
                receiverPos = reshape(obj.receiverTForms(1:3, 4, :), 3, obj.numberOfReceivers);
                plot3(ax, receiverPos(1, :), receiverPos(2, :), receiverPos(3, :), 'gx', 'MarkerSize', 8, 'DisplayName', 'Receivers');
            
                % Update legend
                legend(ax, 'show');
        
                % Set axis limits
                if plotLimitAroundSensor
                    xlim(ax, [obj.sensorTForm(1, 4) - obj.plotAxisLimit, obj.sensorTForm(1, 4) + obj.plotAxisLimit]);
                    ylim(ax, [obj.sensorTForm(2, 4) - obj.plotAxisLimit, obj.sensorTForm(2, 4) + obj.plotAxisLimit]);
                    zlim(ax, [obj.sensorTForm(3, 4) - obj.plotAxisLimit, obj.sensorTForm(3, 4) + obj.plotAxisLimit]);  
                end
            end

            if plotDirectPath 
                if obj.isDirectPathLOS()
                    if isempty(findobj('Type', 'figure', 'Tag', 'STLUEDirectPathPlot'))
                        figure('Tag', 'STLUEDirectPathPlot');
                        ax = axes('Parent', gcf);
                        hold(ax, 'on');
                        grid(ax, 'on');
                        xlabel(ax, 'X (m)');
                        ylabel(ax, 'Y (m)');
                        zlabel(ax, 'Z (m)');
                        view(ax, 3); % 3D view
                        axis(ax, 'equal'); % Equal axis scaling
                    else
                        ax = findobj('Type', 'axes', 'Parent', findobj('Type', 'figure', 'Tag', 'STLUEDirectPathPlot'));
                        cla(ax);
                        hold(ax, 'on');
                    end
    
                    title(ax, sprintf('SonoTraceUE - Measurement #%i - Direct Path - World Frame', obj.index));
                    hold(ax, 'on');        
           
                    % Plot emitters                
                    emitterPos = reshape(obj.emitterTForms(1:3, 4, :), 3, obj.numberOfEmitters);
                    plot3(ax, emitterPos(1, :), emitterPos(2, :), emitterPos(3, :), 'bx', 'MarkerSize', 8, 'DisplayName', 'Emitters');
                    hold(ax, 'on');  
                    % Plot receivers
                    receiverPos = reshape(obj.receiverTForms(1:3, 4, :), 3, obj.numberOfReceivers);
                    receiverPosLOS = zeros(3, 1);
                    receiverPOSNoLOS = zeros(3, 1);    
                    indexLOS = 1;
                    indexNoLOS = 1;
                    for receiverIndex = 1 : size(receiverPos, 2)
                        if obj.directPathLOS(receiverIndex)
                            receiverPosLOS(:, indexLOS) = receiverPos(:, receiverIndex);
                            indexLOS = indexLOS + 1;
                        else
                            receiverPOSNoLOS(:, indexNoLOS) = receiverPos(:, receiverIndex);
                            indexNoLOS = indexNoLOS + 1;
                        end
                    end

                    if indexLOS > 1
                        plot3(ax, receiverPosLOS(1, :), receiverPosLOS(2, :), receiverPosLOS(3, :), 'gx', 'MarkerSize', 8, 'DisplayName', 'Receivers with LOS');
                        hold(ax, 'on');        
                    end
                    if indexNoLOS > 1                    
                        plot3(ax, receiverPOSNoLOS(1, :), receiverPOSNoLOS(2, :), receiverPOSNoLOS(3, :), 'rx', 'MarkerSize', 8, 'DisplayName', 'Receivers without LOS');
                    end

                    % Set axis limits
                    if plotLimitAroundSensor
                        xlim(ax, [obj.sensorTForm(1, 4) - obj.plotAxisLimit, obj.sensorTForm(1, 4) + obj.plotAxisLimit]);
                        ylim(ax, [obj.sensorTForm(2, 4) - obj.plotAxisLimit, obj.sensorTForm(2, 4) + obj.plotAxisLimit]);
                        zlim(ax, [obj.sensorTForm(3, 4) - obj.plotAxisLimit, obj.sensorTForm(3, 4) + obj.plotAxisLimit]);  
                    end

                    % Update legend
                    legend(ax, 'show');           
                else
                    warning("Could not plot direct path results as it is not set!")
                end                 
            end

            if plotIR
                if obj.isImpulseResponsesSet()
                    [plotRows, plotCols, plotCount] = sonotraceue.generateSubPlotRowCol(size(obj.impulseResponses, 2), 32);
                    timeVec = (1 : size(obj.impulseResponses, 3)) / obj.sampleRate; 
                    if isempty(findobj('Type', 'figure', 'Tag', 'STLUEIRPlot'))
                        fig = figure('Tag', 'STLUEIRPlot');
                        for i = 1:plotCount
                            axS = subplot(plotRows, plotCols, i);       
                            plot(axS, timeVec, rand(size(obj.impulseResponses, 3), obj.numberOfEmitters));
                            if mod(i, plotCols) == 1
                                ylabel(axS,"Impulse Response " + newline + "pressure - au)")
                            end
                            if i >= ((plotRows - 1) * plotCols) + 1
                                xlabel(axS, 'Time (ms)')
                            end
                            
                            title(axS, ['Receiver #', num2str(i)]);
                            hold(axS, 'on');
                        end
                    else
                        ax = findobj('Type', 'axes', 'Parent', findobj('Type', 'figure', 'Tag', 'STLUEIRPlot'));
                    end
        
                    sgtitle(sprintf('SonoTraceUE - Measurement #%i - Impulse Responses', obj.index));

                    for i = 1:plotCount
                        axS = subplot(plotRows, plotCols, i);   
                        cla;
                        plot(axS, squeeze(obj.impulseResponses(:, i, :))')
                    end
                else
                    warning("Could not plot IR as it is not set!")
                end
            end

            if plotSignals
                if obj.isReceiverSignalsSet()
                    [plotRows, plotCols, plotCount] = sonotraceue.generateSubPlotRowCol(size(obj.receiverSignals, 1), 9);
                    if isempty(findobj('Type', 'figure', 'Tag', 'STLUESignalPlot'))
                        fig = figure('Tag', 'STLUESignalPlot');          
                        for i = 1:plotCount
                            axS = subplot(plotRows, plotCols, i);       
                            [specS, specF, specT] = spectrogram(sonotraceue.normLin(rand(size(obj.receiverSignals, 2), 1)'), 512, 511, 512, obj.sampleRate, 'yaxis');
                            imagesc(axS, specT, specF / 1000, (abs(specS)))
                            hold(axS, 'on');
                            axis(axS, 'square');   
                            colormap(axS, parula);
                            if mod(i, plotCols) == 1
                                ylabel(axS, "Frequency (kHz)")
                            end
                            if i >= ((plotRows - 1) * plotCols) + 1
                                xlabel(axS, "Time (s)")
                            end
                            set( axS, 'ydir', 'normal' )    
                            title(axS, ['Receiver #', num2str(i)]);
                            hold on;
                        end
                    else
                        fig = findobj('Type', 'axes', 'Parent', findobj('Type', 'figure', 'Tag', 'STLUESignalPlot'));
                    end
    
                    sgtitle(sprintf('SonoTraceUE - Measurement #%i - Receiver Signals', obj.index));

                    for i = 1:plotCount
                        axS = subplot(plotRows, plotCols, i);   
                        cla;
                        [specS, specF, specT] = spectrogram(sonotraceue.normLin(obj.receiverSignals(i, :)), 512, 511, 512, obj.sampleRate, 'yaxis');
                        imagesc(axS, specT, specF / 1000, (abs(specS)))
                    end
                else
                    warning("Could not plot signal as it is not set!")
                end
            end

            if plotReflectedPoints
                if isempty(findobj('Type', 'figure', 'Tag', 'STLUEWorldPlot'))
                    fig = figure('Tag', 'STLUEWorldPlot');
                    ax = gca(fig);
                    hold(ax, 'on');
                    grid(ax, 'on');
                    xlabel(ax, 'X (m)');
                    ylabel(ax, 'Y (m)');
                    zlabel(ax, 'Z (m)');
                    view(ax, 3); 
                    axis(ax, 'equal'); 
                else
                    ax = findobj('Type', 'axes', 'Parent', findobj('Type', 'figure', 'Tag', 'STLUEWorldPlot'));
                    hold(ax, 'on');
                end
    
                title(ax, sprintf('SonoTraceUE - Measurement #%i - World Frame', obj.index));

                hold(ax, 'on');

                if size(obj.reflectedPoints, 1)
                    location = vertcat(obj.reflectedPoints.location);
                    summedStrength = vertcat(obj.reflectedPoints.summedStrength);        
                    normalizedStrength = summedStrength / obj.maximumStrength;
                    normalizedStrength(normalizedStrength > 1) = 1; 
                    normalizedStrength(normalizedStrength < 0) = 0;

                    strengthsReflectionsNorm = sonotraceue.normLog(normalizedStrength,  - dbCutoff );
                    strengthsReflectionsNorm = sonotraceue.normLin(strengthsReflectionsNorm + dbCutoff);                    
                    strengthsReflectionsIndexer = round(strengthsReflectionsNorm * 254) + 1;
                    cmapPlot = parula(256);                    
                    pointColors = cmapPlot(strengthsReflectionsIndexer, :);                

                    if obj.pointsInSensorFrame
                        locationTForms = [location'; ones(1, size(location, 1))];                        
                        locationWorldTforms = obj.sensorTForm * locationTForms;                        
                        locationPlot = locationWorldTforms(1:3, :)';
                    else
                        locationPlot = location;
                    end
                
                    scatter3(ax, locationPlot(:, 1), locationPlot(:, 2), locationPlot(:, 3), 20, pointColors, 'filled', 'DisplayName', 'Reflected points');        

                    cbar = colorbar(ax);
                    cbar.Label.String = 'Normalized Reflection Strength based on BRDF (dB)';
                    colormap(cmapPlot);
                    clim(ax, [-dbCutoff, 0]);
                end
            end
        end
    end

    
end


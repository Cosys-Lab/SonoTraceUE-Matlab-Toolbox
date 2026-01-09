classdef SubOutput
    
    properties
        timestamp = 0;
        maximumStrength = 0;
        maximumCurvature = 0;        
        maximumTotalDistance = 0;
        impulseResponses = [];
        reflectedPoints;
        reflectedStrengths = [];
    end
    
    methods
        function [obj, pointer] = SubOutput(buffer, pointer, numberOfEmitters, numberOfReceivers, numberOfFrequencies) 
            if nargin < 1 
                buffer = []; 
            end

            if ~isempty(buffer)
                % Timestamp
                obj.timestamp = typecast(swapbytes(buffer(pointer:pointer+7)), "double");
                pointer = pointer + 8;
    
                % Maximum Strength
                obj.maximumStrength = typecast(swapbytes(buffer(pointer:pointer+3)), "single");
                pointer = pointer + 4;
    
                % Maximum Curvature
                obj.maximumCurvature = typecast(swapbytes(buffer(pointer:pointer+3)), "single");
                pointer = pointer + 4;
    
                % Maximum Total Distance
                obj.maximumTotalDistance = typecast(swapbytes(buffer(pointer:pointer+3)), "single") / 100;
                pointer = pointer + 4;
    
                % Reflected Points Count
                subOutputReflectedPointsCount = typecast(swapbytes(buffer(pointer:pointer+3)), "int32");
                pointer = pointer + 4;      
                if subOutputReflectedPointsCount > 0
                    templateStruct = sonotraceue.pointStructGenerator(); 
                    pointStructs = repmat(templateStruct, subOutputReflectedPointsCount, 1);
                    for reflectedPointIndex = 1 : subOutputReflectedPointsCount
                        % Reflected Point Size
                        reflectedPointSize = typecast(swapbytes(buffer(pointer:pointer+3)), "int32");
                        pointer = pointer + 4;
    
                        % Reflected Point Data
                        reflectedPointData = buffer(pointer:pointer+reflectedPointSize-1);
                        pointer = pointer + reflectedPointSize;
                        pointStructs(reflectedPointIndex) = sonotraceue.pointStructGenerator(reflectedPointData, numberOfEmitters, numberOfReceivers, numberOfFrequencies);
                    end
                    obj.reflectedPoints = pointStructs;
    
                    % Reflected Strengths
                    dataSubOutputReflectedStrengths = buffer(pointer:pointer+4*subOutputReflectedPointsCount-1);
                    pointer = pointer + 4 * subOutputReflectedPointsCount;
                    obj.reflectedStrengths = typecast(swapbytes(dataSubOutputReflectedStrengths), "single")'; 
                end
            end
        end

        function obj = synthetizeIRFromPoints(obj, settings, NumberOfSamplesIRFilter, IRFilterGaussAlpha, NumberOfIRSamples, ApproximateIRCutDB, EnableApproximateIR, EnablePatternSum)
            if settings.enableEmitterPatternSimulation
                totalNumberOfMics = size(settings.finalReceiverPositions, 1);
                virtualReceiversPerRealReceiver = totalNumberOfMics / settings.numberOfReceivers;
                impulseResponsesAll = sonotraceue.synthetizeIRFromPoints(obj.reflectedPoints, settings.sampleRate, NumberOfSamplesIRFilter, settings.frequencies, ...
                                                                         IRFilterGaussAlpha, NumberOfIRSamples, settings.numberOfEmitters, totalNumberOfMics, ...
                                                                         ApproximateIRCutDB, EnableApproximateIR, settings.speedOfSound);
                if EnablePatternSum
                    impulseResponsesReshaped = reshape(impulseResponsesAll, settings.numberOfEmitters, settings.numberOfReceivers, virtualReceiversPerRealReceiver, size(impulseResponsesAll, 3));
                    obj.impulseResponses = reshape(sum(impulseResponsesReshaped, 3), settings.numberOfEmitters, settings.numberOfReceivers, size(impulseResponsesAll, 3))  ./ double(virtualReceiversPerRealReceiver);
                else 
                    obj.impulseResponses = impulseResponsesAll;
                end
            else
                obj.impulseResponses = sonotraceue.synthetizeIRFromPoints(obj.reflectedPoints, settings.sampleRate, NumberOfSamplesIRFilter, settings.frequencies, ...
                                                                          IRFilterGaussAlpha, NumberOfIRSamples, settings.numberOfEmitters, settings.numberOfReceivers, ...
                                                                          ApproximateIRCutDB, EnableApproximateIR, settings.speedOfSound);
            end
        end

        function isSet = isImpulseResponsesSet(obj)
            isSet = ~isempty(obj.impulseResponses);
        end

        function updatePlot(obj, plotTitle, dbCutoff)   
            if isempty(findobj('Type', 'figure', 'Tag', plotTitle))
                fig = figure('Tag', plotTitle);
                ax = gca(fig);
                hold(ax, 'on');
                grid(ax, 'on');
                xlabel(ax, 'X (m)');
                ylabel(ax, 'Y (m)');
                zlabel(ax, 'Z (m)');
                view(ax, 3);
                axis(ax, 'equal');                
            else
                ax = findobj('Type', 'axes', 'Parent', findobj('Type', 'figure', 'Tag', plotTitle));
                cla(ax);
                hold(ax, 'on');
            end

            title(ax, sprintf('SonoTraceUE - Reflected Points - %s', plotTitle));
            if size(obj.reflectedPoints, 1)
                location = vertcat(obj.reflectedPoints.location);
                summedStrength = vertcat(obj.reflectedPoints.summedStrength);        
                normalizedStrength = summedStrength / obj.maximumStrength;
                normalizedStrength(normalizedStrength > 1) = 1; 
                normalizedStrength(normalizedStrength < 0) = 0;
              
                strengthsReflectionsNorm = sonotraceue.normLog(normalizedStrength, - dbCutoff);
                strengthsReflectionsNorm = sonotraceue.normLin(strengthsReflectionsNorm + dbCutoff);                    
                strengthsReflectionsIndexer = round(strengthsReflectionsNorm *254) + 1;
                cmapPlot = parula(256);                    
                pointColors = cmapPlot(strengthsReflectionsIndexer, :);   
        
                scatter3(ax, location(:, 1), location(:, 2), location(:, 3), 20, pointColors, 'filled', 'DisplayName', 'Reflected points');        

                cbar = colorbar(ax);
                cbar.Label.String = 'Normalized Reflection Strength based on BRDF (dB)';
                colormap(ax, cmapPlot);
                clim(ax, [-dbCutoff, 0]);
            end
        end
    end   
end


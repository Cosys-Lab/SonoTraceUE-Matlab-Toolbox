classdef Settings
    
    properties
        % Input settings
        emitterPositionsOffset = [0, 0, 0];
        receiverPositionsOffset = [0, 0, 0];
        enableStaticReceivers = false;
        enableUseWorldCoordinatesReceivers = true;
        enableEmitterPatternSimulation = false;
        emitterPatternRadius = 0.0125;
        emitterPatternSpacing = 0.005;
        enableSimulation = true;
        enableRaytracing = true;
        enableSpecularComponentCalculation = true;
        enableDiffractionComponentCalculation = true;
        enableDirectPathComponentCalculation = false;
        enableRunSimulationOnlyOnTrigger = true;
        pointsInSensorFrame = true;
        simulationRate = 5;
        numberOfSimFrequencies = 14;
        minimumSimFrequency = 20000;
        maximumSimFrequency = 85000;
        sampleRate = 450000;
        speedOfSound = 343;
        directPathStrength = 100;
        specularMinimumStrength = 0.00001;
        diffractionMinimumStrength = 0.00001;
        diffractionTriangleSizeThreshold = 2;
        diffractionSimDivisionFactor = 25;
        enableDiffractionLineOfSightRequired = true;
        enableDiffractionForDynamicObjects = false;
        enableSpecularSimulationOnlyOnLastHits = false;
        meshDataGenerationAttempts = 5;
        curvatureScale = 1;
        enableCurvatureTriangleSizeBasedScaler = true;
        curvatureScalerMinimumEffect = 0.02;
        curvatureScalerMaximumEffect = 2;
        curvatureScalerLowerTriangleSizeThreshold = 0.005;
        curvatureScalerUpperTriangleSizeThreshold = 0.05;
        sensorLowerAzimuthLimit = -45;
        sensorUpperAzimuthLimit = 45;
        sensorLowerElevationLimit = -45;
        sensorUpperElevationLimit = 45;
        numberOfInitialRays = 50000;
        maximumRayDistance = 5;
        maximumBounces = 3;
        
        % Generated settings
        azimuthAngles = [];
        elevationAngles = [];
        loadedEmitterPositions = [];
        finalEmitterPositions = [];
        loadedReceiverPositions = [];
        finalReceiverPositions = [];
        objectSettings = [];
        frequencies = [];
        emitterSignals = {};
        defaultEmitterSignalIndexes = [];

        numberOfEmitters = 0;
        numberOfReceivers = 0;
    end
    
    methods
        function obj = Settings(server)
            if nargin < 1 
                server = []; 
            end

            if ~isempty(server)

                % Data size
                dataDataSize = uint8(read(server, 4, "uint8"));
                dataSize = typecast(swapbytes(dataDataSize), "int32");
    
                % Read all data into a buffer in one operation
                buffer = uint8(read(server, dataSize, "uint8"));
    
                % Use a pointer-based approach to parse the data
                pointer = 1;
    
                % Emitter and receiver positions offsets
                obj.emitterPositionsOffset = typecast(swapbytes(buffer(pointer:pointer+23)), 'double') .* [0.01 -0.01 0.01];
                pointer = pointer + 24;
                obj.receiverPositionsOffset = typecast(swapbytes(buffer(pointer:pointer+23)), 'double') .* [0.01 -0.01 0.01];
                pointer = pointer + 24;
    
                % Receiver settings
                obj.enableStaticReceivers = logical(buffer(pointer));
                pointer = pointer + 1;
                obj.enableUseWorldCoordinatesReceivers = logical(buffer(pointer));
                pointer = pointer + 1;
                obj.enableEmitterPatternSimulation = logical(buffer(pointer));
                pointer = pointer + 1;
                obj.emitterPatternRadius = typecast(swapbytes(buffer(pointer:pointer+3)), 'single') / 100;
                pointer = pointer + 4;
                obj.emitterPatternSpacing = typecast(swapbytes(buffer(pointer:pointer+3)), 'single') / 100;
                pointer = pointer + 4;
    
                % 3. Simulation Settings
                obj.enableSimulation = logical(buffer(pointer));
                pointer = pointer + 1;            
                obj.enableRaytracing = logical(buffer(pointer));
                pointer = pointer + 1;            
                obj.enableSpecularComponentCalculation = logical(buffer(pointer));
                pointer = pointer + 1;            
                obj.enableDiffractionComponentCalculation = logical(buffer(pointer));
                pointer = pointer + 1;    
                obj.enableDirectPathComponentCalculation = logical(buffer(pointer));
                pointer = pointer + 1;        
                obj.enableRunSimulationOnlyOnTrigger = logical(buffer(pointer));
                pointer = pointer + 1;         
                obj.pointsInSensorFrame = logical(buffer(pointer));
                pointer = pointer + 1;  
                obj.simulationRate = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;            
                obj.numberOfSimFrequencies = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;            
                obj.minimumSimFrequency = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;            
                obj.maximumSimFrequency = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;            
                obj.sampleRate = single(typecast(swapbytes(buffer(pointer:pointer+3)), 'int32'));
                pointer = pointer + 4;            
                obj.speedOfSound = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;          
                obj.directPathStrength = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;    
                obj.specularMinimumStrength = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;    
                obj.diffractionMinimumStrength = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;    
                obj.diffractionTriangleSizeThreshold = typecast(swapbytes(buffer(pointer:pointer+3)), 'single') / 100;
                pointer = pointer + 4;    
                obj.diffractionSimDivisionFactor = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;            
                obj.enableDiffractionLineOfSightRequired = logical(buffer(pointer));
                pointer = pointer + 1;
                obj.enableDiffractionForDynamicObjects = logical(buffer(pointer));
                pointer = pointer + 1;
                obj.enableSpecularSimulationOnlyOnLastHits = logical(buffer(pointer));
                pointer = pointer + 1;
                obj.meshDataGenerationAttempts = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;

                % Curvature settings
                obj.curvatureScale = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.enableCurvatureTriangleSizeBasedScaler = logical(buffer(pointer));
                pointer = pointer + 1;  
                obj.curvatureScalerMinimumEffect = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.curvatureScalerMaximumEffect = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.curvatureScalerLowerTriangleSizeThreshold = typecast(swapbytes(buffer(pointer:pointer+3)), 'single') / 100;
                pointer = pointer + 4;
                obj.curvatureScalerUpperTriangleSizeThreshold = typecast(swapbytes(buffer(pointer:pointer+3)), 'single') / 100;
                pointer = pointer + 4;
    
                % Sensor Settings
                obj.sensorLowerAzimuthLimit = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.sensorUpperAzimuthLimit = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.sensorLowerElevationLimit = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.sensorUpperElevationLimit = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                pointer = pointer + 4;
                obj.numberOfInitialRays = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                obj.maximumRayDistance = typecast(swapbytes(buffer(pointer:pointer+3)), 'single') / 100;
                pointer = pointer + 4;
                obj.maximumBounces = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
    
                % Ray Angles
                rayCount = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                obj.azimuthAngles = zeros(1, rayCount, 'single');
                for i = 1:rayCount
                    obj.azimuthAngles(i) = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                    pointer = pointer + 4;
                end
                obj.elevationAngles = zeros(1, rayCount, 'single');
                for i = 1:rayCount
                    obj.elevationAngles(i) = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                    pointer = pointer + 4;
                end
    
                % Emitters and Receiver Positions
                numberOfEmitters = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                obj.loadedEmitterPositions = zeros(numberOfEmitters, 3, 'single');
                for i = 1:numberOfEmitters
                    obj.loadedEmitterPositions(i, :) = typecast(swapbytes(buffer(pointer:pointer+23)), 'double') .* [0.01 -0.01 0.01];
                    pointer = pointer + 24;
                end
                obj.finalEmitterPositions = zeros(numberOfEmitters, 3, 'single');
                for i = 1:numberOfEmitters
                    obj.finalEmitterPositions(i, :) = typecast(swapbytes(buffer(pointer:pointer+23)), 'double') .* [0.01 -0.01 0.01];
                    pointer = pointer + 24;
                end
                numberOfReceivers = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                obj.loadedReceiverPositions = zeros(numberOfReceivers, 3, 'single');
                for i = 1:numberOfReceivers
                    obj.loadedReceiverPositions(i, :) = typecast(swapbytes(buffer(pointer:pointer+23)), 'double') .* [0.01 -0.01 0.01];
                    pointer = pointer + 24;
                end
                finalnumberOfReceivers = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                obj.finalReceiverPositions = zeros(finalnumberOfReceivers, 3, 'single');
                for i = 1:finalnumberOfReceivers
                    obj.finalReceiverPositions(i, :) = typecast(swapbytes(buffer(pointer:pointer+23)), 'double') .* [0.01 -0.01 0.01];
                    pointer = pointer + 24;
                end
    
                % Object Settings
                objectCount = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                emptyObjectSettings = sonotraceue.ObjectSettings();
                obj.objectSettings = repmat(emptyObjectSettings, objectCount, 1);
                for i = 1:objectCount
                    [obj.objectSettings(i), pointer] = sonotraceue.ObjectSettings(buffer, pointer, obj.numberOfSimFrequencies);
                end
    
                % Frequencies
                obj.frequencies = zeros(1, obj.numberOfSimFrequencies, 'single');
                for i = 1:obj.numberOfSimFrequencies
                    obj.frequencies(i) = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                    pointer = pointer + 4;
                end
    
                % Emitter signals
                emitterSignalsCount = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                pointer = pointer + 4;
                obj.emitterSignals = cell(emitterSignalsCount, 1);
                for i = 1:emitterSignalsCount
                    emitterSignalLength = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                    pointer = pointer + 4;
                    emitterSignal = zeros(1, emitterSignalLength, 'single');
                    for j = 1:emitterSignalLength
                        emitterSignal(j) = typecast(swapbytes(buffer(pointer:pointer+3)), 'single');
                        pointer = pointer + 4;
                    end
                    obj.emitterSignals{i} = emitterSignal;
                end

                obj.defaultEmitterSignalIndexes = zeros(numberOfEmitters, 1, 'int32');
                for i = 1:numberOfEmitters
                    obj.defaultEmitterSignalIndexes(i, :) = typecast(swapbytes(buffer(pointer:pointer+3)), 'int32');
                    pointer = pointer + 4;
                end
                
                obj.numberOfEmitters = numberOfEmitters;
                obj.numberOfReceivers = numberOfReceivers;
            end
        end        
    end
end

